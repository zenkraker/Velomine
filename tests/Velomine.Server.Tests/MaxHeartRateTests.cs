using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Tests;

/// <summary>Tanaka's estimate, 208 - 0.7 x age, and the clamp that keeps an absurd birth year from breaking it.</summary>
public sealed class MaxHeartRateTests
{
    private static readonly TimeProvider NewYear = new FixedTime(new DateTimeOffset(2026, 11, 13, 0, 0, 0, TimeSpan.Zero));

    [Theory]
    [InlineData(1986, 180)] // 40 years: 208 - 28
    [InlineData(1990, 183)] // 36 years: 208 - 25.2 = 182.8, rounded
    [InlineData(2000, 190)] // 26 years: 208 - 18.2 = 189.8, rounded
    [InlineData(1976, 173)] // 50 years: 208 - 35
    public void EstimateMaxHeartRate_ShouldFollowTanaka_WhenTheBirthYearIsKnown(int birthYear, int expected) =>
        Assert.Equal(expected, User.EstimateMaxHeartRate(birthYear, NewYear));

    [Fact]
    public void EstimateMaxHeartRate_ShouldUseAGrownUpAge_WhenTheBirthYearIsThisDecade() =>
        // One year old is a data error: the age is held at 10, so 208 - 7.
        Assert.Equal(201, User.EstimateMaxHeartRate(2025, NewYear));

    [Fact]
    public void EstimateMaxHeartRate_ShouldUseAGrownUpAge_WhenTheBirthYearIsOlderThanACentury() =>
        // 1926 is 100 years: the age is held at 100, so 208 - 70.
        Assert.Equal(138, User.EstimateMaxHeartRate(1926, NewYear));

    [Fact]
    public void EstimateMaxHeartRate_ShouldBeNull_WhenTheMemberHasNoBirthYear() =>
        Assert.Null(User.EstimateMaxHeartRate(null, NewYear));
}
