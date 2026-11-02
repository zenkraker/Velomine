using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql;

namespace Velomine.Server.Tests.Spikes;

// Checks the conditions in docs/dependencies/npgsql-efcore.md against a real PostgreSQL.
// Each test gets its own database on the shared server.
[Collection("postgres")]
public sealed class NpgsqlProviderSpikeTests(PostgresFixture postgres) : IAsyncLifetime
{
    private const string Schema = "rides_spike";
    private string dbConnection = "";

    public async ValueTask InitializeAsync()
    {
        dbConnection = await postgres.CreateDatabaseAsync();
        await using var context = NewContext();
        await context.Database.MigrateAsync();
    }

    public ValueTask DisposeAsync() => ValueTask.CompletedTask;

    private SpikeContext NewContext() =>
        new(new DbContextOptionsBuilder<SpikeContext>().UseNpgsql(dbConnection).Options);

    private async Task<string> Scalar(string sql)
    {
        await using var connection = new NpgsqlConnection(dbConnection);
        await connection.OpenAsync();
        return (await new NpgsqlCommand(sql, connection).ExecuteScalarAsync())?.ToString() ?? "";
    }

    [Fact]
    public async Task ColumnTypes_AreTheOnesTheArchitectureNeeds()
    {
        string Column(string name) => $"select data_type || '/' || udt_name from information_schema.columns where table_schema = '{Schema}' and table_name = 'rides' and column_name = '{name}'";

        Assert.Equal("uuid/uuid", await Scalar(Column("Id")));
        Assert.Equal("timestamp with time zone/timestamptz", await Scalar(Column("StartTime")));
        Assert.Equal("ARRAY/_float4", await Scalar(Column("Speed")));
        Assert.Equal("bytea/bytea", await Scalar(Column("Original")));
    }

    [Fact]
    public async Task RoundTrip_KeepsInstantArrayAndBytes()
    {
        var ride = new SpikeRide
        {
            Id = Guid.NewGuid(),
            StartTime = new DateTimeOffset(2026, 11, 2, 7, 30, 0, TimeSpan.Zero),
            Speed = [1.5f, 2.5f, 3.5f],
            Original = [1, 2, 3, 4],
        };
        await using (var write = NewContext())
        {
            write.Rides.Add(ride);
            await write.SaveChangesAsync(TestContext.Current.CancellationToken);
        }

        await using var read = NewContext();
        var loaded = await read.Rides.SingleAsync(r => r.Id == ride.Id, cancellationToken: TestContext.Current.CancellationToken);
        Assert.Equal(ride.StartTime, loaded.StartTime);
        Assert.Equal(ride.Speed, loaded.Speed);
        Assert.Equal(ride.Original, loaded.Original);
    }

    [Fact]
    public async Task NonUtcOffset_IsRejected_SoCodeMustStoreUtcAndKeepTheLocalOffsetSeparately()
    {
        await using var context = NewContext();
        context.Rides.Add(new SpikeRide
        {
            Id = Guid.NewGuid(),
            StartTime = new DateTimeOffset(2026, 11, 2, 9, 30, 0, TimeSpan.FromHours(2)),
            Speed = [],
            Original = [],
        });

        var error = await Assert.ThrowsAsync<DbUpdateException>(() => context.SaveChangesAsync(TestContext.Current.CancellationToken));
        Assert.IsType<ArgumentException>(error.InnerException);
    }

    [Fact]
    public async Task ConcurrentEdits_SecondSaveIsRejected()
    {
        var id = Guid.NewGuid();
        await using (var seed = NewContext())
        {
            seed.Rides.Add(new SpikeRide { Id = id, StartTime = DateTimeOffset.UnixEpoch, Speed = [], Original = [] });
            await seed.SaveChangesAsync(TestContext.Current.CancellationToken);
        }

        await using var first = NewContext();
        await using var second = NewContext();
        var a = await first.Rides.SingleAsync(r => r.Id == id, cancellationToken: TestContext.Current.CancellationToken);
        var b = await second.Rides.SingleAsync(r => r.Id == id, cancellationToken: TestContext.Current.CancellationToken);
        a.Original = [1];
        b.Original = [2];
        await first.SaveChangesAsync(TestContext.Current.CancellationToken);

        await Assert.ThrowsAsync<DbUpdateConcurrencyException>(() => second.SaveChangesAsync(TestContext.Current.CancellationToken));
    }

    [Fact]
    public async Task MigrationCanCreateIndexConcurrently()
    {
        var valid = await Scalar($"select i.indisvalid from pg_index i join pg_class c on c.oid = i.indexrelid join pg_namespace n on n.oid = c.relnamespace where n.nspname = '{Schema}' and c.relname = 'ix_rides_start_time'");

        Assert.Equal("True", valid);
    }
}

public sealed class SpikeRide
{
    public Guid Id { get; set; }
    public DateTimeOffset StartTime { get; set; }
    public float[] Speed { get; set; } = [];
    public byte[] Original { get; set; } = [];
    public uint Version { get; set; }
}

public sealed class SpikeContext(DbContextOptions<SpikeContext> options) : DbContext(options)
{
    public DbSet<SpikeRide> Rides => Set<SpikeRide>();

    protected override void OnModelCreating(ModelBuilder modelBuilder) =>
        modelBuilder.Entity<SpikeRide>(e =>
        {
            e.ToTable("rides", "rides_spike");
            e.Property(r => r.Version).IsRowVersion();
        });
}

[DbContext(typeof(SpikeContext))]
[Migration("20261102000000_Spike")]
public sealed class SpikeMigration : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.EnsureSchema("rides_spike");
        migrationBuilder.CreateTable(
            name: "rides",
            schema: "rides_spike",
            columns: table => new
            {
                Id = table.Column<Guid>(nullable: false),
                StartTime = table.Column<DateTimeOffset>(nullable: false),
                Speed = table.Column<float[]>(type: "real[]", nullable: false),
                Original = table.Column<byte[]>(nullable: false),
                xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false),
            },
            constraints: table => table.PrimaryKey("PK_rides", x => x.Id));
        // CONCURRENTLY cannot run inside a transaction.
        migrationBuilder.Sql(
            "CREATE INDEX CONCURRENTLY ix_rides_start_time ON rides_spike.rides (\"StartTime\")",
            suppressTransaction: true);
    }

    protected override void Down(MigrationBuilder migrationBuilder) =>
        migrationBuilder.DropTable("rides", "rides_spike");
}
