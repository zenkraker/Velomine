using System.Reflection;
using MailKit.Security;
using MailKit.Net.Smtp;
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Notifications.Email;

namespace Velomine.Server.Tests.Notifications;

public sealed class NotificationKindsTests
{
    [Fact]
    public void NotificationKinds_ShouldMapEveryType_WhenTheTypesAreListed()
    {
        var types = typeof(NotificationTypes)
            .GetFields(BindingFlags.Public | BindingFlags.Static)
            .Where(f => f is { IsLiteral: true, IsInitOnly: false } && f.FieldType == typeof(string))
            .Select(f => (string)f.GetRawConstantValue()!)
            .ToList();

        Assert.NotEmpty(types);
        Assert.All(types, type => Assert.NotNull(NotificationKinds.Of(type)));
    }

    [Fact]
    public void NotificationKinds_ShouldNotEmail_WhenTheTypeIsUnknown()
    {
        Assert.Null(NotificationKinds.Of("not_a_notification"));
    }

    [Fact]
    public void EmailPipelines_ShouldRetryTheSend_WhenTheServerRefusesTemporarily()
    {
        var exception = new SmtpCommandException(SmtpErrorCode.UnexpectedStatusCode, SmtpStatusCode.MailboxBusy, "busy");

        Assert.True(EmailPipelines.IsSafeToRetrySend(exception));
    }

    [Fact]
    public void EmailPipelines_ShouldNotRetryTheSend_WhenTheConnectionDropped()
    {
        Assert.False(EmailPipelines.IsSafeToRetrySend(new SmtpProtocolException("connection lost")));
    }

    [Fact]
    public void EmailPipelines_ShouldNotRetry_WhenAuthenticationFailed()
    {
        Assert.False(EmailPipelines.IsTransient(new AuthenticationException("535 authentication failed")));
    }
}
