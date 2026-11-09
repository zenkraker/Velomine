using FastEndpoints;
using Microsoft.AspNetCore.Identity;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Admin;

public sealed record PasswordResetLinkResponse(string Link, DateTimeOffset ExpiresAt);

/// <summary>
/// Makes a one-time reset link an admin can hand to a member, for a server with no SMTP or a member who cannot receive
/// the email. The link is shown once and is not stored; the server log records that an admin made one.
/// </summary>
public sealed class CreatePasswordResetLink(
    UserManager<User> users,
    PasswordResetLinks links,
    ILogger<CreatePasswordResetLink> logger) : Endpoint<UserIdRequest, PasswordResetLinkResponse>
{
    public override void Configure()
    {
        Post("admin/users/{id}/password-reset-link");
        Roles(Accounts.Roles.Admin);
        Description(d => d.Produces<PasswordResetLinkResponse>(200).Produces(401).Produces(403).Produces(404)
            .ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(UserIdRequest req, CancellationToken ct)
    {
        if (await users.FindByIdAsync(req.Id.ToString()) is not { } user)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (!await users.HasPasswordAsync(user))
        {
            AddError("This account signs in with single sign-on.", "no_password");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        var link = await links.CreateAsync(user);
        logger.LogInformation("Admin {AdminId} made a password reset link for account {UserId}.", User.UserId(), user.Id);
        await Send.OkAsync(new PasswordResetLinkResponse(link, links.ExpiresAt), ct);
    }
}
