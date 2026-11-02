namespace Velomine.Server.Features.Accounts;

/// <summary>
/// What login and refresh return for a bearer-token sign-in. ASP.NET Core writes this JSON itself, so this type only
/// exists to describe it in the API document.
/// </summary>
public sealed record TokenResponse(string TokenType, string AccessToken, long ExpiresIn, string RefreshToken);
