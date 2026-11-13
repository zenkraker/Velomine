using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Rides;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Rides;

/// <summary>
/// The start window and the two limits one ride at a time, through the upload endpoint: the dedupe index is the
/// exact file, so this builds rides whose bytes differ but whose start, elapsed time and distance do not.
/// </summary>
public sealed class RideDuplicateWindowTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    [Fact]
    public async Task UploadRide_ShouldHideTheSecondCopy_WhenTheStartIsExactlyTwoMinutesLater()
    {
        await using var api = await TestApi.StartAsync(postgres,
            b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var member = await api.NewMemberAsync();
        var first = await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(Start, 600)));
        var second = await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(Start.AddSeconds(120), 600)));

        Assert.Equal("duplicate", second.Status);
        Assert.Equal(first.Id, second.DuplicateOf);
    }

    [Fact]
    public async Task UploadRide_ShouldKeepBoth_WhenTheStartIsTwoMinutesAndOneSecondLater()
    {
        await using var api = await TestApi.StartAsync(postgres,
            b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var member = await api.NewMemberAsync();
        var first = await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(Start, 600)));
        var second = await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(Start.AddSeconds(121), 600)));

        Assert.Equal("ready", first.Status);
        Assert.Equal("ready", second.Status);
        Assert.Null(second.DuplicateOf);
    }

    [Fact]
    public async Task UploadRide_ShouldKeepBoth_WhenTheElapsedTimeIsMoreThanAMinuteApart()
    {
        await using var api = await TestApi.StartAsync(postgres,
            b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var member = await api.NewMemberAsync();
        // Same start, but 600 s and 661 s: more than the 60 s tolerance, so they are two different rides.
        await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(Start, 600)));
        var other = await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(Start, 661)));

        Assert.Equal("ready", other.Status);
        Assert.Null(other.DuplicateOf);
    }

    [Fact]
    public async Task UploadRide_ShouldKeepBoth_WhenTheElapsedTimesMatchButTheDistancesDoNot()
    {
        await using var api = await TestApi.StartAsync(postgres,
            b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var member = await api.NewMemberAsync();
        // Same start, 59 s more elapsed. The test file's distance is 8 m/s of elapsed time, so they are 472 m apart:
        // inside the 60 s window, outside the 200 m tolerance. Both limits must hold, so they are two rides.
        await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(Start, 600)));
        var other = await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(Start, 659)));

        Assert.Equal("ready", other.Status);
        Assert.Null(other.DuplicateOf);
    }
}
