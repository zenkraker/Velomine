using Microsoft.AspNetCore.WebUtilities;

namespace Velomine.Server.Features.Accounts;

public static class SsoReturnUrl
{
    /// <summary>Only a path on this server is allowed, so the sign-in cannot be used as an open redirect.</summary>
    public static string Local(string? url) =>
        url is { Length: > 0 } && url[0] == '/' && !url.StartsWith("//") && !url.StartsWith("/\\") ? url : "/";

    /// <summary>
    /// Where the system browser is sent to hand a sign-in back to the phone app: a private-use scheme named after a domain
    /// we control, reversed, with no host (RFC 8252 section 7.1). The app registers this scheme with the OS.
    /// </summary>
    public const string AppCallback = "com.velomine.app:/sso-callback";

    public static string ForApp(string code) => QueryHelpers.AddQueryString(AppCallback, "code", code);

    public static string ForAppError(string error) => QueryHelpers.AddQueryString(AppCallback, "sso_error", error);

    /// <summary>The page to send the browser back to when sign-in did not work; the client shows the reason.</summary>
    public static string WithError(string returnUrl, string error) => QueryHelpers.AddQueryString(returnUrl, "sso_error", error);
}
