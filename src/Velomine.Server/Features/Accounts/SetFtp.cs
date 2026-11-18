using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Accounts;

/// <summary>Source is <c>manual</c> when left out: an older app only ever typed the number.</summary>
public sealed record SetFtpRequest(int FtpW, string Source = FtpSources.Manual);

public sealed class SetFtpValidator : Validator<SetFtpRequest>
{
    public SetFtpValidator()
    {
        RuleFor(x => x.FtpW).InclusiveBetween(30, 1000);
        RuleFor(x => x.Source).Must(s => FtpSources.Chosen.Contains(s)).WithMessage("Use manual or estimate.");
    }
}

/// <summary>
/// Sets only the FTP, so a suggested value from the power curve can be adopted without resending the whole profile.
/// TSS already stored on past rides is not recalculated; zones use the new value from now on. Every change is kept
/// in the member's FTP history.
/// </summary>
public sealed class SetFtp(VelomineDbContext db, SetFtpValue setValue, TimeProvider time) : Endpoint<SetFtpRequest, ProfileResponse>
{
    public override void Configure()
    {
        Put("accounts/me/ftp");
        Description(d => d.Accepts<SetFtpRequest>("application/json").Produces<ProfileResponse>(200).ProducesProblem(400).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(SetFtpRequest req, CancellationToken ct)
    {
        var user = await db.Users.FirstAsync(u => u.Id == User.UserId(), ct);
        setValue.Set(user, req.FtpW, req.Source);
        await db.SaveChangesAsync(ct);
        await Send.OkAsync(await GetProfile.ProfileOfAsync(db, user, time, ct), ct);
    }
}
