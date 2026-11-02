namespace Velomine.Server.Features.Accounts;

/// <summary>
/// Bound from "Velomine:Sso" (environment: Velomine__Sso__Authority, ...). Any OpenID Connect provider works.
/// SSO is on when an Authority is set. The provider must allow the redirect URI {server}/signin-oidc.
/// </summary>
public sealed class SsoOptions
{
    /// <summary>The name used for the external login provider and the authentication scheme.</summary>
    public const string Scheme = "oidc";

    public string? Authority { get; set; }

    public string? ClientId { get; set; }

    public string? ClientSecret { get; set; }

    /// <summary>The text for the sign-in button.</summary>
    public string DisplayName { get; set; } = "Single sign-on";

    /// <summary>Create an account for a first-time SSO user. Off: only people who already have an account can sign in.</summary>
    public bool AutoCreateUsers { get; set; } = true;

    /// <summary>Allow an http:// Authority. For local development only.</summary>
    public bool AllowInsecureHttp { get; set; }

    public bool Enabled => !string.IsNullOrWhiteSpace(Authority);
}
