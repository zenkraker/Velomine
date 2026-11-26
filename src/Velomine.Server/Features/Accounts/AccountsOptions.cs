namespace Velomine.Server.Features.Accounts;

/// <summary>Bound from "Velomine:Accounts" (environment: VELOMINE__ACCOUNTS__SIGNUPENABLED, ...).</summary>
public sealed class AccountsOptions
{
    public bool SignUpEnabled { get; set; } = true;

    /// <summary>
    /// The hosted service (VELOMINE__ACCOUNTS__CLOUD). On: sign-up is confirmed by the registrant's own email link and
    /// never waits for an admin. Off (self-hosted): no verification email is sent, and the admins are told of a new
    /// account when approval is required.
    /// </summary>
    public bool Cloud { get; set; }

    /// <summary>New accounts wait for an admin to approve them. Off: a rider signs up and starts the solo trial at once.</summary>
    public bool RequireAdminApproval { get; set; }

    /// <summary>Riders without a club may start one. Off: only the operator creates clubs (VELOMINE__ACCOUNTS__CLUBCREATIONENABLED).</summary>
    public bool ClubCreationEnabled { get; set; }
}

/// <summary>Bound from "Velomine:Admin". Creates the first admin when the server has none.</summary>
public sealed class AdminBootstrapOptions
{
    public string? Email { get; set; }

    public string? Password { get; set; }
}
