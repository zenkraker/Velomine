using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Notifications.Email;

namespace Velomine.Server.Tests;

/// <summary>Checks the wording itself, without a server or a database.</summary>
public sealed class EmailTextTests
{
    [Theory]
    [InlineData("en", "Reset your Velomine password", "Your ride morning.fit is ready.")]
    [InlineData("it", "Reimposta la password di Velomine", "La tua uscita morning.fit è pronta.")]
    public void EmailText_ShouldUseTheMemberLanguage_WhenItIsSupported(string language, string resetSubject, string sentence)
    {
        using var _ = EmailLanguage.Use(language);

        var reset = PasswordResetEmail.Reset("https://club.example/reset-password#email=a&token=b");
        var notification = NotificationText.Write(
            [new Notification { Type = NotificationTypes.RideReady, Subject = "morning.fit" }]);

        Assert.Equal(resetSubject, reset.Subject);
        Assert.Contains(sentence, notification.Subject);
        Assert.Contains(sentence, notification.Text);
    }

    [Fact]
    public void EmailText_ShouldNotLeakResourceKeys_WhenRenderedInEveryLanguage()
    {
        foreach (var language in new[] { "en", "it" })
        {
            using var _ = EmailLanguage.Use(language);

            var reset = PasswordResetEmail.Reset("https://club.example/reset-password#email=a&token=b");
            var sso = PasswordResetEmail.Sso("Example SSO");
            var notifications = NotificationText.Write(
            [
                new Notification { Type = NotificationTypes.ClubJoinRequest, Subject = "Ada" },
                new Notification { Type = NotificationTypes.ClubJoinApproved, Subject = "Club" },
            ]);
            var all = string.Concat(
                reset.Subject, reset.Text, reset.Html, sso.Subject, sso.Text, sso.Html,
                notifications.Subject, notifications.Text, notifications.Html);

            Assert.DoesNotContain("ResetSubject", all);
            Assert.DoesNotContain("ResetIntro", all);
            Assert.DoesNotContain("SsoBody", all);
            Assert.DoesNotContain("RideReady", all);
            Assert.DoesNotContain("ClubJoinRequest", all);
            Assert.DoesNotContain("UpdatesSubject", all);
            Assert.DoesNotContain("Footer", all);
        }
    }

    [Fact]
    public void EmailText_ShouldEncodeUserText_WhenItIsWrittenToHtml()
    {
        using var _ = EmailLanguage.Use("en");
        var content = NotificationText.Write(
            [new Notification { Type = NotificationTypes.ClubJoinRequest, Subject = "<b>Eve</b>" }]);

        Assert.Contains("&lt;b&gt;Eve&lt;/b&gt;", content.Html);
        Assert.DoesNotContain("<b>Eve</b>", content.Html);
    }
}
