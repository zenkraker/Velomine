using Microsoft.Extensions.Options;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Admin;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Notifications.Email;

namespace Velomine.Server.Tests;

/// <summary>The solo trial's date and the email wording that goes with it, without a server.</summary>
public sealed class SoloTrialTests
{
    private static readonly DateOnly Today = new(2026, 11, 12);

    /// <summary>The date the trial reports as ended: past means "the trial is over".</summary>
    private static bool TrialEnded(DateOnly? endsAt, DateOnly today) => endsAt is { } until && today > until;

    [Fact]
    public void Register_ShouldEndTheTrialThirtyDaysLater_WhenSigningUp()
    {
        Assert.Equal(new DateOnly(2026, 12, 12), Today.AddDays(ClubPlan.TrialDays));
    }

    [Fact]
    public void SoloTrial_ShouldHaveEnded_WhenTodayIsPastTheEndDate()
    {
        var endsAt = Today.AddDays(ClubPlan.TrialDays);

        // The end date itself is still covered; the day after is not. A trial with no date has not ended either.
        Assert.True(TrialEnded(endsAt, endsAt.AddDays(1)));
        Assert.False(TrialEnded(endsAt, endsAt));
        Assert.False(TrialEnded(null, endsAt));
    }

    [Fact]
    public void EmailVerification_ShouldBeRequired_WhenSmtpIsConfigured()
    {
        Assert.True(EmailVerification.Required(Options.Create(new SmtpOptions { Host = "smtp.club.example", From = "velomine@club.example" })));
        Assert.False(EmailVerification.Required(Options.Create(new SmtpOptions())));
    }

    [Fact]
    public void EmailVerificationEmail_ShouldUseItsItalianWording_WhenTheMemberSpeaksItalian()
    {
        using var _ = EmailLanguage.Use("it");
        var content = EmailVerificationEmail.Confirmation("https://club.example/verify-email#token=t");

        Assert.Equal("Conferma la tua email per Velomine", content.Subject);
        Assert.Contains("https://club.example/verify-email#token=t", content.Text);
        Assert.Contains("Conferma la mia email", content.Html);
    }
}
