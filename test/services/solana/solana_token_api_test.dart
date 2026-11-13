import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:solana/solana.dart';
import 'package:stackwallet/services/solana/solana_token_api.dart';

void main() {
  late HttpServer server;
  late HttpClient httpClient;
  late SolanaTokenAPI api;
  late List<Map<String, dynamic>> requests;
  Object? resultValue;

  setUp(() async {
    requests = [];
    resultValue = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final body = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, dynamic>;
      requests.add(body);
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': body['id'],
          'result': {
            'context': {'slot': 1},
            'value': resultValue,
          },
        }),
      );
      await request.response.close();
    });
    httpClient = HttpClient();
    final client = RpcClient(
      'http://127.0.0.1:${server.port}',
      httpClient: httpClient,
    );
    api = SolanaTokenAPI(rpcClient: client);
  });

  tearDown(() async {
    httpClient.close(force: true);
    await server.close(force: true);
  });

  test('all-token query uses the official SPL program', () async {
    final result = await api.getTokenAccountsByOwner('owner');

    expect(result.isSuccess, isTrue);
    expect(requests.single['method'], 'getTokenAccountsByOwner');
    expect((requests.single['params'] as List)[1], {
      'programId': 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA',
    });
  });

  test('mint-filtered query keeps its explicit mint', () async {
    final result = await api.getTokenAccountsByOwner('owner', mint: 'mint');

    expect(result.isSuccess, isTrue);
    expect((requests.single['params'] as List)[1], {'mint': 'mint'});
  });

  test('mint ownership distinguishes SPL and Token-2022 exactly', () async {
    Future<String?> programType(String owner) async {
      resultValue = {
        'data': ['', 'base64'],
        'executable': false,
        'lamports': 1,
        'owner': owner,
        'rentEpoch': 0,
      };
      return api.getTokenProgramType('mint');
    }

    expect(await programType(TokenProgram.programId), 'spl');
    expect(await programType(Token2022Program.programId), 'token2022');
    expect(await programType(SystemProgram.programId), isNull);
    expect(await programType('TokenUnknownProgram'), isNull);
  });
}
