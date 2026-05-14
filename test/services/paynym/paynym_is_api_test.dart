import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/networking/http.dart';
import 'package:stackwallet/utilities/paynym_is_api.dart';

import 'paynym_is_api_test.mocks.dart';

@GenerateMocks([HTTP])
void main() {
  late PaynymIsApi api;
  late MockHTTP client;

  setUp(() {
    client = MockHTTP();
    api = PaynymIsApi();
    api.client = client;
  });

  void stubPost(
    String endpoint,
    String responseBody,
    int statusCode, {
    Map<String, String>? extraHeaders,
  }) {
    when(
      client.post(
        url: Uri.parse('https://paynym.rs/api/v1$endpoint'),
        headers: anyNamed('headers'),
        proxyInfo: anyNamed('proxyInfo'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      ),
    ).thenAnswer((_) async => Response(utf8.encode(responseBody), statusCode));
  }

  group('create', () {
    test('400 with empty body returns typed error', () async {
      stubPost('/create', '', 400);
      final r = await api.create('PM8Ttest');
      expect(r.statusCode, 400);
      expect(r.message, 'Bad request');
      expect(r.value, isNull);
    });

    test('201 with valid JSON returns CreatedPaynym', () async {
      stubPost(
        '/create',
        '{"claimed":false,"nymID":"abc","nymName":"foo","segwit":true,"token":"tok"}',
        201,
      );
      final r = await api.create('PM8Ttest');
      expect(r.statusCode, 201);
      expect(r.message, 'PayNym created successfully');
      expect(r.value, isNotNull);
      expect(r.value!.nymId, 'abc');
    });

    test('200 returns existing PayNym', () async {
      stubPost(
        '/create',
        '{"claimed":true,"nymID":"abc","nymName":"foo","segwit":true,"token":"tok"}',
        200,
      );
      final r = await api.create('PM8Ttest');
      expect(r.statusCode, 200);
      expect(r.message, 'PayNym already exists');
      expect(r.value, isNotNull);
    });
  });

  group('token', () {
    test('404 with empty body returns typed error', () async {
      stubPost('/token', '', 404);
      final r = await api.token('PM8Ttest');
      expect(r.statusCode, 404);
      expect(r.message, 'Payment code was not found');
      expect(r.value, isNull);
    });

    test('400 with empty body returns typed error', () async {
      stubPost('/token', '', 400);
      final r = await api.token('PM8Ttest');
      expect(r.statusCode, 400);
      expect(r.message, 'Bad request');
      expect(r.value, isNull);
    });

    test('200 with valid JSON returns token string', () async {
      stubPost('/token', '{"token":"testToken123"}', 200);
      final r = await api.token('PM8Ttest');
      expect(r.statusCode, 200);
      expect(r.message, 'Token was successfully updated');
      expect(r.value, 'testToken123');
    });
  });

  group('nym', () {
    test('404 with empty body returns typed error', () async {
      stubPost('/nym', '', 404);
      final r = await api.nym('PM8Ttest');
      expect(r.statusCode, 404);
      expect(r.message, 'Nym not found');
      expect(r.value, isNull);
    });

    test('400 with empty body returns typed error', () async {
      stubPost('/nym', '', 400);
      final r = await api.nym('PM8Ttest');
      expect(r.statusCode, 400);
      expect(r.message, 'Bad request');
      expect(r.value, isNull);
    });

    test('200 with valid JSON returns PaynymAccount', () async {
      stubPost(
        '/nym',
        jsonEncode({
          'nymID': 'testId',
          'nymName': 'testName',
          'segwit': true,
          'codes': [
            {'claimed': true, 'segwit': true, 'code': 'PM8Ttest'},
          ],
          'followers': <Map<String, dynamic>>[],
          'following': <Map<String, dynamic>>[],
        }),
        200,
      );
      final r = await api.nym('PM8Ttest');
      expect(r.statusCode, 200);
      expect(r.message, 'Nym found and returned');
      expect(r.value, isNotNull);
      expect(r.value!.nymID, 'testId');
    });
  });

  group('claim', () {
    test('400 with empty body returns typed error', () async {
      stubPost('/claim', '', 400);
      final r = await api.claim('tok', 'sig');
      expect(r.statusCode, 400);
      expect(r.message, 'Bad request');
      expect(r.value, isNull);
    });

    test('200 with valid JSON returns PaynymClaim', () async {
      stubPost('/claim', '{"claimed":"PM8Ttest","token":"newTok"}', 200);
      final r = await api.claim('tok', 'sig');
      expect(r.statusCode, 200);
      expect(r.message, 'Payment code successfully claimed');
      expect(r.value, isNotNull);
      expect(r.value!.claimed, 'PM8Ttest');
    });
  });

  group('follow', () {
    test('404 with empty body returns typed error', () async {
      stubPost('/follow', '', 404);
      final r = await api.follow('tok', 'sig', 'target');
      expect(r.statusCode, 404);
      expect(r.message, 'Payment code not found');
      expect(r.value, isNull);
    });

    test('401 with empty body returns typed error', () async {
      stubPost('/follow', '', 401);
      final r = await api.follow('tok', 'sig', 'target');
      expect(r.statusCode, 401);
      expect(
        r.message,
        'Unauthorized token or signature or Unclaimed payment code',
      );
      expect(r.value, isNull);
    });

    test('400 with empty body returns typed error', () async {
      stubPost('/follow', '', 400);
      final r = await api.follow('tok', 'sig', 'target');
      expect(r.statusCode, 400);
      expect(r.message, 'Bad request');
      expect(r.value, isNull);
    });
  });

  group('unfollow', () {
    test('404 with empty body returns typed error', () async {
      stubPost('/unfollow', '', 404);
      final r = await api.unfollow('tok', 'sig', 'target');
      expect(r.statusCode, 404);
      expect(r.message, 'Payment code not found');
      expect(r.value, isNull);
    });

    test('401 with empty body returns typed error', () async {
      stubPost('/unfollow', '', 401);
      final r = await api.unfollow('tok', 'sig', 'target');
      expect(r.statusCode, 401);
      expect(
        r.message,
        'Unauthorized token or signature or Unclaimed payment code',
      );
      expect(r.value, isNull);
    });

    test('400 with empty body returns typed error', () async {
      stubPost('/unfollow', '', 400);
      final r = await api.unfollow('tok', 'sig', 'target');
      expect(r.statusCode, 400);
      expect(r.message, 'Bad request');
      expect(r.value, isNull);
    });
  });

  group('add', () {
    test('400 with empty body returns typed error', () async {
      stubPost('/nym/add', '', 400);
      final r = await api.add('tok', 'sig', 'nym', 'code');
      expect(r.statusCode, 400);
      expect(r.message, 'Bad request');
      expect(r.value, false);
    });

    test('401 with empty body returns typed error', () async {
      stubPost('/nym/add', '', 401);
      final r = await api.add('tok', 'sig', 'nym', 'code');
      expect(r.statusCode, 401);
      expect(
        r.message,
        'Unauthorized token or signature or Unclaimed payment code',
      );
      expect(r.value, false);
    });

    test('404 with empty body returns typed error', () async {
      stubPost('/nym/add', '', 404);
      final r = await api.add('tok', 'sig', 'nym', 'code');
      expect(r.statusCode, 404);
      expect(r.message, 'Nym not found');
      expect(r.value, false);
    });
  });
}
