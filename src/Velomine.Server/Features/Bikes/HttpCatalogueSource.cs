using System.Net;
using System.Net.Http.Json;
using Microsoft.Extensions.Options;

namespace Velomine.Server.Features.Bikes;

/// <summary>Reads the publisher's full list over HTTP.</summary>
public sealed class HttpCatalogueSource(HttpClient client, IOptions<CatalogueOptions> options) : ICatalogueSource
{
    public async Task<CatalogueFeed?> FetchAsync(CancellationToken ct)
    {
        var url = options.Value.Url;
        if (string.IsNullOrWhiteSpace(url)) return null;

        using var request = new HttpRequestMessage(HttpMethod.Get, url);
        using var response = await client.SendAsync(request, ct);
        if (response.StatusCode == HttpStatusCode.NotModified) return null;
        response.EnsureSuccessStatusCode();

        return await response.Content.ReadFromJsonAsync<CatalogueFeed>(CatalogueSync.JsonOptions, ct);
    }
}
