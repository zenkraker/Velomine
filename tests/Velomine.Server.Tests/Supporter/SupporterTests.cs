using System.IO.Compression;
using System.Net;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Velomine.Server.Features.Admin;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Supporter;

namespace Velomine.Server.Tests.Supporter;

public sealed class SupporterTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>The issuer's key pair for one test: the public half goes on the server, the private half signs keys.</summary>
    private sealed class Issuer : IDisposable
    {
        private readonly ECDsa key = ECDsa.Create(ECCurve.NamedCurves.nistP256);

        public string PublicKey => Convert.ToBase64String(key.ExportSubjectPublicKeyInfo());

        public string Sign(string type, string holder, int serial)
        {
            // Signed exactly as tools/supporter-key.cs does; the server only ever verifies.
            var payload = JsonSerializer.SerializeToUtf8Bytes(new { t = type, n = holder, s = serial }, LicencePayload.Json);
            var signature = key.SignData(payload, HashAlgorithmName.SHA256, DSASignatureFormat.IeeeP1363FixedFieldConcatenation);
            return Base64Url.Encode(payload) + "." + Base64Url.Encode(signature);
        }

        public void Dispose() => key.Dispose();
    }

    private Task<TestApi> StartAsync(string? publicKey) => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        if (publicKey is not null) b.UseSetting("Velomine:Supporter:PublicKey", publicKey);
    });

    private static Task<HttpResponseMessage> ActivateAsync(HttpClient client, string key) =>
        client.PostAsJsonAsync("/api/v1/supporter/activate", new ActivateSupporterRequest { Key = key }, Ct);

    private static Task<SupporterStatusResponse?> StatusAsync(HttpClient client) =>
        client.GetFromJsonAsync<SupporterStatusResponse>("/api/v1/supporter", Ct);

    [Fact]
    public async Task ActivateSupporter_ShouldMarkTheMember_WhenTheRiderKeyIsValid()
    {
        using var issuer = new Issuer();
        await using var api = await StartAsync(issuer.PublicKey);
        var rider = await api.NewMemberAsync();

        var response = await ActivateAsync(rider.Client, issuer.Sign("rider", "Ada Rossi", 42));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var status = await StatusAsync(rider.Client);
        Assert.True(status!.Available);
        Assert.Equal("Ada Rossi", status.Rider!.Holder);
        Assert.Equal(42, status.Rider.Serial);
        Assert.False(status.Rider.Hidden);
        Assert.Null(status.Club);
    }

    [Fact]
    public async Task ActivateSupporter_ShouldRefuseTheKey_WhenItWasTamperedWith()
    {
        using var issuer = new Issuer();
        await using var api = await StartAsync(issuer.PublicKey);
        var rider = await api.NewMemberAsync();
        var (_, signature) = LicenceKeys.Split(issuer.Sign("rider", "Ada Rossi", 42))!.Value;

        // A different name, carrying the signature of the original payload.
        var forged = JsonSerializer.SerializeToUtf8Bytes(new { t = "rider", n = "Someone Else", s = 42 }, LicencePayload.Json);
        var tampered = Base64Url.Encode(forged) + "." + Base64Url.Encode(signature);

        Assert.Equal(HttpStatusCode.BadRequest, (await ActivateAsync(rider.Client, tampered)).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await ActivateAsync(rider.Client, "not-a-key")).StatusCode);
        Assert.Null((await StatusAsync(rider.Client))!.Rider);
    }

    [Fact]
    public async Task ActivateSupporter_ShouldRefuseTheClubKey_WhenTheCallerIsNotTheOwner()
    {
        using var issuer = new Issuer();
        await using var api = await StartAsync(issuer.PublicKey);
        var owner = await api.NewMemberAsync("Owner");
        var club = await TestClubs.CreateAsync(api, owner.Email, "Test Club");
        var member = await api.NewMemberAsync("Member");

        var joined = await member.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct);
        Assert.Equal(HttpStatusCode.OK, joined.StatusCode);

        var refused = await ActivateAsync(member.Client, issuer.Sign("club", "Test Club", 99));

        Assert.Equal(HttpStatusCode.Forbidden, refused.StatusCode);
        Assert.Null((await StatusAsync(member.Client))!.Club);
    }

    [Fact]
    public async Task SupporterStatus_ShouldNotShowTheClubBadge_WhenTheViewerBelongsToAnotherClub()
    {
        using var issuer = new Issuer();
        await using var api = await StartAsync(issuer.PublicKey);
        var owner = await api.NewMemberAsync("Owner");
        var club = await TestClubs.CreateAsync(api, owner.Email, "Test Club");

        Assert.Equal(HttpStatusCode.OK, (await ActivateAsync(owner.Client, issuer.Sign("club", "Test Club", 7))).StatusCode);
        Assert.Equal("Test Club", (await StatusAsync(owner.Client))!.Club!.Holder);

        // A rider in a different club, and one in none, never see it.
        var elsewhere = await api.NewMemberAsync("Elsewhere");
        await TestClubs.CreateAsync(api, elsewhere.Email, "Another Club");
        Assert.Null((await StatusAsync(elsewhere.Client))!.Club);

        var loner = await api.NewMemberAsync("Loner");
        Assert.Null((await StatusAsync(loner.Client))!.Club);
        Assert.Null((await StatusAsync(loner.Client))!.Rider);
    }

    [Fact]
    public async Task SetSupporterHidden_ShouldHideTheBadge_WhenToggled()
    {
        using var issuer = new Issuer();
        await using var api = await StartAsync(issuer.PublicKey);
        var rider = await api.NewMemberAsync();
        await ActivateAsync(rider.Client, issuer.Sign("rider", "Ada Rossi", 42));

        var hidden = await rider.Client.PutAsJsonAsync("/api/v1/supporter/hidden", new SetSupporterHiddenRequest { Hidden = true }, Ct);

        Assert.Equal(HttpStatusCode.OK, hidden.StatusCode);
        Assert.True((await StatusAsync(rider.Client))!.Rider!.Hidden);

        await rider.Client.PutAsJsonAsync("/api/v1/supporter/hidden", new SetSupporterHiddenRequest { Hidden = false }, Ct);
        Assert.False((await StatusAsync(rider.Client))!.Rider!.Hidden);
    }

    [Fact]
    public async Task ActivateSupporter_ShouldAnswer503_WhenTheOperatorHasNotConfiguredAKey()
    {
        await using var api = await StartAsync(publicKey: null);
        var rider = await api.NewMemberAsync();
        using var issuer = new Issuer();

        var response = await ActivateAsync(rider.Client, issuer.Sign("rider", "Ada Rossi", 42));

        Assert.Equal(HttpStatusCode.ServiceUnavailable, response.StatusCode);
        Assert.False((await StatusAsync(rider.Client))!.Available);
        Assert.Null((await StatusAsync(rider.Client))!.Rider);
    }

    [Fact]
    public async Task ActivateSupporter_ShouldRefuseTheKey_WhenTheSerialIsAlreadyActive()
    {
        using var issuer = new Issuer();
        await using var api = await StartAsync(issuer.PublicKey);
        var first = await api.NewMemberAsync();
        var second = await api.NewMemberAsync();
        var key = issuer.Sign("rider", "Ada Rossi", 42);

        Assert.Equal(HttpStatusCode.OK, (await ActivateAsync(first.Client, key)).StatusCode);
        Assert.Equal(HttpStatusCode.Conflict, (await ActivateAsync(second.Client, key)).StatusCode);
        Assert.Null((await StatusAsync(second.Client))!.Rider);
    }

    [Fact]
    public async Task AccountExport_ShouldHoldMyLicenceAndMyClubs_WhenBothAreActivated()
    {
        using var issuer = new Issuer();
        await using var api = await StartAsync(issuer.PublicKey);
        var owner = await api.NewMemberAsync("Owner");
        var club = await TestClubs.CreateAsync(api, owner.Email, "Test Club");
        Assert.Equal(HttpStatusCode.OK, (await ActivateAsync(owner.Client, issuer.Sign("rider", "Owner", 42))).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await ActivateAsync(owner.Client, issuer.Sign("club", "Test Club", 43))).StatusCode);

        // A rider in a club of their own with its own licence: the export holds neither of the other's.
        var elsewhere = await api.NewMemberAsync("Elsewhere");
        await TestClubs.CreateAsync(api, elsewhere.Email, "Another Club");

        var exported = await ExportAsync(owner.Client);
        var licences = JsonDocument.Parse(Encoding.UTF8.GetString(exported["supporter.json"])).RootElement;

        Assert.Equal(2, licences.GetArrayLength());
        Assert.False(licences[0].GetProperty("isClubLicence").GetBoolean());
        Assert.Equal(42, licences[0].GetProperty("serial").GetInt32());
        Assert.True(licences[1].GetProperty("isClubLicence").GetBoolean());
        Assert.Equal("Test Club", licences[1].GetProperty("clubName").GetString());

        var other = await ExportAsync(elsewhere.Client);
        Assert.Equal(0, JsonDocument.Parse(Encoding.UTF8.GetString(other["supporter.json"])).RootElement.GetArrayLength());
        Assert.DoesNotContain("Test Club", Encoding.UTF8.GetString(other["supporter.json"]));
    }

    private static async Task<Dictionary<string, byte[]>> ExportAsync(HttpClient client)
    {
        var path = (await (await client.PostAsync("/api/v1/accounts/me/export-link", null, Ct))
            .Content.ReadFromJsonAsync<Features.Accounts.ExportLinkResponse>(Ct))!.Path;
        using var response = await client.GetAsync(path, Ct);
        using var zip = new ZipArchive(await response.Content.ReadAsStreamAsync(Ct), ZipArchiveMode.Read);
        var entries = new Dictionary<string, byte[]>();
        foreach (var entry in zip.Entries)
        {
            using var memory = new MemoryStream();
            await entry.Open().CopyToAsync(memory, Ct);
            entries[entry.FullName] = memory.ToArray();
        }

        return entries;
    }

    [Fact]
    public async Task AccountDeletion_ShouldRemoveTheLicence_WhenTheSupporterDeletesTheirAccount()
    {
        using var issuer = new Issuer();
        await using var api = await StartAsync(issuer.PublicKey);
        var rider = await api.NewMemberAsync();
        await ActivateAsync(rider.Client, issuer.Sign("rider", "Ada Rossi", 42));

        var deleted = await rider.Client.PostAsJsonAsync(
            "/api/v1/accounts/me/delete", new Features.Accounts.DeleteMyAccountRequest(TestApi.MemberPassword, null), Ct);

        Assert.Equal(HttpStatusCode.NoContent, deleted.StatusCode);
        var signUpAgain = await api.NewMemberAsync();
        // The serial is free again: the licence row went with the account.
        Assert.Equal(HttpStatusCode.OK, (await ActivateAsync(signUpAgain.Client, issuer.Sign("rider", "Second", 42))).StatusCode);
    }
}
