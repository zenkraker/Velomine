namespace Velomine.Server.Features.Accounts;

/// <summary>Bound from "Velomine:Accounts" (environment: VELOMINE__ACCOUNTS__SIGNUPENABLED, ...).</summary>
public sealed class AccountsOptions
{
    public bool SignUpEnabled { get; set; } = true;

    /// <summary>New accounts wait for an admin to approve them.</summary>
    public bool RequireAdminApproval { get; set; } = true;

    /// <summary>Riders without a club may start one. Off: only the operator creates clubs (VELOMINE__ACCOUNTS__CLUBCREATIONENABLED).</summary>
    public bool ClubCreationEnabled { get; set; }
}

/// <summary>Bound from "Velomine:Admin". Creates the first admin when the server has none.</summary>
public sealed class AdminBootstrapOptions
{
    public string? Email { get; set; }

    public string? Password { get; set; }
}
