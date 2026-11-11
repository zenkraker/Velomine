using System.Reflection;

namespace Velomine.Server;

/// <summary>
/// Which build is running: the release version and the short commit it was built from, for example
/// <c>1.4.0+8d4e631</c>. The image passes both in (Dockerfile <c>VERSION</c> and <c>REVISION</c>); a deploy checks
/// <c>GET /api/v1/server</c> for the commit to know its image went live. A build without them reports the project
/// default.
/// </summary>
public static class BuildInfo
{
    private const int ShortRevision = 7;

    public static string Version { get; } = Format(
        typeof(BuildInfo).Assembly.GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion,
        typeof(BuildInfo).Assembly.GetName().Version);

    /// <summary>Keeps the version and at most seven characters of the commit after the <c>+</c>.</summary>
    public static string Format(string? informational, Version? assembly)
    {
        if (string.IsNullOrEmpty(informational)) return assembly?.ToString(3) ?? "0.0.0";

        var plus = informational.IndexOf('+', StringComparison.Ordinal);
        if (plus < 0) return informational;

        return informational.Length - plus - 1 > ShortRevision
            ? informational[..(plus + 1 + ShortRevision)]
            : informational;
    }
}
