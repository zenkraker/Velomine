using System.Net;
using System.Net.Http.Json;
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
    public async Task BackgroundJobs_ShouldNotRepeatOnATimer_WhenTheTestHostStartsTheServer()
    {
        await using var api = await TestApi.StartAsync(postgres);

        var hosted = api.Services.GetServices<IHostedService>().Select(s => s.GetType()).ToList();

        // The test host drops the loops that only repeat on a timer; a test drives them with RunOnceAsync instead.
        Assert.DoesNotContain(hosted, t => t.Name.Contains("Notifier", StringComparison.Ordinal));
        Assert.DoesNotContain(hosted, t => t.Name.Contains("Cleanup", StringComparison.Ordinal));
        Assert.DoesNotContain(hosted, t => t.Name.Contains("Reparse", StringComparison.Ordinal));
        Assert.DoesNotContain(hosted, t => t.Name.Contains("Backfill", StringComparison.Ordinal));
        Assert.DoesNotContain(hosted, t => t.Name.Contains("Retention", StringComparison.Ordinal));
        // What a server must do before it answers is still there: the roles and admin, and the upload reader.
        Assert.Contains(hosted, t => t.Name.Contains("RideIngestion", StringComparison.Ordinal));
        Assert.Contains(hosted, t => t.Name.Contains("AccountsStartup", StringComparison.Ordinal));
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

    [Fact]
    public async Task Uploads_ShouldAcceptThemAgain_WhenTheBucketHasRefilled()
    {
        // One token a minute, so a burst of one and a later one both fit a refreshed bucket.
        await using var api = await TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
            b.UseSetting("Velomine:RateLimits:UploadsPerHour", "60");
            b.UseSetting("Velomine:RateLimits:UploadBurst", "1");
        });
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        var member = await api.SignedInClientAsync(email, TestApi.MemberPassword);

        Assert.Equal(HttpStatusCode.Accepted, (await UploadAsync(member)).StatusCode);
        Assert.Equal(HttpStatusCode.TooManyRequests, (await UploadAsync(member)).StatusCode); // the bucket is empty

        // Wait past the one-minute replenishment period, then the same member is let in again.
        await Task.Delay(TimeSpan.FromSeconds(62), Ct);

        Assert.Equal(HttpStatusCode.Accepted, (await UploadAsync(member)).StatusCode);
    }

    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private static Task<HttpResponseMessage> UploadAsync(HttpClient client) =>
        client.PostAsync(
            "/api/v1/rides/uploads",
            new MultipartFormDataContent { { new ByteArrayContent([1, 2, 3]), "file", "ride.gpx" } },
            Ct);

    [Fact]
    public void PasswordResetThrottle_ShouldKeepOneCacheEntry_WhenTheSameAddressRepeats()
    {
        using var cache = new MemoryCache(new MemoryCacheOptions());
        var throttle = new PasswordResetThrottle(cache, TimeProvider.System);

        for (var attempt = 0; attempt < 50; attempt++)
            throttle.AllowedForEmail($"rider{attempt % PasswordResetThrottle.ForgotLimit}@test.local");

        Assert.Equal(PasswordResetThrottle.ForgotLimit, cache.Count);
    }

    [Fact]
    public void PasswordResetThrottle_ShouldRefuseTheNextAsk_WhenOneAccountReachesTheLimit()
    {
        using var cache = new MemoryCache(new MemoryCacheOptions());
        var throttle = new PasswordResetThrottle(cache, new MovableTime(DateTimeOffset.UtcNow));

        for (var attempt = 0; attempt < PasswordResetThrottle.ForgotLimit; attempt++)
            Assert.True(throttle.AllowedForEmail("rider@test.local"), $"attempt {attempt + 1} inside the limit was refused");

        Assert.False(throttle.AllowedForEmail("rider@test.local"));
        // The address is matched the way people type it: case and surrounding spaces do not buy another budget.
        Assert.False(throttle.AllowedForEmail("  Rider@Test.Local "));
    }

    [Fact]
    public void PasswordResetThrottle_ShouldAllowAgain_WhenTheWindowHasPassed()
    {
        using var cache = new MemoryCache(new MemoryCacheOptions());
        var clock = new MovableTime(DateTimeOffset.UtcNow);
        var throttle = new PasswordResetThrottle(cache, clock);
        for (var attempt = 0; attempt < PasswordResetThrottle.ForgotLimit; attempt++) throttle.AllowedForEmail("rider@test.local");
        Assert.False(throttle.AllowedForEmail("rider@test.local"));

        clock.Advance(PasswordResetThrottle.Window);

        Assert.True(throttle.AllowedForEmail("rider@test.local"));
    }

    [Fact]
    public void PasswordResetThrottle_ShouldNotKeepRefusing_WhenTheCallerKeepsAskingInsideTheWindow()
    {
        using var cache = new MemoryCache(new MemoryCacheOptions());
        var clock = new MovableTime(DateTimeOffset.UtcNow);
        var throttle = new PasswordResetThrottle(cache, clock);
        for (var attempt = 0; attempt < PasswordResetThrottle.ForgotLimit; attempt++) throttle.AllowedForEmail("rider@test.local");
        // A refusal must not move the window: asking again does not lock the member out for longer.
        clock.Advance(TimeSpan.FromMinutes(14));
        Assert.False(throttle.AllowedForEmail("rider@test.local"));

        clock.Advance(TimeSpan.FromMinutes(1));

        Assert.True(throttle.AllowedForEmail("rider@test.local"));
    }

    [Fact]
    public void PasswordResetThrottle_ShouldCountEachAddressApart_WhenForgetsFromOneIpFloodTheOthers()
    {
        using var cache = new MemoryCache(new MemoryCacheOptions());
        var throttle = new PasswordResetThrottle(cache, TimeProvider.System);
        for (var i = 0; i < 100; i++) throttle.AllowedForEmail($"rider{i}@test.local");

        Assert.True(throttle.AllowedForEmail("another@test.local"));
        Assert.True(throttle.AllowedFromAddress(new DefaultHttpContext()));
    }

    [Fact]
    public async Task ForgotPassword_ShouldReturn429_WhenOneAccountAsksTooOften()
    {
        await using var api = await ApiWithEmailAsync();
        var email = TestApi.NewEmail();

        var codes = new List<HttpStatusCode>();
        for (var attempt = 0; attempt <= PasswordResetThrottle.ForgotLimit; attempt++)
            codes.Add((await ForgotAsync(api, email)).StatusCode);

        Assert.All(codes.Take(PasswordResetThrottle.ForgotLimit), code => Assert.Equal(HttpStatusCode.Accepted, code));
        Assert.Equal(HttpStatusCode.TooManyRequests, codes[^1]);
    }

    [Fact]
    public async Task ForgotPassword_ShouldStillAnswerEveryoneElse_WhenOneAccountAsksTooOften()
    {
        await using var api = await ApiWithEmailAsync();
        var flooded = TestApi.NewEmail();
        for (var attempt = 0; attempt <= PasswordResetThrottle.ForgotLimit; attempt++) await ForgotAsync(api, flooded);

        var other = await ForgotAsync(api, TestApi.NewEmail());

        Assert.Equal(HttpStatusCode.Accepted, other.StatusCode);
    }

    [Fact]
    public async Task ResetPassword_ShouldReturn429_WhenOneAddressGuessesTooOften()
    {
        await using var api = await ApiWithEmailAsync();
        var email = TestApi.NewEmail();

        var codes = new List<HttpStatusCode>();
        for (var attempt = 0; attempt <= PasswordResetThrottle.ResetLimit; attempt++)
            codes.Add((await api.CreateClient().PostAsJsonAsync(
                "/api/v1/accounts/password/reset",
                new ResetPasswordRequest(email, "a-guess", "New-password-1"),
                Ct)).StatusCode);

        Assert.All(codes.Take(PasswordResetThrottle.ResetLimit), code => Assert.Equal(HttpStatusCode.BadRequest, code));
        Assert.Equal(HttpStatusCode.TooManyRequests, codes[^1]);
    }

    private async Task<TestApi> ApiWithEmailAsync() =>
        await TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Smtp:Host", "smtp.club.example");
            b.UseSetting("Velomine:Smtp:From", "velomine@club.example");
            // The per-address policy is not what this measures; make its minute generous.
            b.UseSetting("Velomine:RateLimits:AnonymousPerMinute", "1000");
        });

    private static Task<HttpResponseMessage> ForgotAsync(TestApi api, string email) =>
        api.CreateClient().PostAsJsonAsync(
            "/api/v1/accounts/password/forgot",
            new ForgotPasswordRequest(email),
            Ct);

    /// <summary>A clock a test can move forward, so the window passing needs no waiting.</summary>
    private sealed class MovableTime(DateTimeOffset now) : TimeProvider
    {
        private DateTimeOffset current = now;

        public override DateTimeOffset GetUtcNow() => current;

        public void Advance(TimeSpan by) => current += by;
    }
}
