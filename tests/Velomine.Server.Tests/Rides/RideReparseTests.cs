using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Admin;
using Velomine.Server.Features.Bikes;
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;
using Velomine.Server.Features.Wellbeing;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Rides;

public sealed class RideReparseTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>The version a test raises the parser to.</summary>
    private const int Raised = RideParserVersion.Current + 1;

    private Task<TestApi> StartAsync() =>
        TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));

    private sealed record Member(HttpClient Client, Guid Id);

    private static async Task<Member> NewMemberAsync(TestApi api, int? ftpW = 250)
    {
        var email = TestApi.NewEmail();
        var response = await api.RegisterAsync(email);
        response.EnsureSuccessStatusCode();
        var id = (await response.Content.ReadFromJsonAsync<RegisterResponse>(Ct))!.Id;
        var member = new Member(await api.SignedInClientAsync(email, TestApi.MemberPassword), id);
        await SetFtpAsync(api, member, ftpW);
        return member;
    }

    private static async Task SetFtpAsync(TestApi api, Member member, int? ftpW)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        await db.Users.Where(u => u.Id == member.Id).ExecuteUpdateAsync(s => s.SetProperty(u => u.FtpW, ftpW), Ct);
    }

    private static async Task<Guid> UploadAsync(Member member, byte[] file, string name = "ride.fit")
    {
        var form = new MultipartFormDataContent { { new ByteArrayContent(file), "file", name } };
        var accepted = await member.Client.PostAsync("/api/v1/rides/uploads", form, Ct);
        Assert.Equal(HttpStatusCode.Accepted, accepted.StatusCode);
        var id = (await accepted.Content.ReadFromJsonAsync<UploadRideResponse>(Ct))!.RideId;
        await WaitWhileProcessingAsync(member.Client, id);
        return id;
    }

    private static async Task<string> WaitWhileProcessingAsync(HttpClient client, Guid id) =>
        (await TestApi.WaitForReadAsync(client, id)).Status;

    private static async Task<T> InDbAsync<T>(TestApi api, Func<VelomineDbContext, Task<T>> work)
    {
        await using var scope = api.Services.CreateAsyncScope();
        return await work(scope.ServiceProvider.GetRequiredService<VelomineDbContext>());
    }

    private static Task<Ride> LoadAsync(TestApi api, Guid id) =>
        InDbAsync(api, db => db.Rides.AsNoTracking().Include(r => r.Streams).Include(r => r.Laps).Include(r => r.PowerBests).SingleAsync(r => r.Id == id, Ct));

    private static Task ReparseAsync(TestApi api, int version = Raised) =>
        api.Services.GetRequiredService<RideReparseService>().RunAsync(Ct, version);

    private static string OriginalPath(TestApi api, string sha) =>
        Path.Combine(api.FilesPath, "originals", sha[..2], sha);

    [Fact]
    public async Task Reparse_ShouldRefreshDerivedNumbersAndKeepWhatTheMemberDecided_WhenTheParserVersionIsRaised()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var id = await UploadAsync(member, Fit(new FitSession(Start, 120, NormalizedPower: 215, LapSeconds: [60, 60])));
        var bikeId = Guid.CreateVersion7();
        await InDbAsync(api, async db =>
        {
            db.Bikes.Add(new Bike { Id = bikeId, UserId = member.Id, Name = "Mine", WheelCircumferenceMm = 2100, CreatedAt = DateTimeOffset.UtcNow });
            await db.SaveChangesAsync(Ct);
            db.RideFeels.Add(new RideFeel { RideId = id, Rpe = 7, Notes = "legs", UpdatedAt = DateTimeOffset.UtcNow });
            await db.SaveChangesAsync(Ct);
            // What an older parser might have stored, and what the member chose by hand.
            await db.Rides.Where(r => r.Id == id).ExecuteUpdateAsync(s => s
                .SetProperty(r => r.ElevationGainM, 999.0)
                .SetProperty(r => r.DistanceM, 1.0)
                .SetProperty(r => r.MaxSpeedMs, (double?)null)
                .SetProperty(r => r.Discipline, "gravel")
                .SetProperty(r => r.Assist, "ebike")
                .SetProperty(r => r.Environment, "indoor")
                .SetProperty(r => r.Commute, true)
                .SetProperty(r => r.BikeId, bikeId), Ct);
            await db.RideStreams.Where(s => s.RideId == id).ExecuteDeleteAsync(Ct);
            await db.RideLaps.Where(l => l.RideId == id).ExecuteDeleteAsync(Ct);
            await db.RidePowerBests.Where(b => b.RideId == id).ExecuteDeleteAsync(Ct);
            return 0;
        });
        var before = await LoadAsync(api, id);
        var notifications = await InDbAsync(api, db => db.Notifications.CountAsync(n => n.UserId == member.Id, Ct));

        await ReparseAsync(api);

        var after = await LoadAsync(api, id);
        Assert.InRange(after.ElevationGainM!.Value, 10, 13);
        Assert.Equal(119 * 8.0, after.DistanceM!.Value, 1);
        Assert.Equal(8, after.MaxSpeedMs!.Value, 3);
        Assert.Equal(120, after.Streams!.Time.Length);
        Assert.Equal(2, after.Laps.Count);
        Assert.NotEmpty(after.PowerBests);
        Assert.Equal(Raised, after.ParserVersion);
        Assert.Null(after.ReparseFailedVersion);

        Assert.Equal("gravel", after.Discipline);
        Assert.Equal("ebike", after.Assist);
        Assert.Equal("indoor", after.Environment);
        Assert.True(after.Commute);
        Assert.Equal(bikeId, after.BikeId);
        Assert.Equal(RideStatus.Ready, after.Status);
        Assert.Equal(before.UploadedAt, after.UploadedAt);
        Assert.Equal(before.DedupKey, after.DedupKey);
        Assert.Equal(before.FileSha256, after.FileSha256);
        Assert.Equal(before.UserId, after.UserId);
        Assert.Equal(7, (await InDbAsync(api, db => db.RideFeels.SingleAsync(f => f.RideId == id, Ct))).Rpe);
        Assert.Equal(notifications, await InDbAsync(api, db => db.Notifications.CountAsync(n => n.UserId == member.Id, Ct)));
    }

    [Fact]
    public async Task Reparse_ShouldKeepTheTrainingLoadOfTheFirstRead_WhenTheMembersFtpChangedSince()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api, ftpW: 250);
        var id = await UploadAsync(member, Fit(new FitSession(Start, 120, NormalizedPower: 215)));
        var first = await LoadAsync(api, id);
        Assert.Equal(0.86, first.IntensityFactor);
        Assert.Equal(250, first.LoadFtpW);
        await SetFtpAsync(api, member, 300);
        await InDbAsync(api, db => db.Rides.Where(r => r.Id == id).ExecuteUpdateAsync(s => s.SetProperty(r => r.Tss, 1.0), Ct));

        await ReparseAsync(api);

        var after = await LoadAsync(api, id);
        Assert.Equal(first.IntensityFactor, after.IntensityFactor);
        Assert.Equal(first.Tss, after.Tss);
        Assert.Equal(250, after.LoadFtpW);
    }

    [Fact]
    public async Task Reparse_ShouldRecoverTheFtpFromTheStoredLoad_WhenTheRideWasReadBeforeItWasRecorded()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api, ftpW: 250);
        var id = await UploadAsync(member, Fit(new FitSession(Start, 120, NormalizedPower: 215)));
        var first = await LoadAsync(api, id);
        await SetFtpAsync(api, member, 300);
        await InDbAsync(api, db => db.Rides.Where(r => r.Id == id).ExecuteUpdateAsync(s => s
            .SetProperty(r => r.LoadFtpW, (int?)null)
            .SetProperty(r => r.LoadMaxHeartRate, (int?)null)
            .SetProperty(r => r.Trimp, 77.0), Ct));

        await ReparseAsync(api);

        var after = await LoadAsync(api, id);
        Assert.Equal(first.IntensityFactor, after.IntensityFactor);
        Assert.Equal(first.Tss, after.Tss);
        Assert.Equal(250, after.LoadFtpW);
        Assert.Equal(77.0, after.Trimp); // the maximum heart rate of that day cannot be recovered: left as stored
        Assert.Null(after.LoadMaxHeartRate);
    }

    [Fact]
    public async Task Reparse_ShouldLeaveTheStoredLoadUntouched_WhenTheFtpCannotBeRecovered()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api, ftpW: 250);
        var id = await UploadAsync(member, Fit(new FitSession(Start, 120, NormalizedPower: 215)));
        await SetFtpAsync(api, member, 300);
        await InDbAsync(api, db => db.Rides.Where(r => r.Id == id).ExecuteUpdateAsync(s => s
            .SetProperty(r => r.LoadFtpW, (int?)null)
            .SetProperty(r => r.IntensityFactor, (double?)null)
            .SetProperty(r => r.Tss, 33.3), Ct));

        await ReparseAsync(api);

        var after = await LoadAsync(api, id);
        Assert.Null(after.IntensityFactor);
        Assert.Equal(33.3, after.Tss);
        Assert.Null(after.LoadFtpW);
        Assert.Equal(Raised, after.ParserVersion);
    }

    [Fact]
    public async Task Reparse_ShouldKeepTheRideAsItWasAndNotRetryIt_WhenTheFileCannotBeRead()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var id = await UploadAsync(member, Fit(new FitSession(Start, 120, NormalizedPower: 215)));
        var before = await LoadAsync(api, id);
        var path = OriginalPath(api, before.FileSha256);
        var original = await File.ReadAllBytesAsync(path, Ct);
        File.Delete(path);

        await ReparseAsync(api);

        var failed = await LoadAsync(api, id);
        Assert.Equal(RideStatus.Ready, failed.Status);
        Assert.Null(failed.Error);
        Assert.Equal(before.DistanceM, failed.DistanceM);
        Assert.Equal(before.Streams!.Time.Length, failed.Streams!.Time.Length);
        Assert.Equal(before.Laps.Count, failed.Laps.Count);
        Assert.Equal(Raised, failed.ParserVersion);
        Assert.Equal(Raised, failed.ReparseFailedVersion);

        // Not tried again at the same version, even though the file is back.
        await File.WriteAllBytesAsync(path, original, Ct);
        await InDbAsync(api, db => db.Rides.Where(r => r.Id == id).ExecuteUpdateAsync(s => s.SetProperty(r => r.ElevationGainM, 999.0), Ct));
        await ReparseAsync(api);
        Assert.Equal(999.0, (await LoadAsync(api, id)).ElevationGainM);

        // A newer version tries again and succeeds.
        await ReparseAsync(api, Raised + 1);
        var healed = await LoadAsync(api, id);
        Assert.InRange(healed.ElevationGainM!.Value, 10, 13);
        Assert.Equal(Raised + 1, healed.ParserVersion);
        Assert.Null(healed.ReparseFailedVersion);
    }

    [Fact]
    public async Task Reparse_ShouldMakeAFailedRideNormalAndNotifyOnce_WhenItsFileReadsNow()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var id = await UploadAsync(member, "this is not a ride"u8.ToArray(), "broken.fit");
        var failed = await LoadAsync(api, id);
        Assert.Equal(RideStatus.Failed, failed.Status);

        // A parser fix: the same stored bytes now read.
        await File.WriteAllBytesAsync(OriginalPath(api, failed.FileSha256), Fit(new FitSession(Start, 120)), Ct);
        await ReparseAsync(api);
        Assert.Equal("ready", await WaitWhileProcessingAsync(member.Client, id));
        await ReparseAsync(api);

        var rescued = await LoadAsync(api, id);
        Assert.Equal(RideStatus.Ready, rescued.Status);
        Assert.Null(rescued.Error);
        Assert.NotNull(rescued.DistanceM);
        Assert.Equal(120, rescued.Streams!.Time.Length);
        var ready = await InDbAsync(api, db => db.Notifications.CountAsync(n => n.UserId == member.Id && n.Type == NotificationTypes.RideReady && n.RideId == id, Ct));
        Assert.Equal(1, ready);
    }

    [Fact]
    public async Task Reparse_ShouldKeepAFailedRideFailedAndSilent_WhenItsFileStillCannotBeRead()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var id = await UploadAsync(member, "this is not a ride"u8.ToArray(), "broken.fit");
        var notifications = await InDbAsync(api, db => db.Notifications.CountAsync(n => n.UserId == member.Id, Ct));

        await ReparseAsync(api);

        var ride = await LoadAsync(api, id);
        Assert.Equal(RideStatus.Failed, ride.Status);
        Assert.NotNull(ride.Error);
        Assert.Equal(Raised, ride.ReparseFailedVersion);
        Assert.Equal(notifications, await InDbAsync(api, db => db.Notifications.CountAsync(n => n.UserId == member.Id, Ct)));
    }

    [Fact]
    public async Task Reparse_ShouldKeepTheIdOfEveryRide_WhenOneFileHoldsSeveralActivities()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var first = await UploadAsync(member, Fit(new FitSession(Start, 60), new FitSession(Start.AddHours(2), 90)));
        var sha = (await LoadAsync(api, first)).FileSha256;
        var rides = await InDbAsync(api, db => db.Rides.AsNoTracking().Where(r => r.FileSha256 == sha).OrderBy(r => r.StartTime).ToListAsync(Ct));
        Assert.Equal(2, rides.Count);
        var ids = rides.Select(r => r.Id).ToList();
        await InDbAsync(api, db => db.Rides.Where(r => r.FileSha256 == sha).ExecuteUpdateAsync(s => s.SetProperty(r => r.ElevationGainM, 999.0), Ct));

        await ReparseAsync(api);

        var after = await InDbAsync(api, db => db.Rides.AsNoTracking().Include(r => r.Streams).Where(r => r.FileSha256 == sha).OrderBy(r => r.StartTime).ToListAsync(Ct));
        Assert.Equal(ids, after.Select(r => r.Id));
        Assert.Equal([60, 90], after.Select(r => r.Streams!.Time.Length));
        Assert.All(after, r => Assert.InRange(r.ElevationGainM!.Value, 4, 13));
        Assert.All(after, r => Assert.Equal(Raised, r.ParserVersion));
        Assert.Equal(rides.Select(r => r.StartTime), after.Select(r => r.StartTime));
    }

    [Fact]
    public async Task Reparse_ShouldNeitherHideNorRevealARide_WhenADuplicateExists()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var file = Fit(new FitSession(Start, 120));
        var kept = await UploadAsync(member, file, "a.fit");
        var copy = await UploadAsync(member, file, "b.fit");
        var hidden = await LoadAsync(api, copy);
        Assert.Equal(RideStatus.Duplicate, hidden.Status);

        await ReparseAsync(api);

        var after = await LoadAsync(api, copy);
        Assert.Equal(RideStatus.Duplicate, after.Status);
        Assert.Equal(kept, after.DuplicateOf);
        Assert.Equal(RideParserVersion.Current, after.ParserVersion); // never picked up
        Assert.Equal(RideStatus.Ready, (await LoadAsync(api, kept)).Status);
    }

    [Fact]
    public async Task Reparse_ShouldWaitForQueuedUploads_WhenTheIngestionQueueIsNotEmpty()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var id = await UploadAsync(member, Fit(new FitSession(Start, 120)));
        await InDbAsync(api, db => db.Rides.Where(r => r.Id == id).ExecuteUpdateAsync(s => s.SetProperty(r => r.ElevationGainM, 999.0), Ct));
        var queue = new IngestionQueue();
        queue.Enqueue(Guid.NewGuid()); // an upload nobody has read yet
        var service = new RideReparseService(api.Services, queue, api.Services.GetRequiredService<RideFileStore>(), TimeProvider.System, NullLogger<RideReparseService>.Instance);

        var running = service.RunAsync(Ct, Raised);
        // The run is waiting on the queued upload; it must not have touched the old ride by now.
        await Task.Delay(300, Ct);
        Assert.False(running.IsCompleted);
        Assert.Equal(999.0, (await LoadAsync(api, id)).ElevationGainM);

        await foreach (var _ in queue.ReadAllAsync(Ct)) break; // the upload is taken
        await running.WaitAsync(TimeSpan.FromSeconds(20), Ct);
        Assert.InRange((await LoadAsync(api, id)).ElevationGainM!.Value, 10, 13);
    }

    [Fact]
    public async Task Reparse_ShouldReadEveryRideAgain_WhenManyAreWaiting()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var file = Fit(new FitSession(Start, 60));
        var id = await UploadAsync(member, file);
        var sha = (await LoadAsync(api, id)).FileSha256;
        await InDbAsync(api, async db =>
        {
            var ride = await db.Rides.AsNoTracking().SingleAsync(r => r.Id == id, Ct);
            for (var i = 0; i < 45; i++)
            {
                db.Rides.Add(new Ride
                {
                    Id = Guid.CreateVersion7(),
                    UserId = member.Id,
                    Status = RideStatus.Ready,
                    FileSha256 = sha,
                    FileName = "x.fit",
                    UploadedAt = DateTimeOffset.UtcNow.AddMinutes(-i),
                    StartTime = ride.StartTime,
                    DedupKey = $"test:{Guid.NewGuid():N}:{ride.StartTime!.Value.ToUnixTimeSeconds()}",
                    ElevationGainM = 999,
                });
            }
            await db.SaveChangesAsync(Ct);
            return 0;
        });

        await ReparseAsync(api);

        var remaining = await InDbAsync(api, db => db.Rides.CountAsync(r => r.ParserVersion < Raised, Ct));
        Assert.Equal(0, remaining);
        Assert.Equal(46, await InDbAsync(api, db => db.Rides.CountAsync(r => r.ParserVersion == Raised && r.ElevationGainM < 100, Ct)));
    }

    [Fact]
    public async Task GetOverview_ShouldCountRidesWaitingAndNotReadAgain_WhenTheParserVersionWasRaised()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var waiting = await UploadAsync(member, Fit(new FitSession(Start, 120)));
        var stuck = await UploadAsync(member, Fit(new FitSession(Start.AddHours(3), 120)));
        await InDbAsync(api, db => db.Rides.Where(r => r.Id == waiting).ExecuteUpdateAsync(s => s.SetProperty(r => r.ParserVersion, 0), Ct));
        await InDbAsync(api, db => db.Rides.Where(r => r.Id == stuck).ExecuteUpdateAsync(s => s.SetProperty(r => r.ReparseFailedVersion, RideParserVersion.Current), Ct));
        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);

        var overview = await admin.GetFromJsonAsync<OverviewResponse>("/api/v1/admin/overview", Ct);

        Assert.Equal(RideParserVersion.Current, overview!.ParserVersion);
        Assert.Equal(1, overview.RidesToReread);
        Assert.Equal(1, overview.RidesNotReread);
    }

    [Theory]
    [InlineData(180, 600, 130)]
    [InlineData(250, 3600, 215)]
    [InlineData(250, 7200, 100)]
    [InlineData(400, 1800, 150)]
    [InlineData(95, 5400, 140)]
    public void RecoverFtp_ShouldReturnTheOriginalFtp_WhenTheLoadWasWorkedOutFromIt(int ftp, double movingS, int normalizedPower)
    {
        var (intensity, tss) = TrainingLoad.PowerLoad(normalizedPower, movingS, ftp);

        Assert.Equal(ftp, RideParserVersion.RecoverFtp(normalizedPower, movingS, intensity, tss));
    }

    [Fact]
    public void RecoverFtp_ShouldReturnNull_WhenNoPowerLoadWasStored()
    {
        Assert.Null(RideParserVersion.RecoverFtp(215, 600, null, null));
        Assert.Null(RideParserVersion.RecoverFtp(null, 600, 0.86, 10));
    }
}
