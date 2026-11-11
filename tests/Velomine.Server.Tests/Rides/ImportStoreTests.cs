using Microsoft.Extensions.Options;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Import;

namespace Velomine.Server.Tests.Rides;

public sealed class ImportStoreTests
{
    [Fact]
    public async Task ImportStore_ShouldDeleteArchivesNoImportNeeds_WhenTheServerStarts()
    {
        var dir = Directory.CreateTempSubdirectory("velomine-imports-");
        try
        {
            var store = new ImportStore(Options.Create(new RidesOptions { FilesPath = dir.FullName }));
            var alice = Guid.NewGuid();
            var bob = Guid.NewGuid();
            var keeping = await store.SaveAsync(alice, new MemoryStream([1]), TestContext.Current.CancellationToken);
            var finished = await store.SaveAsync(alice, new MemoryStream([2]), TestContext.Current.CancellationToken);
            var someoneElse = await store.SaveAsync(bob, new MemoryStream([3]), TestContext.Current.CancellationToken);
            var justUploaded = await store.SaveAsync(alice, new MemoryStream([4]), TestContext.Current.CancellationToken);
            // An archive left behind is old; a fresh one may belong to an upload still in flight.
            foreach (var sha in new[] { finished, someoneElse })
                File.SetLastWriteTimeUtc(
                    Directory.EnumerateFiles(dir.FullName, sha, SearchOption.AllDirectories).Single(),
                    DateTime.UtcNow.AddHours(-1));

            store.KeepOnly(new HashSet<(Guid, string)> { (alice, keeping) });

            using var kept = store.OpenRead(alice, keeping);
            Assert.NotNull(kept);
            using var recent = store.OpenRead(alice, justUploaded);
            Assert.NotNull(recent);
            Assert.Null(store.OpenRead(alice, finished));
            Assert.Null(store.OpenRead(bob, someoneElse));
        }
        finally
        {
            dir.Delete(recursive: true);
        }
    }
}
