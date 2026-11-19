using System.IO.Compression;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Npgsql;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Tests;

/// <summary>Every FTP a member has had is kept, with when it was set and how, and nobody else can read it.</summary>
public sealed class FtpHistoryTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    // Close to the real clock: a data-protection token's own expiry uses the system clock, so a clock far in the past
    // would make the export link look expired the moment it was made.
    private static readonly DateTimeOffset Now = DateTimeOffset.UtcNow;

    /// <summary>A server whose clock keeps moving, so a second write is later than the first and the export link works.</summary>
    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new OffsetTime(Now)));
    });

    private static Task<HttpResponseMessage> SetFtpAsync(HttpClient client, int watts, string? source = null) =>
        client.PutAsJsonAsync(
            "/api/v1/accounts/me/ftp",
            source is null ? new SetFtpRequest(watts) : new SetFtpRequest(watts, source),
            Ct);

    private static async Task<HttpResponseMessage> UpdateProfileAsync(HttpClient client, int? ftpW) =>
        await client.PutAsJsonAsync(
            "/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Test Rider", ftpW, null, null, null, "monday"),
            Ct);

    private static async Task<FtpHistoryResponse> HistoryAsync(HttpClient client) =>
        (await client.GetFromJsonAsync<FtpHistoryResponse>("/api/v1/accounts/me/ftp-history", Ct))!;

    [Fact]
    public async Task SetFtp_ShouldWriteHistory_WhenTheValueChanges()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        Assert.Equal(HttpStatusCode.OK, (await SetFtpAsync(member.Client, 250)).StatusCode);

        var entry = Assert.Single((await HistoryAsync(member.Client)).Entries);
        Assert.Equal(250, entry.Watts);
        Assert.Equal(FtpSources.Manual, entry.Source);
        Assert.Null(entry.RideId);
        Assert.Equal(Now, entry.SetAt, TimeSpan.FromMinutes(1));

        await SetFtpAsync(member.Client, 260);
        var entries = (await HistoryAsync(member.Client)).Entries;
        Assert.Equal(new[] { 260, 250 }, entries.Select(e => e.Watts)); // newest first
    }

    [Fact]
    public async Task SetFtp_ShouldNotWriteHistory_WhenTheValueIsTheSame()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        await SetFtpAsync(member.Client, 250);
        Assert.Equal(HttpStatusCode.OK, (await SetFtpAsync(member.Client, 250)).StatusCode);

        Assert.Single((await HistoryAsync(member.Client)).Entries);
    }

    [Fact]
    public async Task SetFtp_ShouldRecordEstimate_WhenTheSourceIsEstimate()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        await SetFtpAsync(member.Client, 285, FtpSources.Estimate);

        var entry = Assert.Single((await HistoryAsync(member.Client)).Entries);
        Assert.Equal(285, entry.Watts);
        Assert.Equal(FtpSources.Estimate, entry.Source);
    }

    [Fact]
    public async Task SetFtp_ShouldRefuse_WhenTheSourceIsTest()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        // A test FTP comes only from accepting a ride's suggestion, never from this endpoint.
        Assert.Equal(HttpStatusCode.BadRequest, (await SetFtpAsync(member.Client, 250, FtpSources.Test)).StatusCode);
        Assert.Empty((await HistoryAsync(member.Client)).Entries);
        var profile = await member.Client.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct);
        Assert.Null(profile!.FtpW);
    }

    [Fact]
    public async Task UpdateProfile_ShouldWriteHistory_WhenFtpChanges()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        Assert.Equal(HttpStatusCode.OK, (await UpdateProfileAsync(member.Client, 265)).StatusCode);
        await UpdateProfileAsync(member.Client, 265); // the same number again writes nothing

        var entry = Assert.Single((await HistoryAsync(member.Client)).Entries);
        Assert.Equal(265, entry.Watts);
        Assert.Equal(FtpSources.Manual, entry.Source);
    }

    [Fact]
    public async Task Profile_ShouldSayWhenAndHowFtpWasSet_WhenItHasHistory()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        var none = await member.Client.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct);
        Assert.Null(none!.FtpSetAt);
        Assert.Null(none.FtpSource);

        await SetFtpAsync(member.Client, 250, FtpSources.Estimate);

        var profile = await member.Client.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct);
        Assert.Equal(250, profile!.FtpW);
        Assert.Equal(Now, profile.FtpSetAt!.Value, TimeSpan.FromMinutes(1));
        Assert.Equal(FtpSources.Estimate, profile.FtpSource);
    }

    [Fact]
    public async Task FtpHistory_ShouldNotBeVisible_WhenAnotherMemberAsks()
    {
        await using var api = await StartAsync();
        var me = await api.NewMemberAsync("Ada");
        var other = await api.NewMemberAsync("Grace");
        await SetFtpAsync(me.Client, 250);

        // The list is the caller's own, whoever else has one.
        Assert.Empty((await HistoryAsync(other.Client)).Entries);
        Assert.Equal(250, Assert.Single((await HistoryAsync(me.Client)).Entries).Watts);
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.CreateClient().GetAsync("/api/v1/accounts/me/ftp-history", Ct)).StatusCode);
    }

    [Fact]
    public async Task AccountExport_ShouldContainFtpHistory_WhenTheMemberHasIt()
    {
        await using var api = await StartAsync();
        var me = await api.NewMemberAsync("Ada");
        var other = await api.NewMemberAsync("Grace");
        await SetFtpAsync(me.Client, 250);
        await SetFtpAsync(me.Client, 260);
        await SetFtpAsync(other.Client, 300);

        var requested = await me.Client.PostAsync("/api/v1/accounts/me/export-link", null, Ct);
        Assert.Equal(HttpStatusCode.OK, requested.StatusCode);
        var link = (await requested.Content.ReadFromJsonAsync<ExportLinkResponse>(Ct))!.Path;
        var download = await api.CreateClient().GetAsync(link, Ct);
        download.EnsureSuccessStatusCode();

        using var zip = new ZipArchive(await download.Content.ReadAsStreamAsync(Ct), ZipArchiveMode.Read);
        var entry = zip.GetEntry("ftp-history.json");
        Assert.NotNull(entry);
        using var stream = entry.Open();
        using var document = await JsonDocument.ParseAsync(stream, cancellationToken: Ct);
        var rows = document.RootElement.EnumerateArray().ToList();
        Assert.Equal(new[] { 250, 260 }, rows.Select(r => r.GetProperty("watts").GetInt32())); // oldest first
        Assert.All(rows, r => Assert.Equal("manual", r.GetProperty("source").GetString()));
        Assert.DoesNotContain(rows, r => r.GetProperty("watts").GetInt32() == 300);
    }

    [Fact]
    public async Task AccountDeletion_ShouldRemoveFtpHistory_WhenTheAccountIsDeleted()
    {
        await using var api = await StartAsync();
        var me = await api.NewMemberAsync();
        await SetFtpAsync(me.Client, 250);

        var deleted = await me.Client.PostAsJsonAsync(
            "/api/v1/accounts/me/delete", new DeleteMyAccountRequest(TestApi.MemberPassword, null), Ct);

        Assert.Equal(HttpStatusCode.NoContent, deleted.StatusCode);
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.False(await db.FtpHistory.AnyAsync(h => h.UserId == me.Id, Ct));
    }

    [Fact]
    public async Task FtpHistoryMigration_ShouldBackfillOneEarlierRow_WhenTheMemberAlreadyHasAnFtp()
    {
        var connection = await postgres.CreateDatabaseAsync();
        static VelomineDbContext Db(string connection) =>
            new(new DbContextOptionsBuilder<VelomineDbContext>().UseNpgsql(connection).Options);

        // The database as it was before this migration: one member with an FTP, one without.
        const string insert = """
            INSERT INTO accounts.users (id, display_name, user_name, is_approved, email_confirmed,
                phone_number_confirmed, two_factor_enabled, lockout_enabled, access_failed_count, created_at, ftp_w)
            VALUES (gen_random_uuid(), {0}, {1}, true, true, false, false, true, 0, now(), NULLIF({2}, '')::integer)
            """;
        await using (var before = Db(connection))
        {
            await before.Database.MigrateAsync("20261113121516_RidePrivacySnapshot", Ct);
            await before.Database.ExecuteSqlRawAsync(insert, ["Ada", "ada@test.local", "250"], Ct);
            await before.Database.ExecuteSqlRawAsync(insert, ["Grace", "grace@test.local", ""], Ct);
        }

        NpgsqlConnection.ClearAllPools();
        await using (var after = Db(connection))
        {
            await after.Database.MigrateAsync(Ct);
            var rows = await after.FtpHistory.AsNoTracking().ToListAsync(Ct);

            var row = Assert.Single(rows);
            Assert.Equal(250, row.Watts);
            Assert.Equal(FtpSources.Earlier, row.Source);
            Assert.Null(row.RideId);
            Assert.True(row.SetAt > DateTimeOffset.UtcNow.AddDays(-1)); // the migration's own time, not an invented date
        }

        await postgres.DropDatabaseAsync(connection);
    }
}
