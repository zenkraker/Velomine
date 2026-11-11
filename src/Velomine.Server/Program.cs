using System.Security.Claims;
using System.Threading.RateLimiting;
using FastEndpoints;
using FastEndpoints.OpenApi;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.OpenApi;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Admin;
using Velomine.Server.Features.Bikes;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Routes;
using Velomine.Server.Features.Server;
using Velomine.Server.Features.Sharing;
using Velomine.Server.Observability;

var builder = WebApplication.CreateBuilder(args);
builder.AddVelomineTelemetry();

// A Strava export can be a gigabyte. Only the import request is let past Kestrel's 30 MB default (see the middleware
// below); the endpoint itself enforces this cap, and the form parser has to accept the wrapping around it.
var importMaxBytes = (builder.Configuration.GetValue("Velomine:Imports:MaxArchiveMb", 1024) + 8) * 1024L * 1024L;
builder.Services.Configure<FormOptions>(options => options.MultipartBodyLengthLimit = importMaxBytes);

// The connection string is read when the context is first created, so tests can override it.
builder.Services.AddDbContext<VelomineDbContext>((services, options) =>
    options.UseNpgsql(services.GetRequiredService<IConfiguration>().GetConnectionString("Velomine"))
        .AddInterceptors(services.GetServices<IInterceptor>()));
builder.Services.AddHostedService<DatabaseMigrator>(); // first: later startup work needs the tables
builder.Services.AddDataProtection()
    .PersistKeysToFileSystem(new DirectoryInfo(builder.Configuration["Velomine:DataProtection:KeysPath"] ?? "/data/keys"));
builder.Services.AddAccounts(builder.Configuration);
builder.Services.AddAdmin(builder.Configuration);
builder.Services.AddRides(builder.Configuration);
builder.Services.AddSharing(builder.Configuration);
builder.Services.AddRoutes();
builder.Services.AddBikes(builder.Configuration);
builder.Services.AddClubs(builder.Configuration);
builder.Services.AddOptions<MapOptions>().BindConfiguration("Velomine:Map");
builder.Services.AddFastEndpoints();
builder.Services.OpenApiDocument(o =>
{
    o.DocumentName = "v1";
    o.Title = "Velomine";
    o.Version = "v1";
    o.ShortSchemaNames = true;
    // The Dart client generator reads OpenAPI 3.0 (see docs/dependencies/openapi-generator.md).
    o.ConfigureOpenApi = openApi =>
    {
        openApi.OpenApiVersion = OpenApiSpecVersion.OpenApi3_0;
        // The Idempotency-Key and Bulk-Import are headers, so it does not belong in the multipart form's schema as well.
        openApi.AddSchemaTransformer((schema, context, _) =>
        {
            if (context.JsonTypeInfo.Type == typeof(UploadRideRequest))
            {
                schema.Properties?.Remove("idempotencyKey");
                schema.Properties?.Remove("bulkImport");
            }
            return Task.CompletedTask;
        });

        // "VelomineServerFeaturesAccountsLogin" becomes "login", so the generated Dart methods read well.
        openApi.AddOperationTransformer((operation, _, _) =>
        {
            const string prefix = "VelomineServerFeatures";
            if (operation.OperationId is { } id && id.StartsWith(prefix, StringComparison.Ordinal))
            {
                id = id[prefix.Length..];
                if (operation.Tags?.FirstOrDefault()?.Name is { } tag)
                {
                    // FastEndpoints tags a plural namespace with a singular name ("Clubs" -> "Club").
                    var start = id.StartsWith(tag + "s", StringComparison.Ordinal) ? tag.Length + 1
                        : id.StartsWith(tag, StringComparison.Ordinal) ? tag.Length
                        : 0;
                    id = id[start..];
                }
                operation.OperationId = char.ToLowerInvariant(id[0]) + id[1..];
            }

            return Task.CompletedTask;
        });
    };
});
builder.Services.AddHealthChecks().AddCheck<DatabaseHealthCheck>("database");
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    var permitLimit = builder.Configuration.GetValue("Velomine:RateLimits:AnonymousPerMinute", 60);
    options.AddPolicy("anonymous", context => RateLimitPartition.GetFixedWindowLimiter(
        context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
        _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = permitLimit,
            Window = TimeSpan.FromMinutes(1),
        }));

    // Uploads are signed in, so the key is the member: a whole club behind one address must not share a budget.
    // A bucket rather than a window: a member dropping a bike computer's whole Activities folder sends hundreds of
    // files at once, and that must work; what stays limited is the sustained rate (UploadsPerHour, refilled every
    // minute), so nobody can keep the server busy for long.
    var uploadsPerHour = builder.Configuration.GetValue("Velomine:RateLimits:UploadsPerHour", 600);
    var uploadBurst = builder.Configuration.GetValue("Velomine:RateLimits:UploadBurst", 1000);
    options.AddPolicy("uploads", context => RateLimitPartition.GetTokenBucketLimiter(
        context.User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "anonymous",
        _ => new TokenBucketRateLimiterOptions
        {
            TokenLimit = uploadBurst,
            TokensPerPeriod = Math.Max(1, uploadsPerHour / 60),
            ReplenishmentPeriod = TimeSpan.FromMinutes(1),
            QueueLimit = 0,
        }));

    // Starting a club is for a signed-in rider with no club, so the key is the member; a handful a day is plenty.
    var clubsPerDay = builder.Configuration.GetValue("Velomine:RateLimits:ClubCreationsPerDay", 5);
    options.AddPolicy("club-creation", context => RateLimitPartition.GetFixedWindowLimiter(
        context.User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "anonymous",
        _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = clubsPerDay,
            Window = TimeSpan.FromDays(1),
        }));

    // An archive can be a gigabyte, so a member gets a handful a day.
    var importsPerDay = builder.Configuration.GetValue("Velomine:RateLimits:ImportsPerDay", 10);
    options.AddPolicy("imports", context => RateLimitPartition.GetFixedWindowLimiter(
        context.User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "anonymous",
        _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = importsPerDay,
            Window = TimeSpan.FromDays(1),
        }));
});

// A reverse proxy is the only way in (the app port is never published), so trust its
// forwarded headers; otherwise HTTPS looks like HTTP and every client shares one rate-limit bucket.
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.KnownIPNetworks.Clear();
    options.KnownProxies.Clear();
});

// Exporting the API document (see below) needs no database and no background work.
if (builder.IsExportMode()) builder.Services.RemoveAll<IHostedService>();

var app = builder.Build();
app.UseForwardedHeaders();
// Only the import endpoint may send more than Kestrel's 30 MB default; every other request keeps that cap.
app.Use(async (context, next) =>
{
    if (context.Request.Method == "POST" && context.Request.Path == "/api/v1/rides/imports"
        && context.Features.Get<IHttpMaxRequestBodySizeFeature>() is { IsReadOnly: false } feature)
        feature.MaxRequestBodySize = importMaxBytes;
    await next(context);
});
// API only: the web app and the presentation site are served by the web image (app/Dockerfile), which forwards /api,
// /health and /openapi here, so the browser sees one address.
app.UseVelomineTelemetry();
app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();
app.UseFastEndpoints(c =>
{
    c.Endpoints.RoutePrefix = "api/v1";
    c.Errors.UseProblemDetails();
});
app.MapOpenApi(); // /openapi/v1.json
app.MapHealthChecks("/health");
await app.ExportOpenApiDocsAndExitAsync("v1"); // `--export-openapi-docs true` writes the document and exits, for the client generator
app.Run();

// Lets the integration tests start the server with WebApplicationFactory<Program>.
public partial class Program;
