using Microsoft.Extensions.Options;
using Polly;
using Polly.Retry;
using Velomine.Server.Features.Notifications.Email;

namespace Velomine.Server.Features.Admin;

public static class AdminSetup
{
    public static IServiceCollection AddAdmin(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddSingleton<IValidateOptions<SmtpOptions>, SmtpOptionsValidator>();
        services.AddOptions<SmtpOptions>().BindConfiguration("Velomine:Smtp").ValidateOnStart();
        services.AddScoped<SettingsReader>();
        services.AddResiliencePipeline(EmailPipelines.Connect, builder => builder.AddRetry(new RetryStrategyOptions
        {
            // Connecting and authenticating can be retried safely: no message has been handed over yet.
            ShouldHandle = args => new ValueTask<bool>(EmailPipelines.IsTransient(args.Outcome.Exception)),
            MaxRetryAttempts = 3,
            Delay = TimeSpan.FromSeconds(1),
            BackoffType = DelayBackoffType.Exponential,
            UseJitter = true,
        }));
        services.AddResiliencePipeline(EmailPipelines.Send, builder => builder.AddRetry(new RetryStrategyOptions
        {
            // Only an explicit temporary refusal is safe: a lost connection may already have delivered the message.
            ShouldHandle = args => new ValueTask<bool>(EmailPipelines.IsSafeToRetrySend(args.Outcome.Exception)),
            MaxRetryAttempts = 2,
            Delay = TimeSpan.FromSeconds(1),
            BackoffType = DelayBackoffType.Constant,
        }));
        services.AddSingleton<IEmailSender, MailKitEmailSender>();
        services.AddSingleton<NotificationEmailService>();
        if (configuration.GetValue("Velomine:Background:Enabled", true))
            services.AddHostedService(sp => sp.GetRequiredService<NotificationEmailService>());
        return services;
    }
}
