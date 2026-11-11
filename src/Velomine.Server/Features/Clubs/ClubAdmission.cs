using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Clubs;

public enum AdmissionResult
{
    Admitted,
    ClubNotFound,
    Full,
    PlanEnded,
    AlreadyInClub,
}

/// <summary>
/// The one place a rider becomes a member of a club that already exists (approval and joining with a code). The club
/// row is locked for the length of a short transaction, so two admissions at the same moment are counted one after
/// the other and the club's limit can never be passed by a race.
/// </summary>
public static class ClubAdmission
{
    /// <summary>
    /// Adds the rider as a member if the club has room. <paramref name="stage"/> adds whatever else belongs to the same
    /// change (removing the request, a notification); it is saved together with the membership, or not at all.
    /// </summary>
    public static async Task<AdmissionResult> AdmitAsync(
        VelomineDbContext db,
        TimeProvider time,
        Guid clubId,
        Guid userId,
        Action stage,
        CancellationToken ct)
    {
        await using var transaction = await db.Database.BeginTransactionAsync(ct);

        // Held until the transaction ends: a second admission to the same club waits here, then sees the new count.
        await db.Database.ExecuteSqlAsync($"SELECT 1 FROM clubs.clubs WHERE id = {clubId} FOR UPDATE", ct);

        var plan = await db.Clubs.AsNoTracking()
            .Where(c => c.Id == clubId)
            .Select(c => new { c.MemberLimit, c.PaidUntil, Members = c.Memberships.Count })
            .FirstOrDefaultAsync(ct);
        if (plan is null) return AdmissionResult.ClubNotFound;

        switch (ClubPlan.BlockedReason(plan.MemberLimit, plan.PaidUntil, plan.Members, ClubPlan.Today(time)))
        {
            case ClubPlan.Ended: return AdmissionResult.PlanEnded;
            case ClubPlan.Full: return AdmissionResult.Full;
        }

        db.ClubMemberships.Add(new ClubMembership
        {
            Id = Guid.NewGuid(),
            ClubId = clubId,
            UserId = userId,
            Role = ClubRoles.Member,
            JoinedAt = time.GetUtcNow(),
        });
        stage();

        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException)
        {
            // The unique index on user_id is the final guard when the same rider is admitted twice at once.
            return AdmissionResult.AlreadyInClub;
        }

        await transaction.CommitAsync(ct);
        return AdmissionResult.Admitted;
    }

    /// <summary>The 409 text for a refused admission, or null for the results that are not a refusal.</summary>
    public static string? Refusal(AdmissionResult result) => result switch
    {
        AdmissionResult.Full => "This club is full. It needs a larger plan before it can take more members.",
        AdmissionResult.PlanEnded => "This club's plan has ended. It cannot take new members until the plan is renewed.",
        AdmissionResult.AlreadyInClub => "That person is already in a club.",
        _ => null,
    };
}
