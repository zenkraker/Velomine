namespace Velomine.Server.Features.Accounts;

/// <summary>
/// Bound from "Velomine:Sso" (environment: VELOMINE__SSO__AUTHORITY, ...). Any OpenID Connect provider works.
/// The web uses a confidential client; the phone is a public native client with PKCE and its own redirect URI.
/// </summary>
public sealed class SsoOptions
{
    /// <summary>The name used for the external login provider and the authentication scheme.</summary>
    public const string Scheme = "oidc";

    public string? Authority { get; set; }

    /// <summary>The web client. The server completes the browser redirect.</summary>
    public string? ClientId { get; set; }

    public string? ClientSecret { get; set; }

    /// <summary>The public native client the phone app signs in with. No secret.</summary>
    public string? AppClientId { get; set; }

    /// <summary>Scopes the phone asks the provider for.</summary>
    public string[] AppScopes { get; set; } = ["openid", "profile", "email"];

    /// <summary>The phone's private-use redirect URI, registered on the provider.</summary>
    public string AppRedirectUri { get; set; } = "com.velomine.app:/sso-callback";

    /// <summary>The text for the sign-in button.</summary>
    public string DisplayName { get; set; } = "Single sign-on";

    /// <summary>Create an account for a first-time SSO user. Off: only people who already have an account can sign in.</summary>
    public bool AutoCreateUsers { get; set; } = true;

    /// <summary>Allow an http:// Authority. For local development only.</summary>
    public bool AllowInsecureHttp { get; set; }

    public bool Enabled => !string.IsNullOrWhiteSpace(Authority);

    /// <summary>The web flow needs the confidential client; a direct-only server sets only AppClientId.</summary>
    public bool WebEnabled => Enabled && !string.IsNullOrWhiteSpace(ClientId);

    public bool AppSsoEnabled => Enabled && !string.IsNullOrWhiteSpace(AppClientId);
}
