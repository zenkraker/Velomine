import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/server_config.dart';

class MemoryServerConfigStore implements ServerConfigStore {
  MemoryServerConfigStore([this.value]);

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String? value) async => this.value = value;
}

void main() {
  group('normalizeServerUrl', () {
    test('normalizeServerUrl_ShouldKeepAddressAndStripSlash_WhenPlainUrl', () {
      expect(
        normalizeServerUrl('https://velo.example'),
        'https://velo.example',
      );
      expect(
        normalizeServerUrl('  https://velo.example/  '),
        'https://velo.example',
      );
      expect(
        normalizeServerUrl('http://192.168.1.10:8080/'),
        'http://192.168.1.10:8080',
      );
    });

    test('normalizeServerUrl_ShouldAcceptApiAndProxyPath_WhenPasted', () {
      expect(
        normalizeServerUrl('https://velo.example/api/v1'),
        'https://velo.example',
      );
      expect(
        normalizeServerUrl('https://club.example/velomine/'),
        'https://club.example/velomine',
      );
    });

    test('normalizeServerUrl_ShouldRejectNonHttpAddresses_WhenGivenThem', () {
      for (final bad in [
        '',
        'velo.example',
        'ftp://velo.example',
        'https://',
        'https://user:secret@velo.example',
        'https://velo.example?x=1',
        'https://velo.example/#section',
      ]) {
        expect(normalizeServerUrl(bad), isNull, reason: bad);
      }
    });
  });

  group('ServerConfigViewModel', () {
    ProviderContainer container({
      MemoryServerConfigStore? store,
      bool web = false,
      String? origin,
    }) {
      final container = ProviderContainer(
        overrides: [
          serverConfigStoreProvider.overrideWithValue(
            store ?? MemoryServerConfigStore(),
          ),
          isWebProvider.overrideWithValue(web),
          webOriginProvider.overrideWithValue(origin),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test(
      'ServerConfigViewModel_ShouldLoadSaveAndClearAddress_WhenStoreHasValues',
      () async {
        final store = MemoryServerConfigStore('https://old.example/');
        final app = container(store: store);
        var config = await app.read(serverConfigViewModelProvider.future);
        expect(config.baseUrl, 'https://old.example');

        await app
            .read(serverConfigViewModelProvider.notifier)
            .save('https://new.example/');
        config = app.read(serverConfigViewModelProvider).value!;
        expect(config.baseUrl, 'https://new.example');
        expect(store.value, 'https://new.example');

        await app.read(serverConfigViewModelProvider.notifier).clear();
        config = app.read(serverConfigViewModelProvider).value!;
        expect(config.baseUrl, isNull);
        expect(store.value, isNull);
        expect(config.previousUrl, 'https://new.example');
      },
    );

    test('ServerConfigViewModel_ShouldHaveNoAddress_WhenNoneIsSaved', () async {
      final app = container();
      final config = await app.read(serverConfigViewModelProvider.future);
      expect(config.baseUrl, isNull);
    });

    test(
      'ServerConfigViewModel_ShouldUseOwnOrigin_WhenRunningAsWebApp',
      () async {
        final app = container(web: true, origin: 'https://velo.example');
        final config = await app.read(serverConfigViewModelProvider.future);
        expect(config.baseUrl, 'https://velo.example');
      },
    );
  });
}
