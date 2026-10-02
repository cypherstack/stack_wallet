import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/openalias/open_alias.dart';
import 'package:stackwallet/services/openalias/doh_open_alias.dart';

Map<String, dynamic> reply({
  bool ad = true,
  List<Map<String, dynamic>>? answers,
}) => {
  'Status': 0,
  'AD': ad,
  'CD': false,
  'TC': false,
  'Question': [
    {'name': 'alice.example.', 'type': 16},
  ],
  'Answer':
      answers ?? [txt('alice.example.', 'oa1:xmr recipient_address=valid;')],
};
Map<String, dynamic> txt(String name, String data) => {
  'name': name,
  'type': 16,
  'TTL': 60,
  'data': data,
};
OpenAliasRecipient select(List<String> records) => selectOpenAliasRecipient(
  domain: 'alice.example',
  records: records,
  validateAddress: (s) => s == 'valid' || s == 'second',
);

void main() {
  test('joins TXT chunks within one record, with presentation escapes', () {
    expect(
      decodeDnsTxt(r'"oa1:xmr recipient_address=va" "lid;"'),
      'oa1:xmr recipient_address=valid;',
    );
    expect(decodeDnsTxt(r'"a\032b\"c"'), 'a b"c');
    expect(
      decodeDnsTxt('oa1:xmr recipient_address=valid;'),
      'oa1:xmr recipient_address=valid;',
    );
  });
  test('malformed TXT presentation cannot become an address', () {
    for (final input in ['"unterminated', '"one" junk', r'"\999"']) {
      expect(() => decodeDnsTxt(input), throwsA(isA<OpenAliasException>()));
    }
  });
  test(
    'accepts only authenticated, complete answers to the exact question',
    () {
      expect(decodeAuthenticatedDns(reply(), 'alice.example'), hasLength(1));
      for (final altered in [
        reply(ad: false),
        reply()..remove('AD'),
        reply()..['CD'] = true,
        reply()..['TC'] = true,
        reply()..['Status'] = 2,
        reply()
          ..['Question'] = [
            {'name': 'attacker.example.', 'type': 16},
          ],
      ]) {
        expect(
          () => decodeAuthenticatedDns(altered, 'alice.example'),
          throwsA(isA<OpenAliasException>()),
        );
      }
    },
  );
  test('follows authenticated CNAMEs and ignores unrelated TXT answers', () {
    final records = decodeAuthenticatedDns(
      reply(
        answers: [
          {
            'name': 'alice.example.',
            'type': 5,
            'TTL': 60,
            'data': 'pay.example.',
          },
          txt('pay.example.', 'oa1:xmr recipient_address=valid;'),
          txt('attacker.example.', 'oa1:xmr recipient_address=second;'),
        ],
      ),
      'alice.example',
    );
    expect(select(records).address, 'valid');
  });
  test('follows CNAMEs to underscore names', () {
    final records = decodeAuthenticatedDns(
      reply(
        answers: [
          {
            'name': 'alice.example.',
            'type': 5,
            'TTL': 60,
            'data': '_oa.pay.example.',
          },
          txt('_oa.pay.example.', 'oa1:xmr recipient_address=valid;'),
        ],
      ),
      'alice.example',
    );
    expect(select(records).address, 'valid');
  });
  test('names the alias when no record exists or the lookup fails', () {
    for (final (status, message) in [
      (3, 'No OpenAlias record exists for alice.example.'),
      (2, 'The DNS lookup for alice.example failed. No address was accepted.'),
    ]) {
      expect(
        () => decodeAuthenticatedDns({
          ...reply(),
          'Status': status,
        }, 'alice.example'),
        throwsA(
          isA<OpenAliasException>().having(
            (e) => e.message,
            'message',
            message,
          ),
        ),
      );
    }
  });
  test('reports malformed answer names as invalid responses', () {
    expect(
      () => decodeAuthenticatedDns(
        reply(
          answers: [
            {
              'name': 'alice.example.',
              'type': 5,
              'TTL': 60,
              'data': 'pay..example.',
            },
          ],
        ),
        'alice.example',
      ),
      throwsA(
        isA<OpenAliasException>().having(
          (e) => e.message,
          'message',
          'Invalid DNS response.',
        ),
      ),
    );
  });
  test('rejects CNAME loops and CNAME/TXT ambiguity', () {
    for (final answers in [
      [
        {'name': 'alice.example.', 'type': 5, 'data': 'alice.example.'},
      ],
      [
        {'name': 'alice.example.', 'type': 5, 'data': 'pay.example.'},
        txt('alice.example.', 'oa1:xmr recipient_address=valid;'),
      ],
    ]) {
      expect(
        () => decodeAuthenticatedDns(reply(answers: answers), 'alice.example'),
        throwsA(isA<OpenAliasException>()),
      );
    }
  });
}
