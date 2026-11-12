using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Clubs;

namespace Velomine.Server.Features.Supporter;

public sealed class ActivateSupporterRequest
{
    /// <summary>The licence key exactly as the issuer handed it out.</summary>
    public required string Key { get; set; }
}

public sealed class ActivateSupporterValidator : Validator<ActivateSupporterRequest>
{
    public ActivateSupporterValidator() => RuleFor(x => x.Key).NotEmpty().MaximumLength(4000);
}

/// <summary>
/// Activates a paid supporter licence with its offline signed key. A rider key marks this account; a club key marks the
/// caller's club and only its owner may activate it. No feature is unlocked, so a server without one works the same.
/// </summary>
public sealed class ActivateSupporter(VelomineDbContext db, IOptions<SupporterOptions> options, TimeProvider time)
    : Endpoint<ActivateSupporterRequest, SupporterStatusResponse>
{
    public override void Configure()
    {
        Post("supporter/activate");
        Description(d => d
            .Accepts<ActivateSupporterRequest>("application/json")
            .Produces<SupporterStatusResponse>(200)
            .ProducesProblem(400)
            .Produces(401)
            .ProducesProblem(403)
            .ProducesProblem(409)
            .ProducesProblem(503), clearDefaults: true);
    }

    public override async Task HandleAsync(ActivateSupporterRequest req, CancellationToken ct)
    {
        var publicKey = options.Value.DecodedPublicKey;
        if (publicKey is null)
        {
            AddError("Supporter licences are not available on this server.");
            await Send.ErrorsAsync(503, ct);
            return;
        }

        if (LicenceKeys.Verify(req.Key, publicKey) is not { } licence)
        {
            AddError("That licence key is not valid. Check that you copied all of it.");
            await Send.ErrorsAsync(400, ct);
            return;
        }

        var userId = User.UserId();
        Guid? clubId = null;
        var clubName = "";
        if (licence.Type == LicenceKinds.Club)
        {
            var membership = await db.ClubMemberships.AsNoTracking().Include(m => m.Club)
                .FirstOrDefaultAsync(m => m.UserId == userId, ct);
            if (membership is null || membership.Role != ClubRoles.Owner)
            {
                AddError("Only the owner of the club can activate a club licence.");
                await Send.ErrorsAsync(403, ct);
                return;
            }

            clubId = membership.ClubId;
            clubName = membership.Club.Name;
        }

        if (await db.SupporterLicences.AnyAsync(l => l.Serial == licence.Serial, ct))
        {
            AddError("This licence key has already been activated.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        // One licence per holder: the club keeps its paid licence when the activating owner changes.
        var held = await db.SupporterLicences.AsNoTracking()
            .Where(l => clubId != null ? l.ClubId == clubId : l.UserId == userId)
            .Select(l => new { l.ActivatedAt })
            .FirstOrDefaultAsync(ct);
        if (held is not null)
        {
            AddError(clubId is null
                ? "You already have a supporter licence."
                : $"The club {clubName} already has a supporter licence, activated on {held.ActivatedAt:yyyy-MM-dd}.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        db.SupporterLicences.Add(new Licence
        {
            Id = Guid.NewGuid(),
            UserId = clubId is null ? userId : null,
            ClubId = clubId,
            Holder = licence.Holder.Trim(),
            Serial = licence.Serial,
            ActivatedAt = time.GetUtcNow(),
        });

        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException)
        {
            // The unique indexes are the final guard: the same serial twice, or two licences for one holder at once.
            AddError("This licence key has already been activated, or you already hold one.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        await Send.OkAsync(await SupporterQueries.StatusAsync(db, true, userId, ct), ct);
    }
}
