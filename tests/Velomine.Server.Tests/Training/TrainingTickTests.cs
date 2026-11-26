using System.IO.Compression;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Dynastream.Fit;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;
using Velomine.Server.Features.Training;
using Velomine.Server.Features.Wellbeing;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Training;

/// <summary>
/// A ride ticks the session of its day as soon as it is ready, or asks about one the day before or after. The score it
/// then earns is computed on read, the rider's own, and a re-read, a duplicate and a deleted ride each leave the
/// session exactly where they should.
/// </summary>
public sealed class TrainingTickTests(PostgresFixture postgres, TrainingTickHost host) : IClassFixture<TrainingTickHost>
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>The local day of a ride read from <see cref="TestRideFiles.Start"/>: the file says +2 hours.</summary>
    private static readonly DateOnly Day = new(2026, 10, 3);

    internal static readonly DateTimeOffset Now = new(2026, 10, 3, 20, 0, 0, TimeSpan.Zero);

    private Task<TestApi> StartAsync(DateTimeOffset? now = null) =>
        TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
            b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FakeTime { Now = now ?? Now }));
        });

    /// <summary>A rider with an FTP, a plan that is on, and one open session on the day.</summary>
    private static async Task<(TestMember Member, Guid SessionId)> RiderAsync(
        TestApi api, DateOnly day, string recipe = "R05", int minutes = 60, int? ftpW = 250, int[]? days = null,
        bool on = true, string state = TrainingSessionStates.Planned)
    {
        var member = await api.NewMemberAsync("Rider");
        if (ftpW is { } ftp)
            (await member.Client.PutAsJsonAsync("/api/v1/accounts/me/ftp", new SetFtpRequest(ftp), Ct)).EnsureSuccessStatusCode();
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        db.TrainingPlans.Add(new TrainingPlan
        {
            UserId = member.Id,
            Goal = TrainingGoals.Fitter,
            Days = days ?? [1, 3, 5],
            HoursPerWeek = 6,
            IsOn = on,
            LastPlannedFor = day,
            UpdatedAt = DateTimeOffset.UtcNow,
        });
        var session = new TrainingSession
        {
            Id = Guid.CreateVersion7(),
            UserId = member.Id,
            LocalDate = day,
            Recipe = recipe,
            Minutes = minutes,
            BlockPercents = [91],
            State = state,
            CreatedAt = DateTimeOffset.UtcNow,
        };
        db.TrainingSessions.Add(session);
        await db.SaveChangesAsync(Ct);
        return (member, session.Id);
    }

    private static async Task<RideResponse> UploadAsync(HttpClient client, byte[] file, string key = "ride-1")
    {
        var request = new HttpRequestMessage(HttpMethod.Post, "/api/v1/rides/uploads")
        {
            Content = new MultipartFormDataContent { { new ByteArrayContent(file), "file", "ride.fit" } },
        };
        request.Headers.Add("Idempotency-Key", key);
        var accepted = await client.SendAsync(request, Ct);
        Assert.Equal(HttpStatusCode.Accepted, accepted.StatusCode);
        var id = (await accepted.Content.ReadFromJsonAsync<UploadRideResponse>(Ct))!.RideId;
        return await TestApi.WaitForReadAsync(client, id);
    }

    private static async Task<TrainingSession> SessionAsync(TestApi api, Guid id)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        return await db.TrainingSessions.AsNoTracking().SingleAsync(s => s.Id == id, Ct);
    }

    private static async Task<TrainingWeek> WeekAsync(TestMember member)
    {
        var weeks = await member.Client.GetFromJsonAsync<TrainingWeeksResponse>("/api/v1/training/week", Ct);
        return Assert.Single(weeks!.Weeks);
    }

    private static async Task<NotificationResponse[]> NotificationsAsync(TestMember member) =>
        (await member.Client.GetFromJsonAsync<ListNotificationsResponse>("/api/v1/notifications", Ct))!.Notifications;

    [Fact]
    public async Task Ride_ShouldTickTheSessionOfItsDay_WhenItIsReady()
    {
        var api = host.Api;
        var (member, sessionId) = await RiderAsync(api, Day);

        var ride = await UploadAsync(member.Client, Fit(new FitSession(Start, 3600, SubSport: SubSport.IndoorCycling)));

        Assert.Equal("ready", ride.Status);
        var session = await SessionAsync(api, sessionId);
        Assert.Equal(TrainingSessionStates.Done, session.State);
        Assert.Equal(ride.Id, session.RideId);
        Assert.Equal(Day, session.LocalDate);
    }

    [Fact]
    public async Task Week_ShouldCarryTheScoreAndTheMainSet_WhenTheSessionIsDone()
    {
        var api = host.Api;
        var (member, _) = await RiderAsync(api, Day);
        // A steady 150 W for the hour: 36 of effort against the 57.8 the hour plans, and nothing in the 220–235 W band.
        await UploadAsync(member.Client, Fit(new FitSession(Start, 3600, Power: _ => 150)));

        var week = await WeekAsync(member);
        var session = Assert.Single(week.Sessions);

        Assert.Equal(TrainingSessionStates.Done, session.State);
        var result = Assert.IsType<SessionResult>(session.Result);
        Assert.Equal(65, result.Score);
        Assert.Equal(60, result.PlannedMinutes);
        Assert.Equal(60, result.DoneMinutes, 1);
        Assert.Equal(57.8, result.PlannedEffort);
        Assert.Equal(36, result.DoneEffort!.Value, 1);
        Assert.Equal(0, result.MainSetShare!.Value, 3);
        Assert.Equal(new MainSetTarget("power", 228, 150), result.MainSet);
    }

    [Fact]
    public async Task Week_ShouldReachOneHundred_WhenTheRideIsThePlan()
    {
        var api = host.Api;
        var (member, _) = await RiderAsync(api, Day);
        // 228 W is the middle of the main set's band: the whole hour in target, more effort than planned.
        await UploadAsync(member.Client, Fit(new FitSession(Start, 3600, Power: _ => 228)));

        var session = Assert.Single((await WeekAsync(member)).Sessions);

        Assert.Equal(100, session.Result!.Score);
        Assert.Equal(1, session.Result.MainSetShare!.Value, 3);
    }

    [Fact]
    public async Task Ride_ShouldAskOnTheRidePageAndInTheInbox_WhenItIsCloseToTheSessionBeforeIt()
    {
        var api = host.Api;
        var (member, sessionId) = await RiderAsync(api, Day.AddDays(-1));

        var ride = await UploadAsync(member.Client, Fit(new FitSession(Start, 3600)));

        var question = Assert.IsType<TrainingRideMatch>(ride.Training);
        Assert.Equal(TrainingSessionStates.Planned, question.State);
        Assert.Equal(sessionId, question.SessionId);
        Assert.Equal(Day.AddDays(-1), question.LocalDate);
        // The question is in the inbox, and the session is still open where it was planned.
        var notification = Assert.Single(await NotificationsAsync(member),
            n => n.Type == NotificationTypes.TrainingSessionQuestion);
        Assert.Equal(ride.Id, notification.RideId);
        Assert.Equal(sessionId, notification.Training!.SessionId);
        var session = await SessionAsync(api, sessionId);
        Assert.Equal(TrainingSessionStates.Planned, session.State);
        Assert.Equal(sessionId, session.Id);
        Assert.Equal(Day.AddDays(-1), session.LocalDate);
        Assert.Equal(ride.Id, session.QuestionRideId);
    }

    [Fact]
    public async Task Session_ShouldTickAndMoveToTheRidesDay_WhenTheRiderAnswersYes()
    {
        var api = host.Api;
        var (member, sessionId) = await RiderAsync(api, Day.AddDays(-1));
        var ride = await UploadAsync(member.Client, Fit(new FitSession(Start, 3600)));

        var answer = await member.Client.PostAsJsonAsync($"/api/v1/training/sessions/{sessionId}/match",
            new MatchTrainingSessionRequest { Id = sessionId, RideId = ride.Id, Answer = SessionMatchAnswers.Yes }, Ct);

        Assert.Equal(HttpStatusCode.NoContent, answer.StatusCode);
        var session = await SessionAsync(api, sessionId);
        Assert.Equal(TrainingSessionStates.Done, session.State);
        Assert.Equal(ride.Id, session.RideId);
        Assert.Equal(Day, session.LocalDate);
        Assert.Null(session.QuestionRideId);
        // The question is answered, so the inbox does not keep it.
        Assert.DoesNotContain(await NotificationsAsync(member), n => n.Type == NotificationTypes.TrainingSessionQuestion);
        // The week shows it where it happened, with the score.
        var week = await WeekAsync(member);
        Assert.Equal(Day, Assert.Single(week.Sessions).LocalDate);
        Assert.NotNull(week.Sessions[0].Result);
    }

    [Fact]
    public async Task Ride_ShouldNeverAskAgain_WhenTheRiderAnswersNo()
    {
        var api = host.Api;
        var (member, sessionId) = await RiderAsync(api, Day.AddDays(-1));
        var ride = await UploadAsync(member.Client, Fit(new FitSession(Start, 3600)));

        var answer = await member.Client.PostAsJsonAsync($"/api/v1/training/sessions/{sessionId}/match",
            new MatchTrainingSessionRequest { Id = sessionId, RideId = ride.Id, Answer = SessionMatchAnswers.No }, Ct);

        Assert.Equal(HttpStatusCode.NoContent, answer.StatusCode);
        var session = await SessionAsync(api, sessionId);
        Assert.Null(session.QuestionRideId);
        // Its day was yesterday, so saying no leaves it missed rather than open.
        Assert.Equal(TrainingSessionStates.Missed, session.State);
        Assert.Null((await member.Client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{ride.Id}", Ct))!.Training);
        Assert.DoesNotContain(await NotificationsAsync(member), n => n.Type == NotificationTypes.TrainingSessionQuestion);
        // A re-read is not a first read: the question stays answered.
        await api.Services.GetRequiredService<RideReparseService>().RunAsync(Ct, RideParserVersion.Current + 1);
        Assert.Null((await member.Client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{ride.Id}", Ct))!.Training);
    }

    [Fact]
    public async Task Session_ShouldGoBackToOpen_WhenTheRideIsDeleted()
    {
        var api = host.Api;
        var (member, sessionId) = await RiderAsync(api, Day);
        var ride = await UploadAsync(member.Client, Fit(new FitSession(Start, 3600)));
        Assert.Equal(TrainingSessionStates.Done, (await SessionAsync(api, sessionId)).State);

        (await member.Client.DeleteAsync($"/api/v1/rides/{ride.Id}", Ct)).EnsureSuccessStatusCode();

        var session = await SessionAsync(api, sessionId);
        Assert.Equal(TrainingSessionStates.Planned, session.State);
        Assert.Null(session.RideId);
    }

    [Fact]
    public async Task Session_ShouldGoBackToMissed_WhenItsDayHasPassedAndItsRideIsDeleted()
    {
        await using var api = await StartAsync(Now.AddDays(2));
        var (member, sessionId) = await RiderAsync(api, Day);
        var ride = await UploadAsync(member.Client, Fit(new FitSession(Start, 3600)));

        (await member.Client.DeleteAsync($"/api/v1/rides/{ride.Id}", Ct)).EnsureSuccessStatusCode();

        var session = await SessionAsync(api, sessionId);
        Assert.Equal(TrainingSessionStates.Missed, session.State);
        Assert.Null(session.RideId);
    }

    [Fact]
    public async Task Session_ShouldNotTickAgain_WhenTheRideIsReadAgain()
    {
        var api = host.Api;
        var (member, sessionId) = await RiderAsync(api, Day);
        var ride = await UploadAsync(member.Client, Fit(new FitSession(Start, 3600)));
        var ticked = await SessionAsync(api, sessionId);
        var notifications = (await NotificationsAsync(member)).Length;

        // A better parser reads the same file again: the ride keeps the session it ticked, and asks nothing new.
        await api.Services.GetRequiredService<RideReparseService>().RunAsync(Ct, RideParserVersion.Current + 1);

        var session = await SessionAsync(api, sessionId);
        Assert.Equal(ticked.RideId, session.RideId);
        Assert.Equal(TrainingSessionStates.Done, session.State);
        Assert.Equal(notifications, (await NotificationsAsync(member)).Length);
        Assert.Null(session.QuestionRideId);
    }

    [Fact]
    public async Task Session_ShouldTickOnce_WhenTheSameFileIsUploadedTwice()
    {
        var api = host.Api;
        var (member, sessionId) = await RiderAsync(api, Day);
        var file = Fit(new FitSession(Start, 3600));

        var first = await UploadAsync(member.Client, file, key: "first");
        var second = await UploadAsync(member.Client, file, key: "second");

        Assert.Equal("duplicate", second.Status);
        var session = await SessionAsync(api, sessionId);
        Assert.Equal(TrainingSessionStates.Done, session.State);
        Assert.Equal(first.Id, session.RideId);
    }

    [Fact]
    public async Task Session_ShouldNotAsk_WhenTheRideIsFurtherFromThePlanThanAQuarter()
    {
        var api = host.Api;
        var (member, sessionId) = await RiderAsync(api, Day.AddDays(-1));

        // Two hours and a half against the hour planned: outside a quarter in duration.
        var ride = await UploadAsync(member.Client, Fit(new FitSession(Start, 9000)));

        Assert.Null(ride.Training);
        Assert.Null((await SessionAsync(api, sessionId)).QuestionRideId);
        Assert.DoesNotContain(await NotificationsAsync(member), n => n.Type == NotificationTypes.TrainingSessionQuestion);
    }

    [Fact]
    public async Task Export_ShouldCarryTheComputedScore_WhenASessionIsDone()
    {
        var api = host.Api;
        var (member, _) = await RiderAsync(api, Day);
        await UploadAsync(member.Client, Fit(new FitSession(Start, 3600, Power: _ => 150)));

        // The export writes the score the app's session page shows, worked out from the ride: nothing about it is stored.
        await using var scope = api.Services.CreateAsyncScope();
        var export = ActivatorUtilities.CreateInstance<AccountExport>(scope.ServiceProvider);
        using var output = new MemoryStream();
        await export.WriteAsync(member.Id, output, scope.ServiceProvider.GetRequiredService<TimeProvider>(), Ct);
        output.Position = 0;

        using var zip = new ZipArchive(output, ZipArchiveMode.Read);
        var entry = zip.GetEntry("training-plan.json");
        Assert.NotNull(entry);
        using var stream = entry.Open();
        using var document = await JsonDocument.ParseAsync(stream, cancellationToken: Ct);
        var session = Assert.Single(document.RootElement.GetProperty("sessions").EnumerateArray());
        Assert.Equal(65, session.GetProperty("score").GetInt32());
        Assert.Equal(TrainingSessionStates.Done, session.GetProperty("state").GetString());
    }


    [Fact]
    public async Task Export_ShouldCarryTheWeeksThePlanMadeLighterAndItsDeclinedFiles_WhenItHasThem()
    {
        var api = host.Api;
        var (member, sessionId) = await RiderAsync(api, Day);
        var ride = await UploadAsync(member.Client, Fit(new FitSession(Start, 3600)));
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var plan = await db.TrainingPlans.FirstAsync(p => p.UserId == member.Id, Ct);
            plan.LighterWeeks = [new DateOnly(2026, 9, 28)];
            plan.DeclinedFileHashes = ["declined-file-hash"];
            // The rider is being asked whether that ride was this session.
            (await db.TrainingSessions.FirstAsync(s => s.Id == sessionId, Ct)).QuestionRideId = ride.Id;
            await db.SaveChangesAsync(Ct);
        }

        // Every column the plan and its sessions hold is the member's data, so the export carries all three.
        await using var read = api.Services.CreateAsyncScope();
        var export = ActivatorUtilities.CreateInstance<AccountExport>(read.ServiceProvider);
        using var output = new MemoryStream();
        await export.WriteAsync(member.Id, output, read.ServiceProvider.GetRequiredService<TimeProvider>(), Ct);
        output.Position = 0;

        using var zip = new ZipArchive(output, ZipArchiveMode.Read);
        using var document = await JsonDocument.ParseAsync(zip.GetEntry("training-plan.json")!.Open(), cancellationToken: Ct);
        var plan0 = document.RootElement.GetProperty("plan");
        Assert.Equal("2026-09-28", plan0.GetProperty("lighterWeeks")[0].GetString());
        Assert.Equal("declined-file-hash", plan0.GetProperty("declinedFileHashes")[0].GetString());
        var session = Assert.Single(document.RootElement.GetProperty("sessions").EnumerateArray());
        Assert.Equal(ride.Id, session.GetProperty("questionRideId").GetGuid());
    }

    [Fact]
    public async Task Week_ShouldScoreOneHundredOnTimeAlone_WhenTheRideHasNoSensorsAndNoRating()
    {
        var api = host.Api;
        var (member, _) = await RiderAsync(api, Day, recipe: "R14", minutes: 30);
        // No meter, no strap, no estimate and no rating: nothing but the time can be measured, and the time was the
        // plan. Half a score because the other half has no number would be the whole plan counted as half.
        await UploadAsync(member.Client, Fit(new FitSession(Start, 1800, NoPower: true, NoHeartRate: true)));

        var session = Assert.Single((await WeekAsync(member)).Sessions);

        Assert.NotNull(session.Result);
        Assert.Null(session.Result!.DoneEffort);
        Assert.Equal(100, session.Result.Score);
        Assert.Null(session.Result.MainSetShare);
        Assert.Null(session.Result.MainSet);
    }

    [Fact]
    public async Task Session_ShouldNotTick_WhenAutoTrainingIsOffAndAnOldRideIsImported()
    {
        // Auto training off: the past sessions stay as history, and an import of last month must not write into them.
        await using var api = await StartAsync(Now.AddDays(10));
        var (member, sessionId) = await RiderAsync(api, Day, on: false);

        var ride = await UploadAsync(member.Client, Fit(new FitSession(Start, 3600)));

        var session = await SessionAsync(api, sessionId);
        Assert.Equal(TrainingSessionStates.Planned, session.State);
        Assert.Null(session.RideId);
        Assert.Null(ride.Training);
        Assert.DoesNotContain(await NotificationsAsync(member),
            n => n.Type == NotificationTypes.TrainingSessionQuestion);
    }

    [Fact]
    public async Task Session_ShouldTickAndStayEasy_WhenTheRideIsOnTheDayOfASessionMadeEasy()
    {
        var api = host.Api;
        var (member, sessionId) = await RiderAsync(api, Day, state: TrainingSessionStates.Easy);

        var ride = await UploadAsync(member.Client, Fit(new FitSession(Start, 3600)));

        var session = await SessionAsync(api, sessionId);
        Assert.Equal(ride.Id, session.RideId);
        // Made easy on the day is still the session the rider rode: it is ticked, and it stays easy.
        Assert.Equal(TrainingSessionStates.Easy, session.State);
    }

    [Fact]
    public async Task BackToTrainingPlan_ShouldRefuse_WhenARideHasTickedTheEasySession()
    {
        var api = host.Api;
        var (member, sessionId) = await RiderAsync(api, Day);
        (await member.Client.PostAsync($"/api/v1/training/sessions/{sessionId}/easy", null, Ct)).EnsureSuccessStatusCode();
        var ride = await UploadAsync(member.Client, Fit(new FitSession(Start, 3600)));

        // The ride ticked the easy session (W6). A page left open must not undo the day the rider rode, so the answer is
        // the conflict the app already shows for a refusal, and the day stays as it was ridden.
        var answer = await member.Client.DeleteAsync($"/api/v1/training/sessions/{sessionId}/easy", Ct);

        Assert.Equal(HttpStatusCode.Conflict, answer.StatusCode);
        var session = await SessionAsync(api, sessionId);
        Assert.Equal(TrainingSessionStates.Easy, session.State);
        Assert.Equal(SessionAdaptation.EasyRecipe, session.Recipe);
        Assert.Equal(ride.Id, session.RideId);
    }

    [Fact]
    public async Task Session_ShouldTickOnTheSecondTry_WhenTheFirstSaveLosesTheSession()
    {
        await using var api = await StartAsync();
        var (member, sessionId) = await RiderAsync(api, Day);
        await LoseFirstSessionUpdateAsync(api);

        await UploadAsync(member.Client, Fit(new FitSession(Start, 3600)));

        // The ride's save lost the session row it was changing — what the nightly planning does when it deletes and
        // re-adds the day — and the matching was tried again afterwards, instead of the tick being thrown away.
        var session = await SessionAsync(api, sessionId);
        Assert.Equal(TrainingSessionStates.Done, session.State);
        Assert.NotNull(session.RideId);
    }

    private static async Task LoseFirstSessionUpdateAsync(TestApi api)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        // The first update of a session lands on no row at all, which is what EF reports as a concurrency failure.
        // A sequence, not a row: the save's transaction rolls back, and the marker has to survive it.
        await db.Database.ExecuteSqlRawAsync("""
            CREATE SEQUENCE training.update_once;
            CREATE FUNCTION training.skip_one_update() RETURNS trigger AS $$
            BEGIN
                IF nextval('training.update_once') = 1 THEN RETURN NULL; END IF;
                RETURN NEW;
            END; $$ LANGUAGE plpgsql;
            CREATE TRIGGER skip_one_update BEFORE UPDATE ON training.sessions
            FOR EACH ROW EXECUTE FUNCTION training.skip_one_update();
            """, Ct);
    }

    [Fact]
    public async Task Question_ShouldNameTheSessionInTheRidersOwnLanguage_WhenTheMemberReadsItalian()
    {
        var api = host.Api;
        var (member, _) = await RiderAsync(api, Day.AddDays(-1));
        (await member.Client.PutAsJsonAsync("/api/v1/accounts/me/language",
            new SetMyLanguageRequest { Language = "it" }, Ct)).EnsureSuccessStatusCode();

        await UploadAsync(member.Client, Fit(new FitSession(Start, 3600)));

        // The email says the subject, so it is the Italian name of R05 ("Strong and steady" in English).
        var notification = Assert.Single(await NotificationsAsync(member),
            n => n.Type == NotificationTypes.TrainingSessionQuestion);
        Assert.Equal("Forte e costante", notification.Subject);
    }

    [Fact]
    public async Task Notifications_ShouldLoseTheQuestion_WhenTheRiderTurnsAutoTrainingOff()
    {
        var api = host.Api;
        var (member, sessionId) = await RiderAsync(api, Day.AddDays(-1));
        var ride = await UploadAsync(member.Client, Fit(new FitSession(Start, 3600)));
        Assert.NotNull((await SessionAsync(api, sessionId)).QuestionRideId);

        (await member.Client.DeleteAsync("/api/v1/training/plan", Ct)).EnsureSuccessStatusCode();

        // The questions go with the switch: the session of today and later is gone, and one on a past session has
        // nothing left to be answered against. The ride page shows no card, and the inbox keeps no bare subject.
        Assert.DoesNotContain(await NotificationsAsync(member),
            n => n.Type == NotificationTypes.TrainingSessionQuestion);
        Assert.Null((await member.Client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{ride.Id}", Ct))!.Training);
    }

    [Fact]
    public async Task Ride_ShouldNotBeAskedAboutAgain_WhenItsDuplicateIsReadAfterTheAnswerIsNo()
    {
        var api = host.Api;
        var (member, sessionId) = await RiderAsync(api, Day.AddDays(-1));
        var file = Fit(new FitSession(Start, 3600));
        var first = await UploadAsync(member.Client, file, key: "first");
        var copy = await UploadAsync(member.Client, file, key: "copy");
        Assert.Equal("duplicate", copy.Status);

        (await member.Client.PostAsJsonAsync($"/api/v1/training/sessions/{sessionId}/match",
            new MatchTrainingSessionRequest { Id = sessionId, RideId = first.Id, Answer = SessionMatchAnswers.No }, Ct))
            .EnsureSuccessStatusCode();

        // Deleting the ride brings the hidden copy back to be read as a new ride: the same file is not asked about
        // again, because the rider already said it was not this session.
        (await member.Client.DeleteAsync($"/api/v1/rides/{first.Id}", Ct)).EnsureSuccessStatusCode();
        var reread = await TestApi.WaitForReadAsync(member.Client, copy.Id);

        Assert.Equal("ready", reread.Status);
        Assert.Null(reread.Training);
        Assert.DoesNotContain(await NotificationsAsync(member),
            n => n.Type == NotificationTypes.TrainingSessionQuestion);
    }

    [Fact]
    public async Task Session_ShouldNotBeVisibleToAnotherMember_WhenTheyReadTheirOwnWeek()
    {
        var api = host.Api;
        var (member, _) = await RiderAsync(api, Day);
        var ride = await UploadAsync(member.Client, Fit(new FitSession(Start, 3600)));
        var other = await api.NewMemberAsync("Other Rider");

        // The week and the score are the rider's own: the other member has no plan, so no week, and no ride either.
        Assert.Equal(HttpStatusCode.NotFound,
            (await other.Client.GetAsync("/api/v1/training/week", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound,
            (await other.Client.GetAsync($"/api/v1/rides/{ride.Id}", Ct)).StatusCode);
        Assert.Equal(1, (await WeekAsync(member)).Sessions.Count(s => s.Result is not null));
    }

    [Fact]
    public async Task Session_ShouldStayWhereItIs_WhenTheSweepPlansTheWeekWithAQuestionOpen()
    {
        var api = host.Api;
        // The session is tomorrow, a day the sweep may rewrite, and the ride that might be it is today.
        var (member, sessionId) = await RiderAsync(api, Day.AddDays(1), days: [0, 1, 2, 3, 4, 5, 6]);
        await UploadAsync(member.Client, Fit(new FitSession(Start, 3600)));
        Assert.NotNull((await SessionAsync(api, sessionId)).QuestionRideId);

        // The nightly planning leaves a session the rider is being asked about where it is, so the question survives
        // the night and its answer has a session to move.
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var user = await db.Users.AsNoTracking().SingleAsync(u => u.Id == member.Id, Ct);
            var plan = await db.TrainingPlans.SingleAsync(p => p.UserId == member.Id, Ct);
            await WeekPlanning.PlanAsync(db, user, plan, MemberClock.For(user.TimeZone, user.FirstDayOfWeek,
                scope.ServiceProvider.GetRequiredService<TimeProvider>()),
                scope.ServiceProvider.GetRequiredService<TimeProvider>(), Ct);
        }

        var session = await SessionAsync(api, sessionId);
        Assert.NotNull(session.QuestionRideId);
        Assert.Equal(Day.AddDays(1), session.LocalDate);
    }
}

/// <summary>One server for the class: every test makes its own member and only reads or changes that member's data.</summary>
public sealed class TrainingTickHost(PostgresFixture postgres) : IAsyncLifetime
{
    public TestApi Api { get; private set; } = null!;

    public async ValueTask InitializeAsync() => Api = await TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        // Tests sign members in from the same address; one server per test gave each a fresh budget.
        b.UseSetting("Velomine:RateLimits:AnonymousPerMinute", "100000");
        b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FakeTime { Now = TrainingTickTests.Now }));
    });

    public ValueTask DisposeAsync() => Api.DisposeAsync();
}
