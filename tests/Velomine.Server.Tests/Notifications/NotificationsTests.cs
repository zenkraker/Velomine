using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Bikes;
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Rides;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Notifications;

[Collection("postgres")]
public sealed class NotificationsTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync(bool approval = false) =>
        TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", approval ? "true" : "false"));

    private static Task<HttpClient> NewMemberAsync(TestApi api) => api.NewMemberClientAsync();

    private static Task<RideResponse> UploadAndWaitAsync(HttpClient client, byte[] file, string name = "ride.fit") => TestApi.UploadAndWaitAsync(client, file, name);

    private static async Task<ListNotificationsResponse> ListAsync(HttpClient client) =>
        (await client.GetFromJsonAsync<ListNotificationsResponse>("/api/v1/notifications", Ct))!;

    [Fact]
    public async Task Notifications_ShouldReportEachUpload_WhenRidesAreProcessed()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        var ready = await UploadAndWaitAsync(member, Fit(new FitSession(Start, 120)), "morning.fit");
        var duplicate = await UploadAndWaitAsync(member, Fit(new FitSession(Start, 120)), "again.fit");
        var failed = await UploadAndWaitAsync(member, Bytes("not a ride"), "broken.fit");

        var list = await ListAsync(member);
        Assert.Equal(3, list.UnreadCount);
        Assert.Equal(
            [
                (NotificationTypes.RideFailed, "broken.fit", (Guid?)failed.Id),
                (NotificationTypes.RideDuplicate, "again.fit", duplicate.Id),
                (NotificationTypes.RideReady, "morning.fit", ready.Id),
            ],
            list.Notifications.Select(n => (n.Type, n.Subject, n.RideId)));
        Assert.All(list.Notifications, n => Assert.False(n.IsRead));
    }

    [Fact]
    public async Task Notifications_ShouldMarkReadOneOrAll_WhenTheyBelongToTheMember()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var other = await NewMemberAsync(api);
        await UploadAndWaitAsync(member, Fit(new FitSession(Start, 120)));
        await UploadAndWaitAsync(member, Fit(new FitSession(Start.AddHours(3), 120)));
        var first = (await ListAsync(member)).Notifications[^1];

        Assert.Empty((await ListAsync(other)).Notifications);
        Assert.Equal(HttpStatusCode.NotFound, (await other.PostAsync($"/api/v1/notifications/{first.Id}/read", null, Ct)).StatusCode);

        Assert.Equal(HttpStatusCode.NoContent, (await member.PostAsync($"/api/v1/notifications/{first.Id}/read", null, Ct)).StatusCode);
        var afterOne = await ListAsync(member);
        Assert.Equal(1, afterOne.UnreadCount);
        Assert.True(afterOne.Notifications.Single(n => n.Id == first.Id).IsRead);

        Assert.Equal(HttpStatusCode.NoContent, (await member.PostAsync("/api/v1/notifications/read", null, Ct)).StatusCode);
        Assert.Equal(0, (await ListAsync(member)).UnreadCount);
    }

    [Fact]
    public async Task Notifications_ShouldBeRemoved_WhenTheirRideIsDeleted()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var ride = await UploadAndWaitAsync(member, Fit(new FitSession(Start, 120)));

        (await member.DeleteAsync($"/api/v1/rides/{ride.Id}", Ct)).EnsureSuccessStatusCode();

        Assert.Empty((await ListAsync(member)).Notifications);
    }

    [Fact]
    public async Task Notifications_ShouldTellAdminsAboutSignUps_WhenApprovalIsRequired()
    {
        await using var api = await StartAsync(approval: true);
        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        var email = TestApi.NewEmail();
        var registered = await api.RegisterAsync(email, name: "Newcomer");
        var account = await registered.Content.ReadFromJsonAsync<RegisterResponse>(Ct);

        var waiting = (await ListAsync(admin)).Notifications.Single();
        Assert.Equal(NotificationTypes.SignUpWaiting, waiting.Type);
        Assert.Equal($"Newcomer ({email})", waiting.Subject);
        Assert.Equal(account!.Id, waiting.AboutUserId);

        (await admin.PostAsync($"/api/v1/accounts/users/{account.Id}/approve", null, Ct)).EnsureSuccessStatusCode();

        var after = await ListAsync(admin);
        Assert.Equal(0, after.UnreadCount);
        Assert.True(after.Notifications.Single().IsRead);
    }

    [Fact]
    public async Task Notifications_ShouldStayQuiet_WhenAccountsNeedNoApproval()
    {
        await using var api = await StartAsync();
        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        await NewMemberAsync(api);

        Assert.Empty((await ListAsync(admin)).Notifications);
    }

    [Fact]
    public async Task Notifications_ShouldWarnOncePerLevel_WhenAPartWearsOut()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var bike = await (await member.PostAsJsonAsync("/api/v1/bikes",
            new CreateBikeRequest { Name = "Road bike", Kind = "road", WheelCircumferenceMm = 2105, InitialDistanceM = 0 }, Ct))
            .Content.ReadFromJsonAsync<BikeDetailResponse>(Ct);
        // Each test ride is 952 m, so a 1 km chain is "soon" after one ride and worn after two.
        (await member.PostAsJsonAsync($"/api/v1/bikes/{bike!.Bike.Id}/components",
            new CreateComponentRequest { Type = "chain", InstalledOn = new DateOnly(2026, 10, 1), ExpectedDistanceM = 1000 }, Ct)).EnsureSuccessStatusCode();

        await UploadAndWaitAsync(member, Fit(new FitSession(Start, 120)));
        Assert.Equal(["part_soon"], PartTypes(await ListAsync(member)));

        await UploadAndWaitAsync(member, Fit(new FitSession(Start.AddHours(3), 120)));
        await UploadAndWaitAsync(member, Fit(new FitSession(Start.AddHours(6), 120)));
        var list = await ListAsync(member);
        Assert.Equal(["part_worn", "part_soon"], PartTypes(list));
        var worn = list.Notifications.First(n => n.Type == NotificationTypes.PartWorn);
        Assert.Equal("Chain on Road bike", worn.Subject);
        Assert.Equal(bike.Bike.Id, worn.BikeId);
        Assert.NotNull(worn.ComponentId);
    }

    private static string[] PartTypes(ListNotificationsResponse list) =>
        [.. list.Notifications.Select(n => n.Type).Where(t => t.StartsWith("part_", StringComparison.Ordinal))];
}
