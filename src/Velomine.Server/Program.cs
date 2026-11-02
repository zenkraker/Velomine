using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

var builder = WebApplication.CreateBuilder(args);

// The connection string is read when the context is first created, so tests can override it.
builder.Services.AddDbContext<VelomineDbContext>((services, options) =>
    options.UseNpgsql(services.GetRequiredService<IConfiguration>().GetConnectionString("Velomine")));
builder.Services.AddAccounts();
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
