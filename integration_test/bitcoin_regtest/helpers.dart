import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/input.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_wallet.dart';

import 'regtest_chain.dart';
import 'stack_env.dart';

/// One regtest chain and one Stack environment for a test file, set up once
/// and always torn down, nodes last.
class RegtestFixture {
  RegtestFixture() {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    setUpAll(() async {
      chain = _chain = await RegtestChain.start();
      env = _env = await StackEnv.open(chain);
    });
    tearDownAll(() async {
      try {
        await _env?.close();
      } finally {
        await _chain?.stop();
      }
    });
  }

  late RegtestChain chain;
  late StackEnv env;
  RegtestChain? _chain;
  StackEnv? _env;

  /// Call first in a test: a failure then prints the app and node logs.
  void dumpLogsOnFailure() => addTearDown(() {
    printOnFailure('--- app log\n${env.logTail()}');
    printOnFailure('--- bitcoind and ${chain.indexer}\n${chain.logTail}');
  });

  /// Pays [btc] from the node to [wallet], mines it and syncs the wallet.
  Future<String> fund(BitcoinWallet wallet, String btc) async {
    final txid = await chain.pay(await receivingAddress(wallet), btc);
    await chain.mine(1);
    await wallet.refresh();
    return txid;
  }

  /// bitcoind's mempool entry for [txid].
  Future<Map<String, dynamic>> mempoolEntry(String txid) async =>
      Map<String, dynamic>.from(
        await chain.rpc('getmempoolentry', [txid]) as Map,
      );
}

BigInt sats(String btc) {
  final parts = btc.split('.');
  final frac = parts.length > 1 ? parts[1] : '';
  return BigInt.parse(parts[0]) * BigInt.from(100000000) +
      BigInt.parse(frac.padRight(8, '0'));
}

BigInt btcToSats(num btc) => BigInt.from((btc * 1e8).round());

Future<String> receivingAddress(BitcoinWallet wallet) async =>
    (await wallet.getCurrentReceivingAddress())!.value;

Future<List<TransactionV2>> history(BitcoinWallet wallet) => MainDB
    .instance
    .isar
    .transactionV2s
    .where()
    .walletIdEqualTo(wallet.walletId)
    .findAll();

/// Builds, signs and broadcasts through the same calls the send view makes.
/// [utxos] is the send view's coin control selection.
Future<TxData> send(
  BitcoinWallet from,
  String to,
  String btc, {
  required int satsPerVByte,
  Set<BaseInput>? utxos,
}) async {
  final prepared = await from.prepareSend(
    txData: TxData(
      recipients: [
        TxRecipient(
          address: to,
          amount: Amount(rawValue: sats(btc), fractionDigits: 8),
          isChange: false,
          addressType: from.cryptoCurrency.getAddressType(to)!,
        ),
      ],
      feeRateType: FeeRateType.custom,
      satsPerVByte: satsPerVByte,
      utxos: utxos,
    ),
  );
  return from.confirmSend(txData: prepared);
}
