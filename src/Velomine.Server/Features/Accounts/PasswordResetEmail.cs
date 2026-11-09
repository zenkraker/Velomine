namespace Velomine.Server.Features.Accounts;

/// <summary>The one email a password reset, or an account with no password, sends. Plain text: no tracking, no images.</summary>
public static class PasswordResetEmail
{
    public const string Subject = "Reset your Velomine password";

    public static string Body(string link) =>
        $"""
        Someone asked to reset the password for your Velomine account.

        Open this link to choose a new password:
        {link}

        The link works once and expires in 30 minutes.
        If it was not you, ignore this email; your password stays the same.
        """;

    public const string SsoSubject = "How to sign in to Velomine";

    public static string SsoBody(string provider) =>
        $"""
        This address belongs to a Velomine account that signs in with {provider}.

        Use the single sign-on button on the sign-in page instead of a password.
        """;

    public const string NoPasswordBody =
        """
        This address belongs to a Velomine account that has no password.

        Ask your club admin to help you sign in.
        """;
}
