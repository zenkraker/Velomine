using FastEndpoints;
using FluentValidation;
using Microsoft.AspNetCore.Identity;
using Velomine.Server.Observability;

namespace Velomine.Server.Features.Accounts;

public sealed record SetMyRiderModeRequest(string RiderMode);

public sealed class SetMyRiderModeValidator : Validator<SetMyRiderModeRequest>
{
    public SetMyRiderModeValidator() =>
        RuleFor(x => x.RiderMode)
            .Must(m => m is RiderModes.JustRiding or RiderModes.WithGoals or RiderModes.Training)
            .WithMessage("Use just_riding, with_goals or training.");
}

public static class RiderModes
{
    public const string JustRiding = "just_riding";
    public const string WithGoals = "with_goals";
    public const string Training = "training";
}

/// <summary>
/// Saves how the member rides on this account. It changes only what their own screens show first: nothing is
/// hidden or removed, and no coach, club or share view reads it. Read back on every sign-in, so a choice on the
/// web applies on the phone too.
/// </summary>
public sealed class SetMyRiderMode(UserManager<User> users) : Endpoint<SetMyRiderModeRequest, MeResponse>
{
    public override void Configure()
    {
        Put("accounts/me/rider-mode");
        Description(d => d.Accepts<SetMyRiderModeRequest>("application/json").Produces<MeResponse>(200).ProducesProblem(400).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(SetMyRiderModeRequest req, CancellationToken ct)
    {
        if (await users.GetUserAsync(User) is not { } user)
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        user.RiderMode = req.RiderMode;
        await users.UpdateAsync(user);

        var roles = await users.GetRolesAsync(user);
        await Send.OkAsync(MeResponse.From(user, roles), ct);
    }
}
