using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// One signed-in device: a browser or the app. The row is what the member sees in the session list and what a revoked
/// session is checked against when it renews. Nothing about the network is stored.
/// </summary>
public sealed class UserSession
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public User User { get; set; } = null!;

    /// <summary>What the member reads in the list: "Android app", "Web - Chrome".</summary>
    public string Label { get; set; } = "";

    public DateTimeOffset CreatedAt { get; set; }

    public DateTimeOffset LastUsedAt { get; set; }

    /// <summary>
    /// The refresh token generation this session currently accepts. A refresh rotates it; a token carrying an older
    /// generation was already spent, so it is treated as stolen and the session is revoked.
    /// </summary>
    public int Generation { get; set; }

    public DateTimeOffset? RevokedAt { get; set; }

    public DateTimeOffset ExpiresAt { get; set; }
}

public sealed class UserSessionConfiguration : IEntityTypeConfiguration<UserSession>
{
    public void Configure(EntityTypeBuilder<UserSession> b)
    {
        b.ToTable("user_sessions");
        b.HasKey(s => s.Id);
        b.Property(s => s.Label).HasMaxLength(60);
        b.HasIndex(s => new { s.UserId, s.LastUsedAt });
        b.HasOne(s => s.User).WithMany().HasForeignKey(s => s.UserId).OnDelete(DeleteBehavior.Cascade);
    }
}
