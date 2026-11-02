using FastEndpoints;
using FluentValidation;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;

namespace Velomine.Server.Features.Accounts;

public sealed record RegisterRequest(string Email, string Password, string DisplayName);

public sealed record RegisterResponse(Guid Id, bool IsApproved);

public sealed class RegisterValidator : Validator<RegisterRequest>
{
    public RegisterValidator()
    {
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(256);
        RuleFor(x => x.DisplayName).NotEmpty().MaximumLength(100);
        RuleFor(x => x.Password).NotEmpty();
    }
}

public sealed class Register(UserManager<User> users, IOptions<AccountsOptions> options, TimeProvider clock)
    : Endpoint<RegisterRequest, RegisterResponse>
{
    public override void Configure()
    {
        Post("accounts/register");
        AllowAnonymous();
        Description(d => d.Accepts<RegisterRequest>("application/json").Produces<RegisterResponse>(201).ProducesProblem(400).Produces(403), clearDefaults: true);
    }

    public override async Task HandleAsync(RegisterRequest req, CancellationToken ct)
    {
        if (!options.Value.SignUpEnabled)
        {
            await Send.ForbiddenAsync(ct);
            return;
        }

        var user = new User
        {
            UserName = req.Email,
            Email = req.Email,
            DisplayName = req.DisplayName,
            IsApproved = !options.Value.RequireAdminApproval,
            CreatedAt = clock.GetUtcNow(),
        };
        var result = await users.CreateAsync(user, req.Password);
        if (!result.Succeeded)
        {
            foreach (var error in result.Errors) AddError(error.Description, error.Code);
            await Send.ErrorsAsync(400, ct);
            return;
        }

        await users.AddToRoleAsync(user, Accounts.Roles.Member);
        await Send.ResponseAsync(new RegisterResponse(user.Id, user.IsApproved), 201, ct);
    }
}
