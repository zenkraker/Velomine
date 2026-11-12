using FastEndpoints;
using FluentValidation;
using Microsoft.AspNetCore.Identity;
using Velomine.Server.Observability;

namespace Velomine.Server.Features.Accounts;

public sealed record SetMyUnitsRequest(string Units);

public sealed class SetMyUnitsValidator : Validator<SetMyUnitsRequest>
{
    public SetMyUnitsValidator() =>
        RuleFor(x => x.Units)
            .Must(u => u is "metric" or "imperial")
            .WithMessage("Use metric or imperial.");
}

/// <summary>
/// Saves the units chosen on this account. They change only what the member reads: every value stays metric in the
/// database. Read back on every sign-in, so a choice on the web applies on the phone too.
/// </summary>
public sealed class SetMyUnits(UserManager<User> users) : Endpoint<SetMyUnitsRequest, MeResponse>
{
    public override void Configure()
    {
        Put("accounts/me/units");
        Description(d => d.Accepts<SetMyUnitsRequest>("application/json").Produces<MeResponse>(200).ProducesProblem(400).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(SetMyUnitsRequest req, CancellationToken ct)
    {
        if (await users.GetUserAsync(User) is not { } user)
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        user.Units = req.Units;
        await users.UpdateAsync(user);

        var roles = await users.GetRolesAsync(user);
        await Send.OkAsync(MeResponse.From(user, roles), ct);
    }
}
