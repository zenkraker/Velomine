using FastEndpoints;
using FastEndpoints.OpenApi;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.OpenApi;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.FileProviders;
using System.Threading.RateLimiting;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Admin;
using Velomine.Server.Features.Bikes;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Server;

var builder = WebApplication.CreateBuilder(args);

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
builder.Services.AddBikes(builder.Configuration);
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
        // The Idempotency-Key is a header, so it does not belong in the multipart form's schema as well.
        openApi.AddSchemaTransformer((schema, context, _) =>
        {
            if (context.JsonTypeInfo.Type == typeof(UploadRideRequest)) schema.Properties?.Remove("idempotencyKey");
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
});

// Exporting the API document (see below) needs no database and no background work.
if (builder.IsExportMode()) builder.Services.RemoveAll<IHostedService>();

var app = builder.Build();
// The presentation site lives in site/ and is served at the root: "/", "/status/", "/pricing/", "/contact/",
// "/principles/", "/privacy/", "/terms/" and "/security/".
// The Flutter web app is built into wwwroot (see the Dockerfile) and keeps its own routes through the fallback below.
// Both are served from the same address as the API, so the session cookie works without any cross-origin setup.
var sitePath = Path.Combine(app.Environment.ContentRootPath, "site");
if (Directory.Exists(sitePath))
{
    var siteFiles = new PhysicalFileProvider(sitePath);
    // Directory pages are linked with a trailing slash; add it when someone leaves it out.
    app.Use(async (context, next) =>
    {
        if (context.Request.Path.Value is "/status" or "/pricing" or "/contact" or "/principles" or "/privacy" or "/terms" or "/security" or "/it")
        {
            context.Response.Redirect(context.Request.Path.Value + "/", permanent: true);
            return;
        }

        await next();
    });
    app.UseDefaultFiles(new DefaultFilesOptions { FileProvider = siteFiles });
    app.UseStaticFiles(new StaticFileOptions { FileProvider = siteFiles });
}
app.UseStaticFiles();
app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();
app.UseFastEndpoints(c =>
{
    c.Endpoints.RoutePrefix = "api/v1";
    c.Errors.UseProblemDetails();
});
app.MapOpenApi(); // /openapi/v1.json
// An address without a file extension is a page of the web app (the app routes itself, e.g. /rides). Files such as
// main.dart.js are left to the static file middleware, and API paths that do not exist stay 404. The presentation
// site's pages are excluded so endpoint routing does not hide them from the default-file middleware above.
app.MapFallbackToFile("{*path:regex(^(?!(?:api|health|openapi|status|pricing|contact|principles|privacy|terms|security|it)(?:/|$))[^.]*$)}", "index.html");
app.MapHealthChecks("/health");
await app.ExportOpenApiDocsAndExitAsync("v1"); // `--export-openapi-docs true` writes the document and exits, for the client generator
app.Run();

// Lets the integration tests start the server with WebApplicationFactory<Program>.
public partial class Program;
