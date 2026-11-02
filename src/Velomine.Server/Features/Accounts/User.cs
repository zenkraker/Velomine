using Microsoft.AspNetCore.Identity;

namespace Velomine.Server.Features.Accounts;

public sealed class User : IdentityUser<Guid>
{
    public string DisplayName { get; set; } = "";

    /// <summary>False until an admin approves the account, when the server requires approval.</summary>
    public bool IsApproved { get; set; }

    public DateTimeOffset CreatedAt { get; set; }
}

public static class Roles
{
    public const string Admin = "admin";
    public const string Member = "member";
    public const string Coach = "coach";

    public static readonly string[] All = [Admin, Member, Coach];
}
