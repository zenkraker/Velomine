import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:velomine_api/api.dart';

void main() {
  test(
    'SupporterApi_ShouldSendTheKeyAsJson_WhenTheLicenceIsActivated',
    () async {
      late http.Request sent;
      final client = ApiClient(basePath: 'https://example.test')
        ..client = MockClient((request) async {
          sent = request;
          return http.Response(
            '{"available":true,"rider":null,"club":null}',
            200,
          );
        });

      await SupporterApi(client)
          .activateSupporter(ActivateSupporterRequest(key: 'abc.def'));

      expect(sent.method, 'POST');
      expect(sent.url.path, '/api/v1/supporter/activate');
      expect(sent.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(sent.body), {'key': 'abc.def'});
    },
  );
}
