using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;

var builder = WebApplication.CreateBuilder(args);

// The connection string is read when the context is first created, so tests can override it.
builder.Services.AddDbContext<VelomineDbContext>((services, options) =>
    options.UseNpgsql(services.GetRequiredService<IConfiguration>().GetConnectionString("Velomine")));
builder.Services.AddHostedService<DatabaseMigrator>(); // first: later startup work needs the tables
builder.Services.AddAccounts(builder.Configuration);
builder.Services.AddRides();
builder.Services.AddFastEndpoints();
builder.Services.AddHealthChecks();

var app = builder.Build();
app.UseAuthentication();
app.UseAuthorization();
app.UseFastEndpoints(c =>
{
    c.Endpoints.RoutePrefix = "api/v1";
    c.Errors.UseProblemDetails();
});
app.MapHealthChecks("/health");
app.Run();

// Lets the integration tests start the server with WebApplicationFactory<Program>.
public partial class Program;
