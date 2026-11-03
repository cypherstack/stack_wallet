import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:isar_community/isar.dart';
import 'package:solana/encoder.dart' show SignedTx;
import 'package:solana/solana.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/solana_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/sub_wallets/solana_token_wallet.dart';

import '../support/isar_test_utils.dart';

class _ParentWallet extends Mock implements SolanaWallet {
  _ParentWallet(this.client, this.keyPair);

  final RpcClient client;
  final Ed25519HDKeyPair keyPair;

  @override
  Solana get cryptoCurrency => Solana(CryptoCurrencyNetwork.main);

  @override
  RpcClient getRpcClient() => client;

  @override
  Future<Ed25519HDKeyPair> getKeyPair() async => keyPair;
}

class _TokenWallet extends SolanaTokenWallet {
  _TokenWallet(super.parentSolanaWallet, super.solContract, MainDB db) {
    mainDB = db;
  }

  @override
  String get walletId => 'token-send-test';
}

void main() {
  setUpAll(initializeTestIsar);
  final scenarios = [
    for (final program in [TokenProgram.programId, Token2022Program.programId])
      for (final recipientExists in [false, true])
        (program: program, recipientExists: recipientExists, failed: false),
    (program: SystemProgram.programId, recipientExists: false, failed: false),
    (program: Token2022Program.programId, recipientExists: false, failed: true),
  ];
  for (final scenario in scenarios) {
    final program = scenario.program;
    test(
      program == SystemProgram.programId
          ? 'rejects unsupported sender token program'
          : scenario.failed
          ? 'on-chain token failure is reported to the confirmation caller'
          : 'recipient account uses $program '
                '(exists: ${scenario.recipientExists})',
      () async {
        final keyPair = await Ed25519HDKeyPair.fromSeedWithHdPath(
          seed: List.filled(32, 1),
          hdPath: "m/44'/501'/0'/0'",
        );
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final http = HttpClient();
        addTearDown(() async {
          http.close(force: true);
          await server.close(force: true);
        });
        final account = {
          'owner': program,
          'lamports': 1,
          'executable': false,
          'rentEpoch': 0,
          'data': ['', 'base64'],
        };
        var mintLookupCount = 0;
        var statusLookupCount = 0;
        late final Isar isar;
        final retryStatusLookup =
            program == TokenProgram.programId && scenario.recipientExists;
        SignedTx? sentTransaction;
        server.listen((request) async {
          final body =
              jsonDecode(await utf8.decoder.bind(request).join()) as Map;
          final params = body['params'] as List;
          final isMintLookup =
              body['method'] == 'getAccountInfo' &&
              params.first == Token2022Program.programId;
          if (isMintLookup) {
            mintLookupCount++;
          }
          request.response.headers.contentType = ContentType.json;
          if (isMintLookup) {
            request.response.write(
              jsonEncode({
                'jsonrpc': '2.0',
                'id': body['id'],
                'error': {
                  'code': -32000,
                  'message': 'Unexpected mint owner lookup',
                },
              }),
            );
            await request.response.close();
            return;
          }
          if (body['method'] == 'sendTransaction') {
            sentTransaction = SignedTx.decode(params.first as String);
            request.response.write(
              jsonEncode({
                'jsonrpc': '2.0',
                'id': body['id'],
                'result': sentTransaction!.id,
              }),
            );
            await request.response.close();
            return;
          }
          if (body['method'] == 'getSignatureStatuses') {
            statusLookupCount++;
            if (retryStatusLookup && statusLookupCount == 1) {
              expect(
                isar.transactionV2s.countSync(),
                1,
                reason: 'An uncertain RPC result must retain the broadcast transfer',
              );
              request.response.write(
                jsonEncode({
                  'jsonrpc': '2.0',
                  'id': body['id'],
                  'error': {
                    'code': -32000,
                    'message': 'Temporarily unavailable',
                  },
                }),
              );
              await request.response.close();
              return;
            }
          }
          final value = switch (body['method']) {
            'getTokenAccountsByOwner' =>
              params.first == keyPair.address
                  ? <Map<String, Object>>[
                      {'pubkey': TokenProgram.programId, 'account': account},
                    ]
                  : scenario.recipientExists
                  ? <Map<String, Object>>[
                      {
                        'pubkey': AssociatedTokenAccountProgram.programId,
                        'account': account,
                      },
                    ]
                  : <Map<String, Object>>[],
            'getAccountInfo' =>
              (params.first == TokenProgram.programId ||
                      params.first == Token2022Program.programId ||
                      params.first == AssociatedTokenAccountProgram.programId)
                  ? account
                  : null,
            'getLatestBlockhash' => {
              'blockhash': SystemProgram.programId,
              'lastValidBlockHeight': 1,
            },
            'getFeeForMessage' => 5000,
            'getSignatureStatuses' => [
              {
                'slot': 1,
                'confirmations': 1,
                'confirmationStatus': 'confirmed',
                'err': scenario.failed
                    ? {
                        'InstructionError': [0, 'InvalidAccountData'],
                      }
                    : null,
              },
            ],
            _ => throw StateError('Unexpected RPC: ${body['method']}'),
          };
          request.response.write(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': body['id'],
              'result': {
                'context': {'slot': 1},
                'value': value,
              },
            }),
          );
          await request.response.close();
        });
        final client = RpcClient(
          'http://127.0.0.1:${server.port}',
          httpClient: http,
        );
        final directory = await Directory.systemTemp.createTemp(
          'sol-token-confirmation-',
        );
        isar = await Isar.open(
          [TransactionV2Schema],
          directory: directory.path,
          name: 'sol-token-confirmation',
          inspector: false,
        );
        addTearDown(() async {
          await isar.close();
          await directory.delete(recursive: true);
        });
        final db = MainDB.instance;
        await db.initMainDB(mock: isar);
        final wallet = _TokenWallet(
          _ParentWallet(client, keyPair),
          SolContract(
            address: Token2022Program.programId,
            name: 'Test token',
            symbol: 'TEST',
            decimals: 6,
          ),
          db,
        );
        final amount = Amount(rawValue: BigInt.one, fractionDigits: 6);
        final prepared = wallet.prepareSend(
          txData: TxData(
            recipients: [
              TxRecipient(
                address: SystemProgram.programId,
                amount: amount,
                isChange: false,
                addressType: AddressType.solana,
              ),
            ],
            memo: 'token memo',
          ),
        );
        if (program == SystemProgram.programId) {
          await expectLater(
            prepared,
            throwsA(
              isA<Exception>().having(
                (error) => error.toString(),
                'message',
                contains('Unsupported token program'),
              ),
            ),
          );
          expect(mintLookupCount, 0);
          return;
        }
        final result = await prepared;
        expect(mintLookupCount, 0);
        expect(result.solInstructions!.last.programId.toBase58(), program);
        if (scenario.recipientExists) {
          expect(result.solInstructions, hasLength(1));
          expect(
            result.solInstructions!.last.accounts[2].pubKey.toBase58(),
            AssociatedTokenAccountProgram.programId,
          );
        } else {
          final creation = result.solInstructions!.first;
          expect(creation.accounts[5].pubKey.toBase58(), program);
          final expectedAddress = await Ed25519HDPublicKey.findProgramAddress(
            seeds: [
              Ed25519HDPublicKey.fromBase58(SystemProgram.programId).bytes,
              Ed25519HDPublicKey.fromBase58(program).bytes,
              Ed25519HDPublicKey.fromBase58(Token2022Program.programId).bytes,
            ],
            programId: AssociatedTokenAccountProgram.id,
          );
          expect(
            creation.accounts[1].pubKey.toBase58(),
            expectedAddress.toBase58(),
          );
        }
        // A trailing instruction must not change which program the pending
        // record derives the recipient account from.
        final sending = scenario.recipientExists
            ? [
                ...result.solInstructions!,
                MemoInstruction(signers: const [], memo: 'trailing'),
              ]
            : result.solInstructions!;
        final confirmation = wallet.confirmSend(
          txData: result.copyWith(solInstructions: sending),
        );
        if (scenario.failed) {
          await expectLater(
            confirmation,
            throwsA(
              isA<Exception>().having(
                (error) => error.toString(),
                'message',
                contains('Transaction failed'),
              ),
            ),
          );
          expect(
            isar.transactionV2s.countSync(),
            0,
            reason: 'A definitive on-chain failure must not leave a pending transfer',
          );
        } else {
          final confirmed = await confirmation;
          expect(confirmed.txids, [sentTransaction!.id]);
        }
        expect(mintLookupCount, 0);
        expect(statusLookupCount, retryStatusLookup ? 2 : 1);
        expect(sentTransaction!.signatures, hasLength(1));
        final signedInstructions = sentTransaction!
            .decompileMessage()
            .instructions;
        expect(signedInstructions.first.programId, MemoProgram.id);
        expect(signedInstructions, hasLength(sending.length + 1));
        for (var i = 0; i < sending.length; i++) {
          final expected = sending[i];
          final actual = signedInstructions[i + 1];
          expect(actual.programId, expected.programId);
          expect(actual.data.toList(), expected.data.toList());
          expect(
            actual.accounts.map((e) => e.pubKey),
            expected.accounts.map((e) => e.pubKey),
          );
        }
        if (!scenario.failed) {
          expect(
            isar.transactionV2s
                .where()
                .findAllSync()
                .single
                .outputs
                .single
                .addresses,
            [
              signedInstructions[result.solInstructions!.length]
                  .accounts[2]
                  .pubKey
                  .toBase58(),
            ],
          );
        }
      },
    );
  }
}
