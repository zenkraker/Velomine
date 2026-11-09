using Velomine.Server.Features.Bikes;

namespace Velomine.Server.Tests.Bikes;

/// <summary>
/// The whole of the matching rules. No lookup, no model, no guessing: a part is either identified by a well-formed
/// GTIN, by its brand and part number, or by its name within the club.
/// </summary>
public sealed class PartIdentityTests
{
    [Theory]
    [InlineData("4006381333931", "04006381333931")] // EAN-13
    [InlineData("036000291452", "00036000291452")] // UPC-A
    [InlineData("96385074", "00000096385074")] // GTIN-8
    [InlineData("12345678901231", "12345678901231")] // GTIN-14
    public void Gtin_ShouldNormaliseToFourteenDigits_WhenTheCheckDigitIsRight(string input, string expected)
    {
        Assert.True(PartIdentity.TryNormaliseGtin(input, out var gtin14));
        Assert.Equal(expected, gtin14);
    }

    [Theory]
    [InlineData("4006381333932")] // wrong check digit
    [InlineData("400638133393")] // not a GTIN length
    [InlineData("40063813339A1")] // not digits
    [InlineData("")]
    public void Gtin_ShouldBeRejected_WhenItIsNotAWellFormedGtin(string input) =>
        Assert.False(PartIdentity.TryNormaliseGtin(input, out _));

    [Fact]
    public void PartKey_ShouldMatchTheGtin_WhenTheSamePartArrivesWithDifferentNames()
    {
        var first = PartIdentity.Key("chain", "Shimano", "Ultegra chain", "CN-HG701", "4006381333931");
        var second = PartIdentity.Key("chain", "shimano", "HG701 11-speed", null, "4006381333931");

        Assert.Equal(first, second);
    }

    [Fact]
    public void PartKey_ShouldMatch_WhenBrandAndPartNumberDifferOnlyInCaseAndSpacing()
    {
        var first = PartIdentity.Key("chain", "Shimano", "Ultegra", "CN-M8100", null);
        var second = PartIdentity.Key("chain", "  SHIMANO ", "Ultegra", "cn-m8100", null);

        Assert.Equal(first, second);
    }

    [Fact]
    public void PartKey_ShouldFallBackToTheName_WhenThereIsNoOfficialIdentifier()
    {
        var key = PartIdentity.Key("chain", "Shimano", "CN-M8100", null, null);

        Assert.Equal("name:chain|shimano|cn-m8100", key);
    }

    [Fact]
    public void PartKey_ShouldBeNull_WhenThereIsNothingToMatchOn() =>
        Assert.Null(PartIdentity.Key("chain", null, null, null, null));

    [Fact]
    public void Brand_ShouldUseTheIndustrySpelling_WhenWrittenAnotherWay()
    {
        Assert.Equal("Shimano", PartIdentity.CanonicalBrand("SHIMANO"));
        Assert.Equal("Shimano", PartIdentity.CanonicalBrand("Shimano Inc."));
        Assert.Equal("SRAM", PartIdentity.CanonicalBrand("sram corporation"));
        Assert.Equal("Some New Brand", PartIdentity.CanonicalBrand("  Some   New Brand "));
    }
}
