using System.Runtime.CompilerServices;
using System.Threading.Channels;

namespace Velomine.Server.Features.Rides.Ingestion;

/// <summary>Rides waiting to be read. In memory: the ride rows themselves are the durable record (see RideIngestionService).</summary>
public sealed class IngestionQueue
{
    private readonly Channel<Guid> channel = Channel.CreateUnbounded<Guid>(new UnboundedChannelOptions { SingleReader = true });

    private int pending;

    public void Enqueue(Guid rideId)
    {
        Interlocked.Increment(ref pending);
        if (!channel.Writer.TryWrite(rideId)) Interlocked.Decrement(ref pending);
    }

    /// <summary>How many rides are waiting. The background re-read of old rides yields while this is above zero.</summary>
    public int Pending => Volatile.Read(ref pending);

    public async IAsyncEnumerable<Guid> ReadAllAsync([EnumeratorCancellation] CancellationToken ct)
    {
        await foreach (var id in channel.Reader.ReadAllAsync(ct))
        {
            Interlocked.Decrement(ref pending);
            yield return id;
        }
    }
}
