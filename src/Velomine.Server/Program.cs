using FastEndpoints;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddFastEndpoints();
builder.Services.AddHealthChecks();

var app = builder.Build();
app.UseFastEndpoints(c => c.Endpoints.RoutePrefix = "api/v1");
app.MapHealthChecks("/health");
app.Run();

// Lets the integration tests start the server with WebApplicationFactory<Program>.
public partial class Program;
