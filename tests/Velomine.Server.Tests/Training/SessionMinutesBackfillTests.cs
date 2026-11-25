using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Training;

namespace Velomine.Server.Tests.Training;

/// <summary>
/// The `minutes` column arrived after the sessions table did: a session planned before the deploy must read its own
/// recipe's least length and never 0, so the first week after the upgrade budgets and scores what it carries.
/// </summary>
public sealed class SessionMinutesBackfillTests(PostgresFixture postgres)
{
    private const string BeforeTheColumn = "20261124235341_AddAutoTraining";

    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    [Fact]
    public async Task Sessions_ShouldReadTheirRecipesLeastLength_WhenTheyWerePlannedBeforeTheColumnExisted()
    {
        var connection = await postgres.CreateDatabaseAsync();
        try
        {
            var options = new DbContextOptionsBuilder<VelomineDbContext>().UseNpgsql(connection).Options;
            await using var db = new VelomineDbContext(options);
            var migrator = db.Database.GetService<IMigrator>();

            // The database as the release before the column left it: no minutes, no check on them.
            await migrator.MigrateAsync(BeforeTheColumn, Ct);
            var user = new User
            {
                UserName = "backfill@test.local",
                Email = "backfill@test.local",
                DisplayName = "Backfill Rider",
                IsApproved = true,
                CreatedAt = DateTimeOffset.UnixEpoch,
            };
            db.Users.Add(user);
            await db.SaveChangesAsync(Ct);

            // One session of every kind the planner writes, planned when nothing recorded their length.
            var planned = new[] { "R01", "R02", "R03", "R05", "R16", "R17", "R99" };
            for (var day = 0; day < planned.Length; day++)
                await db.Database.ExecuteSqlAsync($"""
                    INSERT INTO training.sessions (id, user_id, local_date, recipe, block_percents, state, created_at)
                    VALUES (gen_random_uuid(), {user.Id}, DATE '2026-11-23' + {day}, {planned[day]}, ARRAY[90],
                            'planned', now())
                    """, Ct);

            await migrator.MigrateAsync(cancellationToken: Ct);

            var minutes = await db.TrainingSessions
                .Where(s => s.UserId == user.Id)
                .ToDictionaryAsync(s => s.Recipe, s => s.Minutes, Ct);

            Assert.All(planned, recipe => Assert.True(minutes[recipe] > 0, $"{recipe} reads {minutes[recipe]}"));
            Assert.All(planned[..^1], recipe => Assert.Equal(Recipes.ByCode(recipe).LeastMinutes, minutes[recipe]));
            Assert.Equal(45, minutes["R99"]);
        }
        finally
        {
            await postgres.DropDatabaseAsync(connection);
        }
    }
}
