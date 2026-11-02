using System.Threading.Channels;

namespace Velomine.Server.Features.Rides.Ingestion;

/// <summary>Rides waiting to be read. In memory: the ride rows themselves are the durable record (see RideIngestionService).</summary>
public sealed class IngestionQueue
{
    private readonly Channel<Guid> channel = Channel.CreateUnbounded<Guid>(new UnboundedChannelOptions { SingleReader = true });

    public void Enqueue(Guid rideId) => channel.Writer.TryWrite(rideId);

    public IAsyncEnumerable<Guid> ReadAllAsync(CancellationToken ct) => channel.Reader.ReadAllAsync(ct);
}
