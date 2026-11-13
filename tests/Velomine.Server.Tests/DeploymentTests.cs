using System.Net;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Tests;

public sealed class DeploymentTests(PostgresFixture postgres)
{
    [Fact]
    public async Task DataProtection_ShouldPersistItsKeyRing_WhenTheServerStarts()
    {
        await using var api = await TestApi.StartAsync(postgres);

        var protector = api.Services.GetRequiredService<IDataProtectionProvider>().CreateProtector("test");
        protector.Protect("a cookie");

        Assert.NotEmpty(Directory.GetFiles(Path.Combine(api.FilesPath, "keys"), "*.xml"));
    }

    [Fact]
    public async Task BackgroundJobs_ShouldNotRun_WhenBackgroundIsDisabled()
    {
        await using var api = await TestApi.StartAsync(postgres,
            b => b.UseSetting("Velomine:Background:Enabled", "false"));

        var hosted = api.Services.GetServices<IHostedService>().Select(s => s.GetType()).ToList();

        // Only the migration runs on every instance; every job that reads or sends something waits for its owner.
        Assert.Equal([typeof(DatabaseMigrator)], hosted);
    }

    [Fact]
    public async Task Login_ShouldReturn429_WhenOneIpTriesTooManyPasswords()
    {
        await using var api = await TestApi.StartAsync(postgres,
            b => b.UseSetting("Velomine:RateLimits:AnonymousPerMinute", "3"));

        for (var attempt = 0; attempt < 3; attempt++)
            Assert.Equal(HttpStatusCode.Unauthorized,
                (await api.LoginAsync($"{Guid.NewGuid():N}@test.local", "Wrong-password-1")).StatusCode);

        var refused = await api.LoginAsync($"{Guid.NewGuid():N}@test.local", "Wrong-password-1");

        Assert.Equal(HttpStatusCode.TooManyRequests, refused.StatusCode);
    }

    [Fact]
    public async Task Register_ShouldReturn429_WhenOneIpCreatesTooManyAccounts()
    {
        await using var api = await TestApi.StartAsync(postgres,
            b => b.UseSetting("Velomine:RateLimits:AnonymousPerMinute", "3"));

        for (var attempt = 0; attempt < 3; attempt++)
            Assert.Equal(HttpStatusCode.Created,
                (await api.RegisterAsync(TestApi.NewEmail())).StatusCode);

        var refused = await api.RegisterAsync(TestApi.NewEmail());

        Assert.Equal(HttpStatusCode.TooManyRequests, refused.StatusCode);
    }

    [Fact]
    public async Task Uploads_ShouldReturn429_WhenOneMemberUploadsTooManyRides()
    {
        await using var api = await TestApi.StartAsync(postgres, b => b
            .UseSetting("Velomine:Accounts:RequireAdminApproval", "false")
            .UseSetting("Velomine:RateLimits:UploadsPerHour", "2")
            .UseSetting("Velomine:RateLimits:UploadBurst", "2"));
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        var member = await api.SignedInClientAsync(email, TestApi.MemberPassword);

        for (var attempt = 0; attempt < 2; attempt++)
            Assert.Equal(HttpStatusCode.Accepted, (await UploadAsync(member)).StatusCode);

        Assert.Equal(HttpStatusCode.TooManyRequests, (await UploadAsync(member)).StatusCode);
    }

    private static Task<HttpResponseMessage> UploadAsync(HttpClient client) =>
        client.PostAsync(
            "/api/v1/rides/uploads",
            new MultipartFormDataContent { { new ByteArrayContent([1, 2, 3]), "file", "ride.gpx" } },
            TestContext.Current.CancellationToken);

    [Fact]
    public void PasswordResetThrottle_ShouldRefuseTheTwentyFirstAttempt_WhenTheWindowHasNotPassed()
    {
        var clock = new FixedTime(new DateTimeOffset(2026, 11, 13, 10, 0, 0, TimeSpan.Zero));
        var throttle = new PasswordResetThrottle(new MemoryCache(new MemoryCacheOptions()), clock);
        var context = new DefaultHttpContext();
        context.Connection.RemoteIpAddress = IPAddress.Loopback;

        for (var attempt = 0; attempt < PasswordResetThrottle.Limit; attempt++)
            Assert.True(throttle.Allowed("forgot", context), $"Attempt {attempt + 1} was refused inside the budget.");

        Assert.False(throttle.Allowed("forgot", context));
        Assert.True(throttle.Allowed("reset", context)); // the two endpoints have separate budgets
    }

    [Fact]
    public void PasswordResetThrottle_ShouldAllowAgain_WhenTheWindowHasPassed()
    {
        var cache = new MemoryCache(new MemoryCacheOptions());
        var start = new DateTimeOffset(2026, 11, 13, 10, 0, 0, TimeSpan.Zero);
        var context = new DefaultHttpContext();
        context.Connection.RemoteIpAddress = IPAddress.Loopback;
        for (var attempt = 0; attempt < PasswordResetThrottle.Limit; attempt++)
            new PasswordResetThrottle(cache, new FixedTime(start)).Allowed("forgot", context);

        Assert.False(new PasswordResetThrottle(cache, new FixedTime(start)).Allowed("forgot", context));
        Assert.True(new PasswordResetThrottle(cache, new FixedTime(start + PasswordResetThrottle.Window)).Allowed("forgot", context));
    }
}
