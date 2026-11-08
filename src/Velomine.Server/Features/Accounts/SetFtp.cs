using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Accounts;

public sealed record SetFtpRequest(int FtpW);

public sealed class SetFtpValidator : Validator<SetFtpRequest>
{
    public SetFtpValidator() => RuleFor(x => x.FtpW).InclusiveBetween(30, 1000);
}

/// <summary>
/// Sets only the FTP, so a suggested value from the power curve can be adopted without resending the whole profile.
/// TSS already stored on past rides is not recalculated; zones use the new value from now on.
/// </summary>
public sealed class SetFtp(VelomineDbContext db) : Endpoint<SetFtpRequest, ProfileResponse>
{
    public override void Configure()
    {
        Put("accounts/me/ftp");
        Description(d => d.Accepts<SetFtpRequest>("application/json").Produces<ProfileResponse>(200).ProducesProblem(400).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(SetFtpRequest req, CancellationToken ct)
    {
        var user = await db.Users.FirstAsync(u => u.Id == User.UserId(), ct);
        user.FtpW = req.FtpW;
        await db.SaveChangesAsync(ct);
        await Send.OkAsync(GetProfile.ProfileOf(user), ct);
    }
}
