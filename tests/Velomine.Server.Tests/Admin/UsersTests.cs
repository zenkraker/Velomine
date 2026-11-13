using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Admin;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Bikes;
using Velomine.Server.Features.Rides;
using static Velomine.Server.Tests.Rides.TestRideFiles;
using Member = Velomine.Server.Tests.TestMember;

namespace Velomine.Server.Tests.Admin;

public sealed class UsersTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));

    private static Task<HttpClient> AdminAsync(TestApi api) => api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);


    private static Task<Member> NewMemberAsync(TestApi api) => api.NewMemberAsync();

    private static async Task<AdminUserSummary[]> UsersAsync(HttpClient admin) =>
        (await admin.GetFromJsonAsync<ListAdminUsersResponse>("/api/v1/admin/users", Ct))!.Users;

    private static Task UploadAndWaitAsync(HttpClient client, byte[] file) => TestApi.UploadAndWaitAsync(client, file);

    private static int FileCount(TestApi api)
    {
        var originals = Path.Combine(api.FilesPath, "originals");
        return Directory.Exists(originals) ? Directory.GetFiles(originals, "*", SearchOption.AllDirectories).Length : 0;
    }

    [Fact]
    public async Task AdminUsers_ShouldBeForbidden_WhenCallerIsNotAnAdmin()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var other = Guid.NewGuid();
        var role = new SetUserRolesRequest { Roles = ["coach"] };

        Assert.Equal(HttpStatusCode.Unauthorized, (await api.CreateClient().GetAsync("/api/v1/admin/users", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await member.Client.GetAsync("/api/v1/admin/users", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await member.Client.PutAsJsonAsync($"/api/v1/admin/users/{other}/roles", role, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await member.Client.PostAsync($"/api/v1/admin/users/{other}/lock", null, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await member.Client.PostAsync($"/api/v1/admin/users/{other}/unlock", null, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await member.Client.DeleteAsync($"/api/v1/admin/users/{other}", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await member.Client.GetAsync("/api/v1/admin/overview", Ct)).StatusCode);
    }

    [Fact]
    public async Task AdminUsers_ShouldListEveryAccountWithRolesAndState_WhenCalledByAnAdmin()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var member = await NewMemberAsync(api);

        var users = await UsersAsync(admin);

        Assert.Equal(2, users.Length);
        var admins = users.Single(u => u.Email == TestApi.AdminEmail);
        Assert.Equal(["admin", "member"], admins.Roles);
        var rider = users.Single(u => u.Id == member.Id);
        Assert.Equal(["member"], rider.Roles);
        Assert.True(rider.IsApproved);
        Assert.False(rider.IsLockedOut);
    }

    [Fact]
    public async Task AdminUserRoles_ShouldKeepMemberAndRejectSelfDemotion_WhenChanged()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var member = await NewMemberAsync(api);

        var coach = await admin.PutAsJsonAsync($"/api/v1/admin/users/{member.Id}/roles", new SetUserRolesRequest { Roles = ["coach"] }, Ct);
        Assert.Equal(HttpStatusCode.OK, coach.StatusCode);
        Assert.Equal(["coach", "member"], (await coach.Content.ReadFromJsonAsync<AdminUserSummary>(Ct))!.Roles);

        // Promoted to admin, they can use the admin endpoints (after signing in again to get the new role).
        await admin.PutAsJsonAsync($"/api/v1/admin/users/{member.Id}/roles", new SetUserRolesRequest { Roles = ["admin"] }, Ct);
        var promoted = await api.SignedInClientAsync(member.Email, TestApi.MemberPassword);
        Assert.Equal(HttpStatusCode.OK, (await promoted.GetAsync("/api/v1/admin/users", Ct)).StatusCode);

        // Back to a plain member.
        var plain = await admin.PutAsJsonAsync($"/api/v1/admin/users/{member.Id}/roles", new SetUserRolesRequest { Roles = [] }, Ct);
        Assert.Equal(["member"], (await plain.Content.ReadFromJsonAsync<AdminUserSummary>(Ct))!.Roles);

        var self = (await UsersAsync(admin)).Single(u => u.Email == TestApi.AdminEmail).Id;
        Assert.Equal(HttpStatusCode.Conflict, (await admin.PutAsJsonAsync($"/api/v1/admin/users/{self}/roles", new SetUserRolesRequest { Roles = ["coach"] }, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await admin.PutAsJsonAsync($"/api/v1/admin/users/{member.Id}/roles", new SetUserRolesRequest { Roles = ["root"] }, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await admin.PutAsJsonAsync($"/api/v1/admin/users/{Guid.NewGuid()}/roles", new SetUserRolesRequest { Roles = ["coach"] }, Ct)).StatusCode);
    }

    [Fact]
    public async Task SetUserRoles_ShouldRefuseTheOldRefreshToken_WhenTheAdminRoleIsRemoved()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var member = await NewMemberAsync(api);
        await admin.PutAsJsonAsync($"/api/v1/admin/users/{member.Id}/roles", new SetUserRolesRequest { Roles = ["admin"] }, Ct);

        var login = await api.LoginAsync(member.Email, TestApi.MemberPassword);
        var refreshToken = JsonDocument.Parse(await login.Content.ReadAsStringAsync(Ct)).RootElement
            .GetProperty("refreshToken").GetString()!;

        Assert.Equal(HttpStatusCode.OK,
            (await admin.PutAsJsonAsync($"/api/v1/admin/users/{member.Id}/roles", new SetUserRolesRequest { Roles = [] }, Ct)).StatusCode);

        var renew = await api.CreateClient()
            .PostAsJsonAsync("/api/v1/accounts/refresh", new RefreshRequest(refreshToken), Ct);
        Assert.Equal(HttpStatusCode.Unauthorized, renew.StatusCode);
    }

    [Fact]
    public async Task AdminUserLock_ShouldBlockSignInAndRenewal_WhenAccountIsLocked()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var member = await NewMemberAsync(api);
        var login = await api.LoginAsync(member.Email, TestApi.MemberPassword);
        var refreshToken = JsonDocument.Parse(await login.Content.ReadAsStringAsync(Ct)).RootElement.GetProperty("refreshToken").GetString()!;

        Assert.Equal(HttpStatusCode.NoContent, (await admin.PostAsync($"/api/v1/admin/users/{member.Id}/lock", null, Ct)).StatusCode);

        Assert.Equal((HttpStatusCode)423, (await api.LoginAsync(member.Email, TestApi.MemberPassword)).StatusCode); // locked
        var renew = await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/refresh", new RefreshRequest(refreshToken), Ct);
        Assert.Equal(HttpStatusCode.Unauthorized, renew.StatusCode);
        Assert.True((await UsersAsync(admin)).Single(u => u.Id == member.Id).IsLockedOut);
        Assert.Equal(1, (await admin.GetFromJsonAsync<OverviewResponse>("/api/v1/admin/overview", Ct))!.Locked);

        Assert.Equal(HttpStatusCode.NoContent, (await admin.PostAsync($"/api/v1/admin/users/{member.Id}/unlock", null, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await api.LoginAsync(member.Email, TestApi.MemberPassword)).StatusCode);
        Assert.False((await UsersAsync(admin)).Single(u => u.Id == member.Id).IsLockedOut);
    }

    [Fact]
    public async Task AdminUsers_ShouldRefuseSelfLockAndDelete_WhenAccountIsSelfOrUnknown()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var self = (await UsersAsync(admin)).Single(u => u.Email == TestApi.AdminEmail).Id;

        Assert.Equal(HttpStatusCode.Conflict, (await admin.PostAsync($"/api/v1/admin/users/{self}/lock", null, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Conflict, (await admin.DeleteAsync($"/api/v1/admin/users/{self}", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await admin.PostAsync($"/api/v1/admin/users/{Guid.NewGuid()}/lock", null, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await admin.PostAsync($"/api/v1/admin/users/{Guid.NewGuid()}/unlock", null, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await admin.DeleteAsync($"/api/v1/admin/users/{Guid.NewGuid()}", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await api.LoginAsync(TestApi.AdminEmail, TestApi.AdminPassword)).StatusCode);
    }

    [Fact]
    public async Task AdminUsers_ShouldRemoveEverythingOwned_WhenAccountIsDeleted()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var member = await NewMemberAsync(api);
        var bystander = await NewMemberAsync(api);
        await UploadAndWaitAsync(member.Client, Fit(new FitSession(Start, 120)));
        await UploadAndWaitAsync(bystander.Client, Fit(new FitSession(Start.AddHours(5), 120)));
        await member.Client.PostAsJsonAsync("/api/v1/bikes", new CreateBikeRequest { Name = "Road", Kind = "road", WheelCircumferenceMm = 2105, InitialDistanceM = 0 }, Ct);
        await member.Client.PostAsJsonAsync("/api/v1/analytics/goals", new CreateGoalRequest { Period = "week", Metric = "distance", Target = 1000 }, Ct);
        Assert.Equal(2, FileCount(api));

        Assert.Equal(HttpStatusCode.NoContent, (await admin.DeleteAsync($"/api/v1/admin/users/{member.Id}", Ct)).StatusCode);

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.False(await db.Users.AnyAsync(u => u.Id == member.Id, Ct));
        Assert.False(await db.Rides.AnyAsync(r => r.UserId == member.Id, Ct));
        Assert.False(await db.Set<Bike>().AnyAsync(b => b.UserId == member.Id, Ct));
        Assert.False(await db.Set<Goal>().AnyAsync(g => g.UserId == member.Id, Ct));
        Assert.False(await db.Notifications.AnyAsync(n => n.UserId == member.Id, Ct));
        Assert.Equal(1, FileCount(api)); // only the bystander's file is left
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.LoginAsync(member.Email, TestApi.MemberPassword)).StatusCode);
        Assert.True(await db.Rides.AnyAsync(r => r.UserId == bystander.Id, Ct)); // and nobody else lost anything
    }

    [Fact]
    public async Task AdminUsers_ShouldKeepSharedFile_WhenOnlyOneOwnerIsDeleted()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var first = await NewMemberAsync(api);
        var second = await NewMemberAsync(api);
        var same = Fit(new FitSession(Start, 120));
        await UploadAndWaitAsync(first.Client, same);
        await UploadAndWaitAsync(second.Client, same);
        Assert.Equal(1, FileCount(api)); // stored once, named by its hash

        await admin.DeleteAsync($"/api/v1/admin/users/{first.Id}", Ct);
        Assert.Equal(1, FileCount(api));

        await admin.DeleteAsync($"/api/v1/admin/users/{second.Id}", Ct);
        Assert.Equal(0, FileCount(api));
    }

    [Fact]
    public async Task AdminOverview_ShouldCountAccountsRidesAndStorage_WhenRequested()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var member = await NewMemberAsync(api);
        await UploadAndWaitAsync(member.Client, Fit(new FitSession(Start, 120)));

        var overview = await admin.GetFromJsonAsync<OverviewResponse>("/api/v1/admin/overview", Ct);

        Assert.Equal(2, overview!.Accounts);
        Assert.Equal(0, overview.WaitingForApproval);
        Assert.Equal(0, overview.Locked);
        Assert.Equal(1, overview.Rides);
        Assert.True(overview.RideFilesBytes > 0);
        Assert.NotEmpty(overview.Version);
    }
}
