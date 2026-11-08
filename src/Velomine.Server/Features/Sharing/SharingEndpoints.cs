using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Sharing;

namespace Velomine.Server.Features.Sharing;

public sealed record SharingResponse(string Rides, string Analytics, string Routes, string Wellbeing);

public sealed class UpdateSharingRequest
{
    /// <summary>none, coaches or club.</summary>
    public required string Rides { get; set; }

    /// <summary>none, coaches or club.</summary>
    public required string Analytics { get; set; }

    /// <summary>none, coaches or club.</summary>
    public required string Routes { get; set; }

    /// <summary>none, coaches or club.</summary>
    public required string Wellbeing { get; set; }
}

public sealed class UpdateSharingValidator : Validator<UpdateSharingRequest>
{
    private static readonly string[] Choices = ["none", .. Audiences.Assignable];

    public UpdateSharingValidator()
    {
        RuleFor(x => x.Rides).Must(Choices.Contains).WithMessage("Choose none or coaches.");
        RuleFor(x => x.Analytics).Must(Choices.Contains).WithMessage("Choose none or coaches.");
        RuleFor(x => x.Routes)
            .Must(Choices.Contains).WithMessage("Choose none or coaches.")
            .Must((request, routes) => routes == "none" || request.Rides != "none")
            .WithMessage("Share rides before sharing routes.");
        RuleFor(x => x.Wellbeing).Must(Choices.Contains).WithMessage("Choose none or coaches.");
    }
}

/// <summary>The member's sharing choices. Everything starts as none.</summary>
public sealed class GetSharing(VelomineDbContext db) : EndpointWithoutRequest<SharingResponse>
{
    public override void Configure()
    {
        Get("sharing");
        Description(d => d.Produces<SharingResponse>(200).Produces(401).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        if (await db.ClubMemberships.AsNoTracking().FirstOrDefaultAsync(m => m.UserId == User.UserId(), ct) is null)
        {
            AddError("Join a club before sharing anything.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        var grants = await db.ShareGrants.AsNoTracking().Where(g => g.MemberId == User.UserId()).ToListAsync(ct);
        string Choice(string type) => grants.FirstOrDefault(g => g.DataType == type)?.Audience ?? "none";
        await Send.OkAsync(new SharingResponse(
            Choice(DataTypes.Rides),
            Choice(DataTypes.Analytics),
            Choice(DataTypes.Routes),
            Choice(DataTypes.Wellbeing)), ct);
    }
}

/// <summary>Sets each kind of data to nobody, the coaches, or the whole club.</summary>
public sealed class UpdateSharing(VelomineDbContext db, TimeProvider time) : Endpoint<UpdateSharingRequest, SharingResponse>
{
    public override void Configure()
    {
        Put("sharing");
        Description(d => d.Accepts<UpdateSharingRequest>("application/json").Produces<SharingResponse>(200).ProducesProblem(400).Produces(401).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(UpdateSharingRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var membership = await db.ClubMemberships.FirstOrDefaultAsync(m => m.UserId == userId, ct);
        if (membership is null)
        {
            AddError("Join a club before sharing anything.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        var wanted = new Dictionary<string, string>
        {
            [DataTypes.Rides] = req.Rides,
            [DataTypes.Analytics] = req.Analytics,
            [DataTypes.Routes] = req.Routes,
            [DataTypes.Wellbeing] = req.Wellbeing,
        };
        var existing = await db.ShareGrants.Where(g => g.MemberId == userId).ToListAsync(ct);
        foreach (var (type, choice) in wanted)
        {
            var grant = existing.FirstOrDefault(g => g.DataType == type);
            if (choice == "none")
            {
                if (grant is not null) db.ShareGrants.Remove(grant);
                continue;
            }

            if (grant is null)
            {
                db.ShareGrants.Add(new ShareGrant
                {
                    Id = Guid.NewGuid(),
                    MemberId = userId,
                    ClubId = membership.ClubId,
                    DataType = type,
                    Audience = choice,
                    UpdatedAt = time.GetUtcNow(),
                });
            }
            else
            {
                grant.ClubId = membership.ClubId;
                grant.Audience = choice;
                grant.UpdatedAt = time.GetUtcNow();
            }
        }

        await db.SaveChangesAsync(ct);
        await Send.OkAsync(new SharingResponse(req.Rides, req.Analytics, req.Routes, req.Wellbeing), ct);
    }
}
