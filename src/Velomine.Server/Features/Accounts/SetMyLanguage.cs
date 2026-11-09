using FastEndpoints;
using FluentValidation;
using Microsoft.AspNetCore.Identity;

namespace Velomine.Server.Features.Accounts;

public sealed class SetMyLanguageRequest
{
    /// <summary>A language code such as "en" or "it"; null follows the device.</summary>
    public string? Language { get; set; }
}

public sealed class SetMyLanguageValidator : Validator<SetMyLanguageRequest>
{
    public SetMyLanguageValidator() =>
        RuleFor(x => x.Language)
            .MaximumLength(8)
            .Matches("^[a-z]{2}(-[A-Za-z]{2,8})?$")
            .WithMessage("Use a language code such as en or it.")
            .When(x => !string.IsNullOrWhiteSpace(x.Language));
}

/// <summary>
/// Saves the language chosen on this account. It is read back on every sign-in, so a choice on the web applies
/// on the phone too. Null means "follow the device".
/// </summary>
public sealed class SetMyLanguage(UserManager<User> users) : Endpoint<SetMyLanguageRequest, MeResponse>
{
    public override void Configure()
    {
        Put("accounts/me/language");
        Description(d => d.Accepts<SetMyLanguageRequest>("application/json").Produces<MeResponse>(200).ProducesProblem(400).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(SetMyLanguageRequest req, CancellationToken ct)
    {
        if (await users.GetUserAsync(User) is not { } user)
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        user.Language = string.IsNullOrWhiteSpace(req.Language)
            ? null
            : req.Language.Trim().ToLowerInvariant();
        await users.UpdateAsync(user);

        var roles = await users.GetRolesAsync(user);
        await Send.OkAsync(new MeResponse(user.Id, user.Email!, user.DisplayName, [.. roles], user.Language), ct);
    }
}
