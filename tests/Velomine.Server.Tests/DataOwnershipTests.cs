using System.IO.Compression;
using System.Net;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Bikes;
using Velomine.Server.Features.Rides;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests;

/// <summary>Members own their data: they can take all of it out, and delete their account with everything in it.</summary>
[Collection("postgres")]
public sealed class DataOwnershipTests(PostgresFixture postgres, FakeOidcFixture oidc)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.UseSetting("Velomine:Sso:Authority", FakeOidcFixture.Authority);
        b.UseSetting("Velomine:Sso:AppClientId", FakeOidcFixture.AppClientId);
        b.UseSetting("Velomine:Sso:AllowInsecureHttp", "true");
    });

    private sealed record Member(string Email, Guid Id, HttpClient Client);

    private static async Task<Member> NewMemberAsync(TestApi api, string name = "Test Rider")
    {
        var email = TestApi.NewEmail();
        var id = (await (await api.RegisterAsync(email, name: name)).Content.ReadFromJsonAsync<RegisterResponse>(Ct))!.Id;
        return new Member(email, id, await api.SignedInClientAsync(email, TestApi.MemberPassword));
    }

    private static async Task UploadAsync(HttpClient client, byte[] file, string name = "morning.fit")
    {
        var form = new MultipartFormDataContent { { new ByteArrayContent(file), "file", name } };
        var id = (await (await client.PostAsync("/api/v1/rides/uploads", form, Ct)).Content.ReadFromJsonAsync<UploadRideResponse>(Ct))!.RideId;
        for (var i = 0; i < 100; i++)
        {
            if ((await client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{id}", Ct))!.Status != "processing") return;
            await Task.Delay(100, Ct);
        }

        throw new TimeoutException("The ride was still processing after 10 seconds.");
    }

    private static int FileCount(TestApi api)
    {
        var originals = Path.Combine(api.FilesPath, "originals");
        return Directory.Exists(originals) ? Directory.GetFiles(originals, "*", SearchOption.AllDirectories).Length : 0;
    }

    private static async Task<string> LinkAsync(HttpClient member) =>
        (await (await member.PostAsync("/api/v1/accounts/me/export-link", null, Ct)).Content.ReadFromJsonAsync<ExportLinkResponse>(Ct))!.Path;

    private static async Task<Dictionary<string, byte[]>> UnzipAsync(HttpResponseMessage response)
    {
        using var zip = new ZipArchive(await response.Content.ReadAsStreamAsync(Ct), ZipArchiveMode.Read);
        var entries = new Dictionary<string, byte[]>();
        foreach (var entry in zip.Entries)
        {
            using var stream = entry.Open();
            using var memory = new MemoryStream();
            await stream.CopyToAsync(memory, Ct);
            entries[entry.FullName] = memory.ToArray();
        }

        return entries;
    }

    [Fact]
    public async Task DataOwnership_ShouldExportAllAndOnlyMyData_WhenDownloadingTheExport()
    {
        await using var api = await StartAsync();
        var me = await NewMemberAsync(api, "Ada");
        var other = await NewMemberAsync(api, "Grace");
        var original = Fit(new FitSession(Start, 120));
        await UploadAsync(me.Client, original);
        await UploadAsync(other.Client, Fit(new FitSession(Start.AddHours(6), 120)), "grace-ride.fit");
        await me.Client.PutAsJsonAsync("/api/v1/accounts/me/profile", new UpdateProfileRequest("Ada", 265, 61.5, 1995, "Europe/Rome", "sunday"), Ct);
        var bike = await (await me.Client.PostAsJsonAsync("/api/v1/bikes", new CreateBikeRequest { Name = "Road", Kind = "road", WheelCircumferenceMm = 2105, InitialDistanceM = 1000 }, Ct)).Content.ReadFromJsonAsync<BikeDetailResponse>(Ct);
        await me.Client.PostAsJsonAsync($"/api/v1/bikes/{bike!.Bike.Id}/components", new CreateComponentRequest { Type = "chain", InstalledOn = new DateOnly(2026, 10, 1), ExpectedDistanceM = 4_000_000 }, Ct);
        await me.Client.PostAsJsonAsync("/api/v1/analytics/goals", new CreateGoalRequest { Period = "week", Metric = "distance", Target = 100_000 }, Ct);

        // The link is the sign-in: a browser with no session of its own can open it.
        var download = await api.CreateClient().GetAsync(await LinkAsync(me.Client), Ct);

        Assert.Equal(HttpStatusCode.OK, download.StatusCode);
        Assert.Equal("application/zip", download.Content.Headers.ContentType!.MediaType);
        Assert.Matches(@"^velomine-data-\d{4}-\d{2}-\d{2}\.zip$", download.Content.Headers.ContentDisposition!.FileName!.Trim('"'));
        var entries = await UnzipAsync(download);
        Assert.Contains("README.txt", entries.Keys);
        string Text(string name) => Encoding.UTF8.GetString(entries[name]);

        var profile = JsonDocument.Parse(Text("profile.json")).RootElement;
        Assert.Equal(me.Email, profile.GetProperty("email").GetString());
        Assert.Equal(265, profile.GetProperty("ftpW").GetInt32());
        Assert.Equal("Europe/Rome", profile.GetProperty("timeZone").GetString());

        var bikes = JsonDocument.Parse(Text("bikes.json")).RootElement;
        Assert.Equal("Road", bikes[0].GetProperty("name").GetString());
        Assert.Equal("chain", bikes[0].GetProperty("components")[0].GetProperty("type").GetString());
        Assert.Equal("distance", JsonDocument.Parse(Text("goals.json")).RootElement[0].GetProperty("metric").GetString());
        Assert.True(JsonDocument.Parse(Text("notifications.json")).RootElement.GetArrayLength() >= 1);

        // One ride, and its original file is in the ZIP byte for byte.
        var rides = JsonDocument.Parse(Text("rides.json")).RootElement;
        Assert.Equal(1, rides.GetArrayLength());
        Assert.Equal("morning.fit", rides[0].GetProperty("ride").GetProperty("fileName").GetString());
        var fileEntry = rides[0].GetProperty("file").GetString()!;
        Assert.StartsWith("files/", fileEntry);
        Assert.Equal(original, entries[fileEntry]);

        // Nothing that is not mine, and nothing secret.
        var everything = string.Join("\n", entries.Where(e => e.Key.EndsWith(".json")).Select(e => Text(e.Key)));
        Assert.DoesNotContain(other.Email, everything);
        Assert.DoesNotContain("grace-ride.fit", everything);
        Assert.DoesNotContain("passwordHash", everything, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("securityStamp", everything, StringComparison.OrdinalIgnoreCase);
        Assert.Single(entries.Keys, k => k.StartsWith("files/", StringComparison.Ordinal));
    }

    [Fact]
    public async Task DataOwnership_ShouldRejectExportLinks_WhenTheyAreInvalidExpiredOrForged()
    {
        await using var api = await StartAsync();
        var me = await NewMemberAsync(api);
        var good = await LinkAsync(me.Client);

        Assert.Equal(HttpStatusCode.Unauthorized, (await api.CreateClient().PostAsync("/api/v1/accounts/me/export-link", null, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.CreateClient().GetAsync("/api/v1/accounts/export/not-a-token", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.CreateClient().GetAsync(good[..^3] + "abc", Ct)).StatusCode); // changed

        // A link that has expired.
        var protector = api.Services.GetRequiredService<IDataProtectionProvider>().CreateProtector("velomine.export").ToTimeLimitedDataProtector();
        var expired = protector.Protect(me.Id.ToString("N"), DateTimeOffset.UtcNow.AddMinutes(-1));
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.CreateClient().GetAsync("/api/v1/accounts/export/" + Uri.EscapeDataString(expired), Ct)).StatusCode);

        // A protected value made for another purpose is not a link.
        var other = api.Services.GetRequiredService<IDataProtectionProvider>().CreateProtector("something.else").ToTimeLimitedDataProtector()
            .Protect(me.Id.ToString("N"), DateTimeOffset.UtcNow.AddMinutes(1));
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.CreateClient().GetAsync("/api/v1/accounts/export/" + Uri.EscapeDataString(other), Ct)).StatusCode);

        Assert.Equal(HttpStatusCode.OK, (await api.CreateClient().GetAsync(good, Ct)).StatusCode);
    }

    [Fact]
    public async Task DataOwnership_ShouldDeleteNothing_WhenTheDeletePasswordIsWrong()
    {
        await using var api = await StartAsync();
        var me = await NewMemberAsync(api);
        await UploadAsync(me.Client, Fit(new FitSession(Start, 120)));

        Assert.Equal(HttpStatusCode.Forbidden, (await me.Client.PostAsJsonAsync("/api/v1/accounts/me/delete", new DeleteMyAccountRequest("wrong-password-1", null), Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await me.Client.PostAsJsonAsync("/api/v1/accounts/me/delete", new DeleteMyAccountRequest(null, me.Email), Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await api.LoginAsync(me.Email, TestApi.MemberPassword)).StatusCode);
        Assert.Equal(1, FileCount(api));
    }

    [Fact]
    public async Task DataOwnership_ShouldRemoveEverythingIOwn_WhenDeletingMyAccount()
    {
        await using var api = await StartAsync();
        var me = await NewMemberAsync(api);
        var other = await NewMemberAsync(api);
        await UploadAsync(me.Client, Fit(new FitSession(Start, 120)));
        await UploadAsync(other.Client, Fit(new FitSession(Start.AddHours(6), 120)));
        await me.Client.PostAsJsonAsync("/api/v1/bikes", new CreateBikeRequest { Name = "Road", Kind = "road", WheelCircumferenceMm = 2105, InitialDistanceM = 0 }, Ct);
        await me.Client.PostAsJsonAsync("/api/v1/analytics/goals", new CreateGoalRequest { Period = "week", Metric = "distance", Target = 1000 }, Ct);

        var deleted = await me.Client.PostAsJsonAsync("/api/v1/accounts/me/delete", new DeleteMyAccountRequest(TestApi.MemberPassword, null), Ct);

        Assert.Equal(HttpStatusCode.NoContent, deleted.StatusCode);
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.False(await db.Users.AnyAsync(u => u.Id == me.Id, Ct));
        Assert.False(await db.Rides.AnyAsync(r => r.UserId == me.Id, Ct));
        Assert.False(await db.Set<Bike>().AnyAsync(b => b.UserId == me.Id, Ct));
        Assert.False(await db.Set<Goal>().AnyAsync(g => g.UserId == me.Id, Ct));
        Assert.False(await db.Notifications.AnyAsync(n => n.UserId == me.Id, Ct));
        Assert.Equal(1, FileCount(api)); // only the other member's file is left
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.LoginAsync(me.Email, TestApi.MemberPassword)).StatusCode);
        Assert.True(await db.Rides.AnyAsync(r => r.UserId == other.Id, Ct));
    }

    [Fact]
    public async Task DataOwnership_ShouldAskForTheEmail_WhenAnAccountWithoutPasswordDeletesItself()
    {
        await using var api = await StartAsync();
        string email = TestApi.NewEmail();
        Guid id;
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var users = scope.ServiceProvider.GetRequiredService<UserManager<User>>();
            var user = new User { UserName = email, Email = email, DisplayName = "SSO Rider", IsApproved = true, CreatedAt = DateTimeOffset.UtcNow };
            Assert.True((await users.CreateAsync(user)).Succeeded); // no password: it signs in through single sign-on
            await users.AddToRoleAsync(user, Roles.Member);
            id = user.Id;
        }

        // The phone's sign-in hands out tokens for such an account (see SsoAppTests); play that part.
        await oidc.EnsureStartedAsync();
        var idToken = oidc.SignToken($"data-ownership-{id:N}", email);
        var exchanged = await api.CreateClient().PostAsJsonAsync(
            "/api/v1/accounts/sso/token", new ExchangeSsoTokenRequest(idToken, null), Ct);
        exchanged.EnsureSuccessStatusCode();
        var token = (await exchanged.Content.ReadFromJsonAsync<JsonElement>(Ct)).GetProperty("accessToken").GetString();
        var client = api.CreateClient();
        client.DefaultRequestHeaders.Authorization = new("Bearer", token);

        Assert.False((await client.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct))!.HasPassword);
        Assert.Equal(HttpStatusCode.Forbidden, (await client.PostAsJsonAsync("/api/v1/accounts/me/delete", new DeleteMyAccountRequest(null, "someone@else.test"), Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await client.PostAsJsonAsync("/api/v1/accounts/me/delete", new DeleteMyAccountRequest(null, null), Ct)).StatusCode);

        Assert.Equal(HttpStatusCode.NoContent, (await client.PostAsJsonAsync("/api/v1/accounts/me/delete", new DeleteMyAccountRequest(null, "  " + email.ToUpperInvariant() + " "), Ct)).StatusCode);
        await using var check = api.Services.CreateAsyncScope();
        Assert.False(await check.ServiceProvider.GetRequiredService<VelomineDbContext>().Users.AnyAsync(u => u.Id == id, Ct));
    }

    [Fact]
    public async Task DataOwnership_ShouldBlockDeletion_WhenTheCallerIsTheOnlyAdmin()
    {
        await using var api = await StartAsync();
        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        var successor = await NewMemberAsync(api);

        var blocked = await admin.PostAsJsonAsync("/api/v1/accounts/me/delete", new DeleteMyAccountRequest(TestApi.AdminPassword, null), Ct);
        Assert.Equal(HttpStatusCode.Conflict, blocked.StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await api.LoginAsync(TestApi.AdminEmail, TestApi.AdminPassword)).StatusCode);

        await admin.PutAsJsonAsync($"/api/v1/admin/users/{successor.Id}/roles", new Features.Admin.SetUserRolesRequest { Roles = ["admin"] }, Ct);
        var allowed = await admin.PostAsJsonAsync("/api/v1/accounts/me/delete", new DeleteMyAccountRequest(TestApi.AdminPassword, null), Ct);
        Assert.Equal(HttpStatusCode.NoContent, allowed.StatusCode);
    }

    [Fact]
    public async Task DataOwnership_ShouldReportHasPassword_WhenReadingTheProfile()
    {
        await using var api = await StartAsync();
        var me = await NewMemberAsync(api);

        Assert.True((await me.Client.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct))!.HasPassword);
    }
}
