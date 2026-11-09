namespace Velomine.Server.Features.Clubs;

/// <summary>A rider's ask to join a discoverable club. The owner approves or declines; joining clears it.</summary>
public sealed class ClubJoinRequest
{
    public Guid Id { get; set; }

    public Guid ClubId { get; set; }

    public Club Club { get; set; } = null!;

    public Guid UserId { get; set; }

    public Accounts.User User { get; set; } = null!;

    /// <summary>An optional word from the rider, kept as it was sent.</summary>
    public string? Note { get; set; }

    public DateTimeOffset CreatedAt { get; set; }
}
