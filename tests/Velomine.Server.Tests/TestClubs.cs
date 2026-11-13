using System.Net.Http.Json;
using Velomine.Server.Features.Clubs;

namespace Velomine.Server.Tests;

/// <summary>Clubs made the only way production makes them: by an admin, with an owner.</summary>
public static class TestClubs
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>Creates a club owned by <paramref name="ownerEmail"/> and signed in as the admin.</summary>
    public static async Task<AdminClubResponse> CreateAsync(TestApi api, string ownerEmail, string? name = null)
    {
        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        var response = await admin.PostAsJsonAsync(
            "/api/v1/admin/clubs",
            new CreateClubRequest { Name = name ?? $"Club {Guid.NewGuid():N}", OwnerEmail = ownerEmail },
            Ct);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<AdminClubResponse>(Ct))!;
    }

    public static Task<AdminClubResponse> CreateAsync(TestApi api, TestMember owner, string? name = null) =>
        CreateAsync(api, owner.Email, name);

    /// <summary>Puts the member in the club with its join code.</summary>
    public static async Task JoinAsync(TestMember member, AdminClubResponse club) =>
        (await member.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct))
            .EnsureSuccessStatusCode();
}
