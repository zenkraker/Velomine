using System.Net;
using System.Net.Http.Json;
using Dynastream.Fit;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Rides;

/// <summary>
/// A Zwift ride is a cycling FIT file from the Zwift manufacturer with the virtual-activity sub-sport, power from a
/// smart trainer, and coordinates that land on real places (Watopia lands near the Solomon Islands) that are not the
/// virtual world. The files here are synthetic.
/// </summary>
public sealed class ZwiftRideTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private const double WatopiaLatitude = -11.64;
    private const double WatopiaLongitude = 166.95;

    private static byte[] ZwiftRide() => Fit(new FitSession(
        Start,
        600,
        SubSport: SubSport.VirtualActivity,
        ManufacturerId: Manufacturer.Zwift,
        StartLatitude: WatopiaLatitude,
        StartLongitude: WatopiaLongitude));

    [Fact]
    public void FitParser_ShouldReadAVirtualRideFromZwift_WhenTheFileIsAZwiftActivity()
    {
        var ride = Assert.Single(RideFileParser.Parse(ZwiftRide()));

        Assert.Equal("virtual", ride.Environment);
        Assert.Equal("none", ride.Assist);
        Assert.Equal("Zwift", ride.Device);
        Assert.Equal(600, ride.Samples.Count);
        Assert.InRange(ride.Samples[0].Latitude!.Value, WatopiaLatitude - 0.01, WatopiaLatitude + 0.01);
        Assert.InRange(ride.Samples[0].Longitude!.Value, WatopiaLongitude - 0.01, WatopiaLongitude + 0.01);
    }

    [Fact]
    public void FitParser_ShouldReadAVirtualRide_WhenAZwiftFileHasNoVirtualSubSport()
    {
        var file = Fit(new FitSession(
            Start,
            600,
            ManufacturerId: Manufacturer.Zwift,
            StartLatitude: WatopiaLatitude,
            StartLongitude: WatopiaLongitude));

        var ride = Assert.Single(RideFileParser.Parse(file));

        Assert.Equal("virtual", ride.Environment);
    }

    [Fact]
    public async Task UploadRide_ShouldStoreAVirtualRideWithPowerMetricsAndBests_WhenGivenAZwiftFile()
    {
        await using var api = await TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var member = await api.NewMemberClientAsync();

        var uploaded = await TestApi.UploadAndWaitAsync(member, ZwiftRide());

        Assert.Equal("ready", uploaded.Status);
        Assert.Equal("virtual", uploaded.Environment);
        Assert.Equal("Zwift", uploaded.Device);
        Assert.Equal(200, uploaded.AvgPowerW);
        Assert.Equal(200, uploaded.NormalizedPowerW); // steady power: NP equals the average
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var bests = await db.RidePowerBests.AsNoTracking().Where(b => b.RideId == uploaded.Id).ToListAsync(Ct);
        Assert.NotEmpty(bests);
        Assert.All(bests, b => Assert.Equal(200, b.Watts));
    }

    [Fact]
    public async Task UploadRide_ShouldComputeTssAndIntensity_WhenAZwiftRideComesFromAMemberWithFtp()
    {
        await using var api = await TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var email = TestApi.NewEmail();
        var registered = await api.RegisterAsync(email);
        registered.EnsureSuccessStatusCode();
        var member = await api.SignedInClientAsync(email, TestApi.MemberPassword);
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            await db.Users.Where(u => u.Email == email).ExecuteUpdateAsync(s => s.SetProperty(u => u.FtpW, 250), Ct);
        }

        var uploaded = await TestApi.UploadAndWaitAsync(member, ZwiftRide());

        Assert.Equal(0.8, uploaded.IntensityFactor!.Value, 2); // 200 W against an FTP of 250 W
        Assert.InRange(uploaded.Tss!.Value, 10, 11); // 600 s at 0.8 IF: 600 * 0.8 * 0.8 / 36
    }
}
