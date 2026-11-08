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

  group('ServerConfig', () {
    test(
      'ServerConfig_ShouldLoadSaveAndClearAddress_WhenStoreHasValues',
      () async {
        final store = MemoryServerConfigStore('https://old.example/');
        final config = ServerConfig(store: store, web: false);
        await config.load();
        expect(config.baseUrl, 'https://old.example');

        await config.save('https://new.example/');
        expect(config.baseUrl, 'https://new.example');
        expect(store.value, 'https://new.example');

        await config.clear();
        expect(config.baseUrl, isNull);
        expect(store.value, isNull);
        expect(config.previousUrl, 'https://new.example');
      },
    );

    test('ServerConfig_ShouldHaveNoAddress_WhenNoneIsSaved', () async {
      final config = ServerConfig(store: MemoryServerConfigStore(), web: false);
      await config.load();
      expect(config.baseUrl, isNull);
    });

    test('ServerConfig_ShouldUseOwnOrigin_WhenRunningAsWebApp', () async {
      final config = ServerConfig(
        store: MemoryServerConfigStore(),
        web: true,
        webOrigin: 'https://velo.example',
      );
      await config.load();
      expect(config.baseUrl, 'https://velo.example');
    });
  });
}
