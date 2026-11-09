using FastEndpoints;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Notifications.Email;

namespace Velomine.Server.Features.Admin;

/// <summary>Sends a test email to the signed-in admin's own address, to check the SMTP settings from the environment.</summary>
public sealed class SendTestEmail(IEmailSender sender, IOptions<SmtpOptions> smtp, UserManager<User> users, ILogger<SendTestEmail> logger)
    : EndpointWithoutRequest
{
    public override void Configure()
    {
        Post("admin/settings/test-email");
        Roles(Accounts.Roles.Admin);
        Description(d => d.Produces(204).Produces(401).Produces(403).ProducesProblem(409).ProducesProblem(502), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        if (!smtp.Value.Configured)
        {
            AddError("Email is not set up. Set VELOMINE__SMTP__HOST and VELOMINE__SMTP__FROM and restart the server.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        var admin = await users.GetUserAsync(User);
        try
        {
            await sender.SendAsync(admin!.Email!, "Velomine: test email", "If you can read this, Velomine can send email.\n", ct);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            // What the mail server answered helps the admin; the settings themselves, and the password, are never in it.
            logger.LogWarning("The test email could not be sent ({Exception}).", ex.GetType().Name);
            AddError("The mail server did not accept it: " + ex.Message);
            await Send.ErrorsAsync(502, ct);
            return;
        }

        await Send.NoContentAsync(ct);
    }
}
