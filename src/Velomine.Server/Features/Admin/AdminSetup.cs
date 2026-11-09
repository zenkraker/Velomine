using Microsoft.Extensions.Options;
using Velomine.Server.Features.Notifications.Email;

namespace Velomine.Server.Features.Admin;

public static class AdminSetup
{
    public static IServiceCollection AddAdmin(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddSingleton<IValidateOptions<SmtpOptions>, SmtpOptionsValidator>();
        services.AddOptions<SmtpOptions>().BindConfiguration("Velomine:Smtp").ValidateOnStart();
        services.AddScoped<SettingsReader>();
        services.AddSingleton<IEmailSender, MailKitEmailSender>();
        services.AddSingleton<NotificationEmailService>();
        if (configuration.GetValue("Velomine:Background:Enabled", true))
            services.AddHostedService(sp => sp.GetRequiredService<NotificationEmailService>());
        return services;
    }
}
