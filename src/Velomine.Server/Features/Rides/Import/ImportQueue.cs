using System.Threading.Channels;

namespace Velomine.Server.Features.Rides.Import;

/// <summary>Imports waiting to be read. In memory: the import rows themselves are the durable record.</summary>
public sealed class ImportQueue
{
    private readonly Channel<Guid> channel = Channel.CreateUnbounded<Guid>(new UnboundedChannelOptions { SingleReader = true });

    public void Enqueue(Guid importId) => channel.Writer.TryWrite(importId);

    public IAsyncEnumerable<Guid> ReadAllAsync(CancellationToken ct) => channel.Reader.ReadAllAsync(ct);
}
