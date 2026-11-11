using Microsoft.Extensions.Options;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Tests.Rides;

public sealed class RideFileStoreTests
{
    [Fact]
    public async Task RideFileStore_ShouldRefuseAndKeepNothing_WhenTheStreamIsLargerThanTheLimit()
    {
        var dir = Directory.CreateTempSubdirectory("velomine-files-");
        try
        {
            var store = new RideFileStore(Options.Create(new RidesOptions { FilesPath = dir.FullName }));
            using var content = new MemoryStream(new byte[2048]);

            await Assert.ThrowsAsync<InvalidDataException>(() =>
                store.SaveAsync(content, TestContext.Current.CancellationToken, maxBytes: 1024));

            Assert.Empty(Directory.GetFiles(dir.FullName, "*", SearchOption.AllDirectories));
        }
        finally
        {
            dir.Delete(recursive: true);
        }
    }
}
