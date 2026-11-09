namespace Velomine.Server.Features.Accounts;

/// <summary>Bound from "Velomine:PublicUrl". The address members reach this club at, used in password reset links.</summary>
public sealed class PublicUrlOptions
{
    public string PublicUrl { get; set; } = "http://localhost:8080";
}
