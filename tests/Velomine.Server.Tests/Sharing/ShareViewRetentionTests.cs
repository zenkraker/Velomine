using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Sharing;

namespace Velomine.Server.Tests.Sharing;

[Collection("postgres")]
public sealed class ShareViewRetentionTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));

    private static async Task<Guid> NewMemberAsync(TestApi api) =>
        (await (await api.RegisterAsync(TestApi.NewEmail())).Content.ReadFromJsonAsync<RegisterResponse>(Ct))!.Id;

    private static ShareView View(Guid memberId, DateTimeOffset at) => new()
    {
        Id = Guid.NewGuid(),
        MemberId = memberId,
        ClubId = Guid.NewGuid(),
        ViewerId = memberId,
        ViewerName = "Coach",
        What = ViewKinds.Summary,
        At = at,
    };

    [Fact]
    public async Task ShareViewRetention_ShouldDeleteOnlyTheOldRows_WhenItRuns()
    {
        await using var api = await StartAsync();
        var memberId = await NewMemberAsync(api);
        var old = DateTimeOffset.UtcNow.AddMonths(-4);
        var recent = DateTimeOffset.UtcNow.AddMonths(-2);
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            db.ShareViews.AddRange(View(memberId, old), View(memberId, recent));
            await db.SaveChangesAsync(Ct);
        }

        var deleted = await api.Services.GetRequiredService<ShareViewRetention>().RunOnceAsync(Ct);

        Assert.Equal(1, deleted);
        await using var check = api.Services.CreateAsyncScope();
        var checkDb = check.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.False(await checkDb.ShareViews.AnyAsync(v => v.At == old, Ct));
        Assert.True(await checkDb.ShareViews.AnyAsync(v => v.At == recent, Ct));
    }

    [Fact]
    public async Task ShareViewRetention_ShouldDeleteTheWholeBacklog_WhenItIsLargerThanOneBatch()
    {
        await using var api = await StartAsync();
        var memberId = await NewMemberAsync(api);
        var old = DateTimeOffset.UtcNow.AddMonths(-4);
        var recent = DateTimeOffset.UtcNow.AddMonths(-2);
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            for (var i = 0; i < 5001; i++) db.ShareViews.Add(View(memberId, old.AddSeconds(i)));
            db.ShareViews.Add(View(memberId, recent));
            await db.SaveChangesAsync(Ct);
        }

        var deleted = await api.Services.GetRequiredService<ShareViewRetention>().RunOnceAsync(Ct);

        Assert.Equal(5001, deleted);
        await using var check = api.Services.CreateAsyncScope();
        var checkDb = check.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.Equal(0, await checkDb.ShareViews.CountAsync(v => v.At < DateTimeOffset.UtcNow.AddMonths(-3), Ct));
        Assert.Equal(1, await checkDb.ShareViews.CountAsync(Ct));
    }
}
