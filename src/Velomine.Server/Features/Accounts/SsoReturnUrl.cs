using Microsoft.AspNetCore.WebUtilities;

namespace Velomine.Server.Features.Accounts;

public static class SsoReturnUrl
{
    /// <summary>Only a path on this server is allowed, so the sign-in cannot be used as an open redirect.</summary>
    public static string Local(string? url) =>
        url is { Length: > 0 } && url[0] == '/' && !url.StartsWith("//") && !url.StartsWith("/\\") ? url : "/";

    /// <summary>The page to send the browser back to when sign-in did not work; the client shows the reason.</summary>
    public static string WithError(string returnUrl, string error) => QueryHelpers.AddQueryString(returnUrl, "sso_error", error);
}
