using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Tests.Rides;

/// <summary>
/// Aerobic decoupling and efficiency factor (Story 7) against the numbers written in the story: 15 minutes of warm-up
/// at 150 W and 120 bpm, then 70 minutes at 200 W with heart rate 140 for half and 147 for the other.
/// </summary>
public sealed class DecouplingTests
{
    private const int Seconds = 85 * 60;

    /// <summary>The story's ride, one second at a time: warm-up at 150 W and 120 bpm, then 35 minutes at 140 bpm and 35 at 147.</summary>
    private static (double Power, double HeartRate)[] Ride()
    {
        var seconds = new List<(double, double)>(Seconds);
        for (var t = 0; t < Seconds; t++)
        {
            seconds.Add(t < 15 * 60
                ? (150, 120)
                : t < 15 * 60 + 35 * 60 ? (200, 140) : (200, 147));
        }

        return [.. seconds];
    }

    /// <summary>The same ride as a file: one sample a second, with power and heart rate alike.</summary>
    private static List<Sample> Samples(Func<int, (short Power, short HeartRate)>? at = null)
    {
        var samples = new List<Sample>(Seconds);
        for (var t = 0; t < Seconds; t++)
        {
            var (power, heartRate) = at?.Invoke(t)
                ?? (t < 15 * 60 ? ((short)150, (short)120) : t < 15 * 60 + 35 * 60 ? ((short)200, (short)140) : ((short)200, (short)147));
            samples.Add(new Sample(t, Power: power, HeartRate: heartRate));
        }

        return samples;
    }

    private static (double? EfficiencyFactor, double? DecouplingPct, bool? Steady) Compute(IReadOnlyList<Sample> samples)
    {
        var pause = RideMetrics.PauseThresholdS(samples);
        return RideMetrics.Efficiency(RideMetrics.PairedSeconds(samples, pause));
    }

    [Fact]
    public void Decoupling_ShouldBeFourPointEight_WhenHeartRateRisesFrom140To147()
    {
        var (efficiencyFactor, decoupling, steady) = RideMetrics.Efficiency(Ride());

        Assert.Equal(4.8, decoupling);
        // The kept seconds are 200 W steady over a mean of 143.5 bpm: 200 / 143.5 to two decimals.
        Assert.Equal(Math.Round(200 / 143.5, 2), efficiencyFactor);
        Assert.Equal(1.39, efficiencyFactor);
        Assert.True(steady);
    }

    [Fact]
    public void Decoupling_ShouldBeNull_WhenLessThan40MinutesRemainAfterWarmUp()
    {
        // 54 minutes of pedalling: 39 minutes are left once the warm-up goes.
        var (efficiencyFactor, decoupling, steady) = RideMetrics.Efficiency(Ride()[..(54 * 60)]);

        Assert.Null(efficiencyFactor);
        Assert.Null(decoupling);
        Assert.Null(steady);
    }

    [Fact]
    public void Decoupling_ShouldBeNull_WhenTheRideIsNotSteady()
    {
        // Five minutes at 300 W alternating with five at 100 W: normalized power 250 W over an average of 200 W is a
        // variability index of 1.25, so the heart rate drift these seconds show means nothing.
        var (efficiencyFactor, decoupling, steady) = RideMetrics.Efficiency(
            [.. Ride().Select((s, i) => i < 15 * 60 ? s : ((i - 15 * 60) / 300 % 2 == 0 ? (300.0, s.HeartRate) : (100.0, s.HeartRate)))]);

        Assert.Equal(1.75, efficiencyFactor); // 250 W over the 143.5 bpm these seconds average
        Assert.Null(decoupling);
        Assert.False(steady);
    }

    [Fact]
    public void EfficiencyFactor_ShouldIgnorePauses_WhenTheRideStopped()
    {
        // Ten minutes with no samples at all: the gap is a pause, and no second of it reaches the kept list.
        var samples = Samples().Where(s => s.T is < 30 * 60 or >= 40 * 60).ToList();

        var (efficiencyFactor, _, steady) = Compute(samples);

        // Every remaining sample but the last stands for one second: 4,498, not the 5,100 of a straight clock.
        var pause = RideMetrics.PauseThresholdS(samples);
        Assert.Equal(4500 - 2, RideMetrics.PairedSeconds(samples, pause).Length);
        Assert.Equal(1.39, efficiencyFactor);
        Assert.True(steady);
    }

    [Fact]
    public void Decoupling_ShouldIgnoreCoasting_WhenPowerIsBelow50W()
    {
        // Ten minutes freewheeling at 0 W and 130 bpm, placed so that under 50 W are left out and the two halves
        // then hold the same 35 minutes each: the drift is the story's 4.8 %.
        const int start = 15 * 60 + 20 * 60;
        var withoutCoasting = Ride();
        var (_, decoupling, steady) = RideMetrics.Efficiency(
        [
            .. withoutCoasting[..start],
            .. Enumerable.Repeat((0.0, 130.0), 600),
            .. withoutCoasting[start..],
        ]);

        Assert.Equal(4.8, decoupling);
        Assert.True(steady);
    }

    [Fact]
    public void Decoupling_ShouldCountTheGapLikeAPause_WhenTheStrapStopsRecording()
    {
        // Five minutes with no heart rate while the power goes on: those seconds have no pair, so they leave both
        // signals together. The result is the same ride with the gap removed outright, never a pairing of power with
        // a heart rate from minutes later.
        const int gapStart = 15 * 60 + 40 * 60;
        const int gapEnd = gapStart + 5 * 60;
        var withGap = Samples().Select(s => s.T >= gapStart && s.T < gapEnd ? s with { HeartRate = null } : s).ToList();
        var withoutGap = Samples().Where(s => s.T < gapStart || s.T >= gapEnd).ToList();

        var gap = Compute(withGap);
        var closed = Compute(withoutGap);

        Assert.Equal(closed.EfficiencyFactor, gap.EfficiencyFactor);
        // The gap moves where the halves split, as a pause does, but the drift stays close to the story's 4.8 %.
        Assert.InRange(gap.DecouplingPct!.Value, 4.0, 5.0);
        Assert.True(gap.Steady);
    }

    [Fact]
    public void Decoupling_ShouldBeNull_WhenCoastingHidesAVariableKeptStretch()
    {
        // An hour of 5-minute blocks at 300 W and 100 W, then an hour of freewheeling at 0 W.
        // The whole ride's normalized power (210 W) over the kept average (200 W) reads steady; the kept seconds
        // themselves are 251 W over 200 W, a variability index of 1.25, so this must not be called steady.
        var samples = Samples(t => (Power: (short)(t < 15 * 60 ? 150 : ((t - 15 * 60) / 300 % 2 == 0 ? 300 : 100)), HeartRate: (short)140)).ToList();
        for (var t = Seconds; t < Seconds + 60 * 60; t++) samples.Add(new Sample(t, Power: 0, HeartRate: 118));

        var (efficiencyFactor, decoupling, steady) = Compute(samples);

        Assert.Equal(1.79, efficiencyFactor); // the kept seconds' 251 W over their 140 bpm
        Assert.Null(decoupling);
        Assert.False(steady);
    }
}
