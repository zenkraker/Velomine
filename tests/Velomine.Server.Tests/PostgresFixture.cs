using Microsoft.EntityFrameworkCore;
using Npgsql;
using Testcontainers.PostgreSql;
using Velomine.Server.Data;

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
    private string? template;

    public string ServerConnection { get; private set; } = "";

    public async ValueTask InitializeAsync()
    {
        var existing = Environment.GetEnvironmentVariable("VELOMINE_TEST_POSTGRES");
        if (existing is not null)
        {
            ServerConnection = existing;
        }
        else
        {
            container = new PostgreSqlBuilder("postgres:17").Build();
            await container.StartAsync();
            ServerConnection = container.GetConnectionString();
        }

        // Migrate once, then clone: every test still gets its own database, but not its own migration run.
        template = "t_template_" + Guid.NewGuid().ToString("N");
        await ExecuteAsync($"CREATE DATABASE {template}");
        var options = new DbContextOptionsBuilder<VelomineDbContext>()
            .UseNpgsql(new NpgsqlConnectionStringBuilder(ServerConnection) { Database = template }.ConnectionString)
            .Options;
        await using var db = new VelomineDbContext(options);
        await db.Database.MigrateAsync();
        // A pooled connection would keep the template busy, and PostgreSQL refuses to clone a template in use.
        NpgsqlConnection.ClearAllPools();
    }

    /// <summary>Creates an empty database and returns its connection string.</summary>
    public async Task<string> CreateDatabaseAsync()
    {
        var name = "t_" + Guid.NewGuid().ToString("N");
        await ExecuteAsync($"CREATE DATABASE {name} TEMPLATE {template}");
        databases.Add(name);
        return new NpgsqlConnectionStringBuilder(ServerConnection) { Database = name }.ConnectionString;
    }

    private async Task ExecuteAsync(string sql)
    {
        await using var admin = new NpgsqlConnection(ServerConnection);
        await admin.OpenAsync();
        await new NpgsqlCommand(sql, admin).ExecuteNonQueryAsync();
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
        if (template is not null)
            await new NpgsqlCommand($"DROP DATABASE IF EXISTS {template} WITH (FORCE)", admin).ExecuteNonQueryAsync();
    }
}

[CollectionDefinition("postgres")]
public sealed class PostgresCollection : ICollectionFixture<PostgresFixture>, ICollectionFixture<DexFixture>;
