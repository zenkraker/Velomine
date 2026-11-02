using Npgsql;
using Testcontainers.PostgreSql;

namespace Velomine.Server.Tests;

/// <summary>
/// One PostgreSQL server for the whole test run (see <see cref="PostgresCollection"/>). Starts a postgres:17
/// container, the image docker-compose uses; set VELOMINE_TEST_POSTGRES to an existing server connection string
/// to use that instead. Tests ask for a fresh, empty database with <see cref="CreateDatabaseAsync"/>.
/// </summary>
public sealed class PostgresFixture : IAsyncLifetime
{
    private readonly List<string> databases = [];
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

    /// <summary>Creates an empty database and returns its connection string.</summary>
    public async Task<string> CreateDatabaseAsync()
    {
        var name = "t_" + Guid.NewGuid().ToString("N");
        await using var admin = new NpgsqlConnection(ServerConnection);
        await admin.OpenAsync();
        await new NpgsqlCommand($"CREATE DATABASE {name}", admin).ExecuteNonQueryAsync();
        databases.Add(name);
        return new NpgsqlConnectionStringBuilder(ServerConnection) { Database = name }.ConnectionString;
    }

    public async ValueTask DisposeAsync()
    {
        if (container is not null)
        {
            await container.DisposeAsync();
            return;
        }

        // An existing server keeps running, so remove the databases the tests made.
        NpgsqlConnection.ClearAllPools();
        await using var admin = new NpgsqlConnection(ServerConnection);
        await admin.OpenAsync();
        foreach (var name in databases)
            await new NpgsqlCommand($"DROP DATABASE IF EXISTS {name} WITH (FORCE)", admin).ExecuteNonQueryAsync();
    }
}

[CollectionDefinition("postgres")]
public sealed class PostgresCollection : ICollectionFixture<PostgresFixture>, ICollectionFixture<DexFixture>;
