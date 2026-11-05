namespace Velomine.Server.Tests;

/// <summary>A clock that always says the same instant, so "today" and "this week" are known in a test.</summary>
public sealed class FixedTime(DateTimeOffset now) : TimeProvider
{
    public override DateTimeOffset GetUtcNow() => now;
}
