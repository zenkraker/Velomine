namespace Velomine.Server.Tests;

public sealed class BuildInfoTests
{
    [Fact]
    public void Format_ShouldKeepTheShortCommit_WhenBuiltFromACommit() =>
        Assert.Equal("1.4.0+8d4e631", BuildInfo.Format("1.4.0+8d4e631b9c9eafab54e19df366b8581c3dc2da74", new Version(1, 4, 0)));

    [Fact]
    public void Format_ShouldKeepThePrerelease_WhenBuiltFromMain() =>
        Assert.Equal("0.0.0-main.42+8d4e631", BuildInfo.Format("0.0.0-main.42+8d4e631b9c9eafab54e19df366b8581c3dc2da74", new Version(0, 0, 0)));

    [Fact]
    public void Format_ShouldReturnTheVersionAlone_WhenThereIsNoCommit() =>
        Assert.Equal("1.4.0", BuildInfo.Format("1.4.0", new Version(1, 4, 0, 0)));

    [Fact]
    public void Format_ShouldFallBackToTheAssemblyVersion_WhenThereIsNoInformationalVersion() =>
        Assert.Equal("1.0.0", BuildInfo.Format(null, new Version(1, 0, 0, 0)));
}
