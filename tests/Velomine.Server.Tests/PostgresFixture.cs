using Testcontainers.PostgreSql;

namespace Velomine.Server.Tests;

/// <summary>
/// One PostgreSQL server per test class. Starts a postgres:17 container (the image docker-compose uses);
/// set VELOMINE_TEST_POSTGRES to an existing server connection string to use that instead.
/// </summary>
public sealed class PostgresFixture : IAsyncLifetime
{
    private PostgreSqlContainer? container;

    public string ServerConnection { get; private set; } = "";

    public async ValueTask InitializeAsync()
    {
        var existing = Environment.GetEnvironmentVariable("VELOMINE_TEST_POSTGRES");
        if (existing is not null)
        {
            ServerConnection = existing;
            return;
        }

        container = new PostgreSqlBuilder("postgres:17").Build();
        await container.StartAsync();
        ServerConnection = container.GetConnectionString();
    }

    public async ValueTask DisposeAsync()
    {
        if (container is not null) await container.DisposeAsync();
    }
}
