using System.Net;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Tests;

[Collection("postgres")]
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

        var hosted = api.Services.GetServices<IHostedService>().ToList();

        Assert.Contains(hosted, service => service is DatabaseMigrator);
        Assert.DoesNotContain(hosted, service => service is RideIngestionService);
        Assert.DoesNotContain(hosted, service => service is AccountsStartup);
    }

    [Fact]
    public async Task BackgroundJobs_ShouldRun_WhenBackgroundIsEnabled()
    {
        await using var api = await TestApi.StartAsync(postgres);

        var hosted = api.Services.GetServices<IHostedService>().ToList();

        Assert.Contains(hosted, service => service is RideIngestionService);
        Assert.Contains(hosted, service => service is AccountsStartup);
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
            .UseSetting("Velomine:RateLimits:UploadsPerHour", "2"));
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
    public void PasswordResetThrottle_ShouldKeepOneCacheEntry_WhenTheSameAddressRepeats()
    {
        using var cache = new MemoryCache(new MemoryCacheOptions());
        var throttle = new PasswordResetThrottle(cache, TimeProvider.System);
        var context = new DefaultHttpContext();
        context.Connection.RemoteIpAddress = IPAddress.Loopback;

        for (var attempt = 0; attempt < 50; attempt++)
            throttle.Allowed("forgot", context);

        Assert.Equal(1, cache.Count);
    }
}
