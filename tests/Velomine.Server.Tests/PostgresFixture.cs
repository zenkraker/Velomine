using System.Collections.Concurrent;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using Testcontainers.PostgreSql;
using Velomine.Server.Data;
using Velomine.Server.Tests;

// Assembly fixtures are handed to every test class's constructor and leave the classes free to run in parallel,
// which a collection fixture does not: one collection is one thread.
[assembly: AssemblyFixture(typeof(PostgresFixture))]
[assembly: AssemblyFixture(typeof(DexFixture))]

namespace Velomine.Server.Tests;

/// <summary>
/// One PostgreSQL server for the whole test run, shared as an assembly fixture so test classes run in parallel.
/// Starts a postgres:17 container, the image docker-compose uses; set VELOMINE_TEST_POSTGRES to an existing server
/// connection string to use that instead. Tests ask for a fresh, empty database with <see cref="CreateDatabaseAsync"/>.
/// </summary>
public sealed class PostgresFixture : IAsyncLifetime
{
    private readonly ConcurrentBag<string> databases = [];
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
            // Test classes run in parallel and every server has its own pool, so the default 100 connections are
            // not enough. The module's own settings (fsync=off and the rest) are added after this command.
            container = new PostgreSqlBuilder("postgres:17")
                .WithCommand("-c", "max_connections=500")
                .Build();
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
        var connection = new NpgsqlConnectionStringBuilder(ServerConnection) { Database = name };
        // On an existing server (VELOMINE_TEST_POSTGRES) the connection limit is not ours to raise.
        if (Environment.GetEnvironmentVariable("VELOMINE_TEST_POSTGRES") is not null) connection.MaxPoolSize = 5;
        return connection.ConnectionString;
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
