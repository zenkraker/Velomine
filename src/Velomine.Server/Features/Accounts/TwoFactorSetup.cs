using FastEndpoints;
using FluentValidation;
using Microsoft.AspNetCore.Identity;

namespace Velomine.Server.Features.Accounts;

public sealed record TwoFactorState(bool Enabled, bool HasPassword);

/// <summary>Whether the member has a second factor, and whether they could add one.</summary>
public sealed class GetTwoFactor(UserManager<User> users) : EndpointWithoutRequest<TwoFactorState>
{
    public override void Configure()
    {
        Get("accounts/me/two-factor");
        Description(d => d.Produces<TwoFactorState>(200, "application/json").Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        if (await users.GetUserAsync(User) is not { } user)
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        await Send.OkAsync(new TwoFactorState(user.TwoFactorEnabled, await users.HasPasswordAsync(user)), ct);
    }
}

public sealed record TwoFactorSetup(string Key, string OtpauthUri);

/// <summary>
/// Starts enrolment: returns the authenticator key as text and as an otpauth:// address. No QR code is drawn, so there
/// is no dependency; every authenticator app accepts the key typed by hand.
/// </summary>
public sealed class StartTwoFactorEnrollment(UserManager<User> users) : EndpointWithoutRequest<TwoFactorSetup>
{
    public override void Configure()
    {
        Post("accounts/me/two-factor/start");
        Description(d => d.Produces<TwoFactorSetup>(200, "application/json").Produces(401).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        if (await users.GetUserAsync(User) is not { } user)
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        if (!await users.HasPasswordAsync(user))
        {
            AddError("This account signs in with single sign-on, which is already a second step.", "no_password");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        if (user.TwoFactorEnabled)
        {
            AddError("Two-factor sign-in is already on. Turn it off first to set up a new authenticator.", "already_enabled");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        var key = await users.GetAuthenticatorKeyAsync(user);
        if (string.IsNullOrEmpty(key))
        {
            await users.ResetAuthenticatorKeyAsync(user);
            key = await users.GetAuthenticatorKeyAsync(user);
        }

        if (string.IsNullOrEmpty(key))
        {
            AddError("Could not create the authenticator key. Try again.", "failed");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        const string issuer = "Velomine";
        var account = Uri.EscapeDataString(user.Email!);
        var uri = $"otpauth://totp/{issuer}:{account}?secret={key}&issuer={issuer}&digits=6&period=30";
        await Send.OkAsync(new TwoFactorSetup(key, uri), ct);
    }
}

public sealed record EnableTwoFactorRequest(string Password, string Code);

public sealed record RecoveryCodesResponse(string[] RecoveryCodes);

public sealed class EnableTwoFactorValidator : Validator<EnableTwoFactorRequest>
{
    public EnableTwoFactorValidator()
    {
        RuleFor(x => x.Password).NotEmpty();
        RuleFor(x => x.Code).NotEmpty().MaximumLength(64);
    }
}

/// <summary>
/// Confirms the authenticator and turns the second factor on. The password is the confirmation, so a borrowed session
/// cannot quietly lock the owner out. Other devices are signed out; this one stays.
/// </summary>
public sealed class EnableTwoFactor(
    UserManager<User> users,
    UserSessions sessions) : Endpoint<EnableTwoFactorRequest, RecoveryCodesResponse>
{
    public override void Configure()
    {
        Post("accounts/me/two-factor/enable");
        Options(b => b.RequireRateLimiting("anonymous"));
        Description(
            d => d.Accepts<EnableTwoFactorRequest>("application/json")
                .Produces<RecoveryCodesResponse>(200, "application/json")
                .ProducesProblem(400)
                .Produces(401)
                .ProducesProblem(409)
                .ProducesProblem(429),
            clearDefaults: true);
    }

    public override async Task HandleAsync(EnableTwoFactorRequest req, CancellationToken ct)
    {
        if (await users.GetUserAsync(User) is not { } user)
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        if (!await users.HasPasswordAsync(user) || !await users.CheckPasswordAsync(user, req.Password))
        {
            AddError("The password is not right.", "wrong_password");
            await Send.ErrorsAsync(400, ct);
            return;
        }

        if (!await users.VerifyTwoFactorTokenAsync(user, users.Options.Tokens.AuthenticatorTokenProvider, req.Code))
        {
            AddError("That code did not work. Check the clock on the phone and try the next one.", "invalid_code");
            await Send.ErrorsAsync(400, ct);
            return;
        }

        await users.SetTwoFactorEnabledAsync(user, true);
        var codes = await users.GenerateNewTwoFactorRecoveryCodesAsync(user, 10) ?? [];
        if (User.SessionId() is { } current) await sessions.RevokeOthersAsync(user.Id, current, ct);
        await Send.OkAsync(new RecoveryCodesResponse([.. codes]), ct);
    }
}

public sealed record PasswordConfirmation(string Password);

public sealed class PasswordConfirmationValidator : Validator<PasswordConfirmation>
{
    public PasswordConfirmationValidator() => RuleFor(x => x.Password).NotEmpty();
}

/// <summary>Turns the second factor off. The password is the confirmation; every other device is signed out.</summary>
public sealed class DisableTwoFactor(
    UserManager<User> users,
    UserSessions sessions) : Endpoint<PasswordConfirmation>
{
    public override void Configure()
    {
        Post("accounts/me/two-factor/disable");
        Description(d => d.Accepts<PasswordConfirmation>("application/json").Produces(204).ProducesProblem(400).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(PasswordConfirmation req, CancellationToken ct)
    {
        if (await users.GetUserAsync(User) is not { } user)
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        if (!await users.HasPasswordAsync(user) || !await users.CheckPasswordAsync(user, req.Password))
        {
            AddError("The password is not right.", "wrong_password");
            await Send.ErrorsAsync(400, ct);
            return;
        }

        await users.SetTwoFactorEnabledAsync(user, false);
        await users.ResetAuthenticatorKeyAsync(user);
        if (User.SessionId() is { } current) await sessions.RevokeOthersAsync(user.Id, current, ct);
        await Send.NoContentAsync(ct);
    }
}

/// <summary>Replaces the recovery codes after the password is confirmed. The old ones stop working immediately.</summary>
public sealed class RegenerateRecoveryCodes(
    UserManager<User> users) : Endpoint<PasswordConfirmation, RecoveryCodesResponse>
{
    public override void Configure()
    {
        Post("accounts/me/two-factor/recovery-codes");
        Description(
            d => d.Accepts<PasswordConfirmation>("application/json")
                .Produces<RecoveryCodesResponse>(200, "application/json")
                .ProducesProblem(400)
                .Produces(401)
                .ProducesProblem(409),
            clearDefaults: true);
    }

    public override async Task HandleAsync(PasswordConfirmation req, CancellationToken ct)
    {
        if (await users.GetUserAsync(User) is not { } user)
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        if (!await users.HasPasswordAsync(user) || !await users.CheckPasswordAsync(user, req.Password))
        {
            AddError("The password is not right.", "wrong_password");
            await Send.ErrorsAsync(400, ct);
            return;
        }

        if (!user.TwoFactorEnabled)
        {
            AddError("Two-factor sign-in is not on.", "not_enabled");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        var codes = await users.GenerateNewTwoFactorRecoveryCodesAsync(user, 10) ?? [];
        await Send.OkAsync(new RecoveryCodesResponse([.. codes]), ct);
    }
}
