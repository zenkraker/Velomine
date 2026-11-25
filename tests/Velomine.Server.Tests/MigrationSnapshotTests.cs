using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.EntityFrameworkCore.Migrations.Operations;
using Velomine.Server.Data;

namespace Velomine.Server.Tests;

/// <summary>
/// The model and the migrations agree. A migration written by hand is where this breaks, and the next one generated
/// from the snapshot would then carry the difference again, so the check is a test rather than a step in a document.
/// </summary>
public sealed class MigrationSnapshotTests
{
    [Fact]
    public void Snapshot_ShouldMatchTheModel_WhenAMigrationWasWrittenByHand()
    {
        var options = new DbContextOptionsBuilder<VelomineDbContext>()
            .UseNpgsql("Host=localhost;Database=unused;Username=unused;Password=unused")
            .Options;
        using var db = new VelomineDbContext(options);
        var snapshot = db.GetService<IModelRuntimeInitializer>()
            .Initialize(db.GetService<IMigrationsAssembly>().ModelSnapshot!.Model)
            .GetRelationalModel();
        var model = db.GetService<IDesignTimeModel>().Model.GetRelationalModel();

        var differences = db.GetService<IMigrationsModelDiffer>().GetDifferences(snapshot, model);

        Assert.Empty(differences.Select(Describe));
    }

    private static string Describe(MigrationOperation operation) => operation switch
    {
        AddColumnOperation c => $"add column {c.Schema}.{c.Table}.{c.Name}",
        DropColumnOperation c => $"drop column {c.Schema}.{c.Table}.{c.Name}",
        CreateIndexOperation i => $"create index {i.Name}",
        DropIndexOperation i => $"drop index {i.Name}",
        CreateTableOperation t => $"create table {t.Schema}.{t.Name}",
        DropTableOperation t => $"drop table {t.Schema}.{t.Name}",
        AddForeignKeyOperation f => $"add foreign key {f.Name}",
        DropForeignKeyOperation f => $"drop foreign key {f.Name}",
        _ => operation.GetType().Name,
    };
}
