using FastEndpoints;

namespace Velomine.Server.Features.Bikes;

public sealed record ComponentTypeResponse(string Id, string Name, string Group, double? TypicalDistanceM, double? TypicalHours, int? TypicalMonths);

public sealed record ListComponentTypesResponse(ComponentTypeResponse[] Types);

/// <summary>The kinds of parts a bike can have, with rough typical lifetimes to start from. The typical values are suggestions, not facts about any one part.</summary>
public sealed class ListComponentTypes : EndpointWithoutRequest<ListComponentTypesResponse>
{
    public override void Configure()
    {
        Get("bikes/component-types");
        Description(d => d.Produces<ListComponentTypesResponse>(200).Produces(401), clearDefaults: true);
    }

    public override Task HandleAsync(CancellationToken ct) =>
        Send.OkAsync(new ListComponentTypesResponse([.. ComponentTypes.All.Select(t =>
            new ComponentTypeResponse(t.Id, t.Name, t.Group, t.TypicalDistanceKm * 1000, t.TypicalHours, t.TypicalMonths))]), ct);
}
