using Microsoft.AspNetCore.Identity;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// Checks the password a signed-in member gives as confirmation. It spends the same lockout counter as sign-in, so a
/// stolen cookie cannot be used to guess the password for free.
/// </summary>
public static class PasswordCheck
{
    public enum Result
    {
        Ok,
        Wrong,
        LockedOut,
    }

    public static async Task<Result> RunAsync(SignInManager<User> signIn, User user, string? password)
    {
        if (string.IsNullOrEmpty(password)) return Result.Wrong;

        var check = await signIn.CheckPasswordSignInAsync(user, password, lockoutOnFailure: true);
        if (check.Succeeded) return Result.Ok;
        return check.IsLockedOut ? Result.LockedOut : Result.Wrong;
    }
}
