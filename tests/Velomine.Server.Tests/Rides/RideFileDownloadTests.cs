using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Rides;

/// <summary>
/// A ride's file going back out: as received, and as a FIT file the server writes for a ride read from GPX or TCX.
/// The link is the sign-in, so the download is anonymous and the ride's owner is checked when it is made.
/// </summary>
public sealed class RideFileDownloadTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync(TimeProvider? time = null) =>
        TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
            if (time is not null) b.ConfigureTestServices(s => s.AddSingleton(time));
        });

    /// <summary>A clock a test can move, so a two-minute link can be waited out without the test waiting.</summary>
    private sealed class MovableTime(DateTimeOffset now) : TimeProvider
    {
        public DateTimeOffset Now { get; set; } = now;

        public override DateTimeOffset GetUtcNow() => Now;
    }

    private static async Task<RideFileLinkResponse> LinkAsync(
        HttpClient client, Guid rideId, string format = RideFileFormats.Original)
    {
        var response = await client.PostAsJsonAsync(
            $"/api/v1/rides/{rideId}/file-link",
            new CreateRideFileLinkRequest { Id = rideId, Format = format },
            Ct);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<RideFileLinkResponse>(Ct))!;
    }

    /// <summary>Just the token out of a download address, for a test that points it at another ride.</summary>
    private static string TokenOf(string path) => new Uri("http://localhost" + path).Segments[^1];

    private static async Task<(byte[] Bytes, string? FileName)> DownloadAsync(TestApi api, string path)
    {
        var response = await api.CreateClient().GetAsync(path, Ct);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadAsByteArrayAsync(Ct), response.Content.Headers.ContentDisposition?.FileName?.Trim('"'));
    }

    [Fact]
    public async Task DownloadRideFile_ShouldReturnTheOriginalAsReceived_WhenFormatIsOriginal()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        var gpx = Bytes(Gpx(30));
        var ride = await TestApi.UploadAndWaitAsync(member.Client, gpx, "morning.gpx");

        var link = await LinkAsync(member.Client, ride.Id);
        var (downloaded, fileName) = await DownloadAsync(api, link.Path);

        Assert.Equal(gpx, downloaded);
        Assert.Equal("morning.gpx", fileName);
    }

    [Fact]
    public async Task DownloadRideFile_ShouldWriteAFitThatReadsBack_WhenTheRideCameFromGpx()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        var ride = await TestApi.UploadAndWaitAsync(
            member.Client,
            Bytes(Gpx(60, i => "<gpxtpx:TrackPointExtension><gpxtpx:hr>150</gpxtpx:hr></gpxtpx:TrackPointExtension>")),
            "morning.gpx");

        var link = await LinkAsync(member.Client, ride.Id, RideFileFormats.Fit);
        var (downloaded, fileName) = await DownloadAsync(api, link.Path);

        Assert.Equal("morning.fit", fileName);
        // The server's own reader takes the file back: same ride, same samples, same start, the same ground covered.
        var parsed = Assert.Single(RideFileParser.Parse(downloaded));
        Assert.Equal(ride.StartTime, parsed.StartTime);
        Assert.Equal(60, parsed.Samples.Count);
        Assert.All(parsed.Samples, sample => Assert.Equal((short?)150, sample.HeartRate));
        Assert.All(parsed.Samples, sample => Assert.NotNull(sample.Altitude));
        var distance = (double)(parsed.Samples[^1].Distance ?? 0);
        Assert.InRange(distance, ride.DistanceM!.Value * 0.99, ride.DistanceM.Value * 1.01);
    }

    [Fact]
    public async Task DownloadRideFile_ShouldReturnTheOriginalFit_WhenTheRideIsAlreadyFit()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        var fit = Fit(new FitSession(Start, 60));
        var ride = await TestApi.UploadAndWaitAsync(member.Client, fit, "ride.fit");

        var link = await LinkAsync(member.Client, ride.Id, RideFileFormats.Fit);
        var (downloaded, fileName) = await DownloadAsync(api, link.Path);

        Assert.Equal(fit, downloaded);
        Assert.Equal("ride.fit", fileName);
    }

    [Fact]
    public void RideFitWriter_ShouldLeaveOutEstimatedPower_WhenTheRideHasNoPowerMeter()
    {
        var start = new DateTimeOffset(2026, 10, 3, 8, 0, 0, TimeSpan.Zero);
        var ride = new Ride { Id = Guid.NewGuid(), Status = RideStatus.Ready, StartTime = start };
        var streams = new RideStreams
        {
            Time = [0, 1, 2],
            EstimatedPower = [200, 210, 220],
        };

        var parsed = Assert.Single(RideFileParser.Parse(RideFitWriter.Write(ride, streams)));

        Assert.Equal(3, parsed.Samples.Count);
        Assert.All(parsed.Samples, sample => Assert.Null(sample.Power));
    }

    [Fact]
    public async Task CreateRideFileLink_ShouldAnswer404_WhenTheRideBelongsToSomeoneElse()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync("Ada");
        var other = await api.NewMemberAsync("Grace");
        var ride = await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(Start, 60)));

        var response = await other.Client.PostAsJsonAsync(
            $"/api/v1/rides/{ride.Id}/file-link",
            new CreateRideFileLinkRequest { Id = ride.Id },
            Ct);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task DownloadRideFile_ShouldAnswer404_WhenTheTokenIsAnotherMembers()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync("Ada");
        var other = await api.NewMemberAsync("Grace");
        var mine = await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(Start, 60)), "ada.fit");
        var theirs = await TestApi.UploadAndWaitAsync(other.Client, Fit(new FitSession(Start.AddHours(6), 60)), "grace.fit");

        // Ada's link, pointed at Grace's ride.
        var link = await LinkAsync(member.Client, mine.Id);
        var token = TokenOf(link.Path);
        var response = await api.CreateClient().GetAsync($"/api/v1/rides/{theirs.Id}/file/{token}", Ct);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task DownloadRideFile_ShouldAnswer401_WhenTheTokenHasExpired()
    {
        var clock = new MovableTime(new DateTimeOffset(2026, 11, 1, 8, 0, 0, TimeSpan.Zero));
        await using var api = await StartAsync(clock);
        var member = await api.NewMemberAsync();
        var ride = await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(Start, 60)));
        var link = await LinkAsync(member.Client, ride.Id);

        clock.Now = clock.Now.AddMinutes(3);
        var response = await api.CreateClient().GetAsync(link.Path, Ct);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task CreateRideFileLink_ShouldAnswer400_WhenTheFormatIsUnknown()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        var ride = await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(Start, 60)));

        var response = await member.Client.PostAsJsonAsync(
            $"/api/v1/rides/{ride.Id}/file-link",
            new CreateRideFileLinkRequest { Id = ride.Id, Format = "gpx" },
            Ct);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
