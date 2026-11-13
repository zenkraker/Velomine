namespace Velomine.Server.Tests;

/// <summary>A clock a test can move forward, for a link that must stop working.</summary>
public sealed class FakeTime : TimeProvider
{
    public DateTimeOffset Now { get; set; } = DateTimeOffset.UtcNow;

    public override DateTimeOffset GetUtcNow() => Now;
}
