namespace Velomine.Server.Features.Clubs;

/// <summary>
/// A club's plan: how many members it has room for and until when that is paid for. The server knows no prices; the
/// operator sets both values by hand (a bank transfer today), and a payment provider can later set the same two.
/// A plan never takes anything away: an ended or full plan only stops new members from being admitted.
/// </summary>
public static class ClubPlan
{
    /// <summary>The size bands. More than 150 is "no limit" (null).</summary>
    public static readonly int[] Limits = [25, 75, 150];

    /// <summary>A club a rider starts herself begins on the smallest band, with this many free days.</summary>
    public const int TrialDays = 30;

    public const string Full = "full";
    public const string Ended = "ended";

    public static DateOnly Today(TimeProvider time) => DateOnly.FromDateTime(time.GetUtcNow().UtcDateTime);

    /// <summary>
    /// Why the club cannot admit another member now: <see cref="Ended"/> when the paid-until day has passed, <see cref="Full"/>
    /// when it has as many members as its limit, otherwise null. An ended plan wins, because renewing is the first step.
    /// </summary>
    public static string? BlockedReason(int? memberLimit, DateOnly? paidUntil, int memberCount, DateOnly today) =>
        paidUntil is { } until && today > until ? Ended
        : memberLimit is { } limit && memberCount >= limit ? Full
        : null;
}
