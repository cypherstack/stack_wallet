import 'dart:convert';
import 'dart:typed_data';

import 'package:isar_community/isar.dart';
import 'package:mutex/mutex.dart';
import 'package:wallet/wallet.dart' as eth;
import 'package:web3dart/json_rpc.dart' show RPCError;
import 'package:web3dart/web3dart.dart' as web3;

import '../../../db/hive/db.dart';
import '../../../exceptions/electrumx/no_such_transaction.dart';
import '../../../exceptions/exchange/exchange_exception.dart';
import '../../../exceptions/json_rpc/json_rpc_exception.dart';
import '../../../models/exchange/response_objects/trade.dart';
import '../../../models/input.dart';
import '../../../models/isar/models/ethereum/eth_contract.dart';
import '../../../models/trade_wallet_lookup.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/default_eth_tokens.dart';
import '../../../utilities/enums/fee_rate_type_enum.dart';
import '../../../utilities/extensions/extensions.dart';
import '../../../utilities/logger.dart';
import '../../../wallets/crypto_currency/crypto_currency.dart';
import '../../../wallets/models/tx_data.dart';
import '../../../wallets/wallet/impl/ethereum_wallet.dart';
import '../../../wallets/wallet/impl/firo_wallet.dart';
import '../../../wallets/wallet/impl/sub_wallets/eth_token_wallet.dart';
import '../../../wallets/wallet/wallet.dart';
import '../../../wallets/wallet/wallet_mixin_interfaces/firo_op_return.dart';
import 'rosen_api.dart';
import 'rosen_exchange.dart';
import 'rosen_protocol.dart';

enum _FundingConflict { none, pending, confirmed, exact, unknown }

/// Bridge transactions retain the normal swap confirmation and wallet signing.
class RosenFunding {
  static const fundingKey = 'funding';
  static const submittingState = 'submitting';
  static const broadcastState = 'broadcast';
  static const needsAttentionState = 'needsAttention';
  static const failedState = 'failed';
  static final Map<String, Mutex> _walletLocks = {};

  static Future<void> _saveFundingLookup({
    required Trade trade,
    required String walletId,
    required String txid,
  }) => DB.instance.hive
      .box<TradeWalletLookup>(DB.boxNameTradeLookup)
      .put(
        trade.uuid,
        TradeWalletLookup(
          uuid: trade.uuid,
          txid: txid,
          tradeId: trade.tradeId,
          walletIds: [walletId],
        ),
      );

  static CryptoCurrency sourceCoin(Trade trade) => RosenExchange.isFiro(trade)
      ? Firo(CryptoCurrencyNetwork.main)
      : Ethereum(CryptoCurrencyNetwork.main);

  static bool canFund(Wallet wallet, Trade trade) =>
      !wallet.info.isViewOnly &&
      wallet.cryptoCurrency == sourceCoin(trade) &&
      (RosenExchange.isFiro(trade)
          ? wallet is FiroWallet
          : wallet is EthereumWallet);

  static EthContract _tokenFor(Wallet wallet) => DefaultTokens.rsFiro.copyWith(
    id: Isar.autoIncrement,
    address: wallet.info.tokenContractAddresses.firstWhere(
      (address) => address.toLowerCase() == DefaultTokens.rsFiro.address,
      orElse: () => DefaultTokens.rsFiro.address,
    ),
  );

  static Future<void> registerToken(Wallet wallet) async {
    if (wallet is! EthereumWallet ||
        wallet.cryptoCurrency.network != CryptoCurrencyNetwork.main) {
      throw StateError('rsFIRO requires an Ethereum mainnet wallet.');
    }
    final token = _tokenFor(wallet);
    final stored = await wallet.mainDB
        .getEthContracts()
        .filter()
        .addressEqualTo(token.address, caseSensitive: false)
        .findFirst();
    if (stored == null) await wallet.mainDB.putEthContract(token);
    if (!wallet.info.tokenContractAddresses.any(
      (address) => address.toLowerCase() == DefaultTokens.rsFiro.address,
    )) {
      await wallet.updateTokenContracts([
        ...wallet.info.tokenContractAddresses,
        stored?.address ?? token.address,
      ]);
    }
  }

  static Future<void> _validatePendingTransfer(
    web3.Web3Client client,
    eth.EthereumAddress sender,
    eth.EthereumAddress contract,
    Uint8List data,
  ) async {
    final result = await client.callRaw(
      sender: sender,
      contract: contract,
      data: data,
      atBlock: const web3.BlockNum.pending(),
    );
    if (RosenProtocol.tokenContract
            .function('transfer')
            .decodeReturnValues(result)
            .single !=
        true) {
      throw StateError('The pending rsFIRO transfer would fail.');
    }
  }

  /// Save the exact signed transaction before making the network request.
  static Future<void> recordFundingIntent({
    required Trade trade,
    required String walletId,
    required String txid,
    required String raw,
    int? nonce,
    int? sourceHeight,
    List<Map<String, Object>>? firoInputs,
  }) async {
    if (!RosenProtocol.isTransactionId(txid)) {
      throw StateError('The wallet created an invalid transaction ID.');
    }
    txid = txid.toLowerCase();
    if (raw.isEmpty ||
        raw.length.isOdd ||
        !RegExp(r'^(0x)?[0-9a-fA-F]+$').hasMatch(raw)) {
      throw StateError('The wallet created an invalid signed transaction.');
    }
    raw = raw.toLowerCase();
    final db = DB.instance;
    await db.mutex.protect(() async {
      final trades = db.hive.box<Trade>(DB.boxNameTradesV2);
      final current = trades.get(trade.uuid);
      if (current == null) {
        throw StateError('This Rosen swap is no longer available.');
      }
      final data = jsonDecode(current.other!) as Map<String, dynamic>;
      final funding = data[fundingKey];
      if (current.payInTxid.isEmpty) {
        RosenExchange.currentUnfunded(trade);
        await trades.put(
          current.uuid,
          current.copyWith(
            payInTxid: txid,
            status: 'Confirming',
            updatedAt: DateTime.now(),
            other: jsonEncode({
              ...data,
              fundingKey: {
                'walletId': walletId,
                'txid': txid,
                'raw': raw,
                'state': submittingState,
                if (nonce != null) 'nonce': nonce,
                if (sourceHeight != null) 'height': sourceHeight,
                if (firoInputs != null) 'inputs': firoInputs,
              },
            }),
          ),
        );
      } else if (current.payInTxid != txid ||
          funding is! Map ||
          funding['walletId'] != walletId ||
          funding['txid'] != txid ||
          funding['raw'] != raw) {
        throw StateError('This Rosen swap already has another deposit.');
      }
      try {
        await _saveFundingLookup(
          trade: current,
          walletId: walletId,
          txid: txid,
        );
      } catch (e, s) {
        Logging.instance.e(
          'Rosen funding lookup will be repaired during recovery',
          error: e,
          stackTrace: s,
        );
      }
    });
  }

  static Map<String, dynamic>? _funding(Trade trade) {
    final value =
        (jsonDecode(trade.other!) as Map<String, dynamic>)[fundingKey];
    if (value == null) return null;
    if (value is! Map) {
      throw const FormatException('Invalid Rosen funding journal.');
    }
    final funding = Map<String, dynamic>.from(value);
    final state = funding['state'];
    if (state != submittingState &&
        state != broadcastState &&
        state != needsAttentionState &&
        state != failedState) {
      throw const FormatException('Invalid Rosen funding journal state.');
    }
    return funding;
  }

  static String? fundingWalletId(Trade trade) {
    final funding = _funding(trade);
    return funding == null ||
            {broadcastState, failedState}.contains(funding['state'])
        ? null
        : funding['walletId'] as String?;
  }

  static bool needsAttention(Trade trade) =>
      _funding(trade)?['state'] == needsAttentionState;

  static bool _requiresAttention(Object error) {
    final message = switch (error) {
      JsonRpcException() => error.message,
      RPCError() => '${error.message} ${error.data ?? ''}',
      _ => '',
    }.toLowerCase();
    return const [
      'transaction was rejected by network rules',
      'bad-txns',
      'mandatory-script-verify',
      'non-mandatory-script-verify',
      'nonce too low',
      'invalid sender',
      'intrinsic gas too low',
      'replacement transaction underpriced',
      'already known',
    ].any(message.contains);
  }

  static bool _historicalDataUnavailable(RPCError error) {
    final message = '${error.message} ${error.data ?? ''}'.toLowerCase();
    return const [
      'missing trie node',
      'state unavailable',
      'state is unavailable',
      'state not available',
      'state is not available',
      'no state available',
      'history has been pruned',
      'history is pruned',
      'history pruned',
      'block body unavailable',
      'block body is unavailable',
      'block body not available',
      'block body is not available',
    ].any(message.contains);
  }

  static Future<_FundingConflict> _fundingConflict({
    required Wallet wallet,
    required Map<String, dynamic> funding,
    required String txid,
  }) async {
    if (wallet is FiroWallet) {
      final savedInputs = funding['inputs'];
      if (savedInputs == null) return _FundingConflict.none;
      if (savedInputs is! List) {
        throw const FormatException('Invalid FIRO funding inputs.');
      }
      final inputs = <({String txid, int vout, String scripthash})>[];
      for (final entry in savedInputs) {
        if (entry is! Map ||
            entry['txid'] is! String ||
            entry['vout'] is! int ||
            entry['scripthash'] is! String) {
          throw const FormatException('Invalid FIRO funding input.');
        }
        inputs.add((
          txid: (entry['txid'] as String).toLowerCase(),
          vout: entry['vout'] as int,
          scripthash: entry['scripthash'] as String,
        ));
      }
      final height = await wallet.fetchChainHeight();
      final seen = <String>{};
      var result = _FundingConflict.none;
      for (final scripthash
          in inputs.map((input) => input.scripthash).toSet()) {
        final history = await wallet.electrumXClient.getHistory(
          scripthash: scripthash,
        );
        for (final item in history) {
          final candidate = item['tx_hash'];
          final blockHeight = item['height'];
          if (candidate is! String || blockHeight is! int) {
            continue;
          }
          if (!RosenProtocol.isTransactionId(candidate)) {
            throw const FormatException('Invalid FIRO transaction history.');
          }
          if (!seen.add(candidate.toLowerCase())) continue;
          final response = await wallet.electrumXClient.request(
            command: 'blockchain.transaction.get',
            args: [candidate, false],
          );
          if (response is! String) {
            throw const FormatException('Invalid FIRO transaction response.');
          }
          final decoded = decodeFiroTransaction(response);
          if (decoded.txid.toLowerCase() != candidate.toLowerCase()) {
            throw const FormatException('FIRO transaction hash mismatch.');
          }
          if (candidate.toLowerCase() == txid.toLowerCase()) {
            return _FundingConflict.exact;
          }
          final spendsSavedInput = decoded.prevouts.any(
            (prevout) => inputs.any(
              (input) =>
                  input.txid == prevout.txid.toLowerCase() &&
                  input.vout == prevout.vout,
            ),
          );
          if (spendsSavedInput) {
            if (blockHeight > 0 &&
                height - blockHeight + 1 >= RosenApi.firoConfirmationWindow) {
              return _FundingConflict.confirmed;
            }
            result = _FundingConflict.pending;
          }
        }
      }
      return result;
    }

    final nonce = funding['nonce'];
    final sourceHeight = funding['height'];
    if (nonce is! int || sourceHeight is! int || sourceHeight < 0) {
      return _FundingConflict.none;
    }
    final ethereum = wallet as EthereumWallet;
    final client = ethereum.getEthClient();
    try {
      final sender = await ethereum.getMyWeb3Address();
      Future<_FundingConflict> pendingOrNone() async =>
          await client.getTransactionCount(
                sender,
                atBlock: const web3.BlockNum.pending(),
              ) >
              nonce
          ? _FundingConflict.pending
          : _FundingConflict.none;
      final height = await client.getBlockNumber();
      final safeHeight = height - RosenApi.ethereumConfirmationWindow + 1;
      if (safeHeight < sourceHeight) return await pendingOrNone();
      Future<int> countAt(int height) => client.getTransactionCount(
        sender,
        atBlock: web3.BlockNum.exact(height),
      );
      if (await countAt(safeHeight) <= nonce) return await pendingOrNone();

      var low = sourceHeight >= RosenApi.ethereumConfirmationWindow - 1
          ? sourceHeight - RosenApi.ethereumConfirmationWindow + 1
          : 0;
      var high = safeHeight;
      try {
        while (low < high) {
          final middle = (low + high) ~/ 2;
          if (await countAt(middle) > nonce) {
            high = middle;
          } else {
            low = middle + 1;
          }
        }
      } on RPCError catch (error) {
        if (_historicalDataUnavailable(error)) {
          return _FundingConflict.unknown;
        }
        rethrow;
      }
      final blockNumber = '0x${low.toRadixString(16)}';
      late final Map<String, dynamic> block;
      try {
        block = await client.makeRPCCall<Map<String, dynamic>>(
          'eth_getBlockByNumber',
          [blockNumber, true],
        );
      } on RPCError catch (error) {
        if (_historicalDataUnavailable(error)) {
          return _FundingConflict.unknown;
        }
        rethrow;
      }
      final transactions = block['transactions'];
      if (block['number'] != blockNumber ||
          transactions is! List ||
          transactions.isEmpty) {
        throw const FormatException('Invalid Ethereum block response.');
      }
      for (final value in transactions) {
        if (value is! Map || value['from'] is! String) {
          throw const FormatException('Invalid Ethereum block response.');
        }
        final valueNonce = value['nonce'];
        if (valueNonce is! String ||
            !RegExp(r'^0x[0-9a-fA-F]+$').hasMatch(valueNonce)) {
          throw const FormatException('Invalid Ethereum transaction nonce.');
        }
        final hash = value['hash'];
        if (hash is! String || !RosenProtocol.isTransactionId(hash)) {
          throw const FormatException('Invalid Ethereum transaction response.');
        }
        if ((value['from'] as String).toLowerCase() !=
                sender.with0x.toLowerCase() ||
            int.parse(valueNonce.substring(2), radix: 16) != nonce) {
          continue;
        }
        return hash.toLowerCase() == txid.toLowerCase()
            ? _FundingConflict.exact
            : _FundingConflict.confirmed;
      }
      return _FundingConflict.confirmed;
    } finally {
      await client.dispose();
    }
  }

  static Future<Trade> _markFundingState({
    required Trade trade,
    required String walletId,
    required String txid,
    required String raw,
    required String state,
    String? reason,
  }) async {
    final db = DB.instance;
    return db.mutex.protect(() async {
      final trades = db.hive.box<Trade>(DB.boxNameTradesV2);
      final current = trades.get(trade.uuid);
      if (current == null) {
        throw StateError('This Rosen swap is no longer available.');
      }
      final data = jsonDecode(current.other!) as Map<String, dynamic>;
      final funding = _funding(current);
      if (current.payInTxid.toLowerCase() != txid.toLowerCase() ||
          funding == null ||
          funding['walletId'] != walletId ||
          funding['txid'] != txid ||
          funding['raw'] != raw) {
        throw StateError('The Rosen funding journal changed.');
      }
      await _saveFundingLookup(trade: current, walletId: walletId, txid: txid);
      final terminal = {
        'finished',
        'failed',
      }.contains(current.status.toLowerCase());
      final progressed = {
        'exchanging',
        'sending',
      }.contains(current.status.toLowerCase());
      final status = terminal || (state == broadcastState && progressed)
          ? current.status
          : state == broadcastState
          ? 'Confirming'
          : state == failedState
          ? 'Failed'
          : 'Verifying';
      final sameReason =
          state != needsAttentionState || funding['reason'] == reason;
      if (funding['state'] == broadcastState ||
          (funding['state'] == state &&
              current.status == status &&
              sameReason)) {
        return current;
      }
      final updatedFunding = <String, dynamic>{...funding, 'state': state};
      if (state == needsAttentionState) {
        updatedFunding['reason'] = reason;
      } else {
        updatedFunding.remove('reason');
      }
      final updated = current.copyWith(
        status: status,
        updatedAt: terminal ? current.updatedAt : DateTime.now(),
        other: jsonEncode({...data, fundingKey: updatedFunding}),
      );
      await trades.put(current.uuid, updated);
      return updated;
    });
  }

  static Future<Trade> _recoverFundingIntent({
    required Wallet wallet,
    required Trade trade,
  }) async {
    final current = DB.instance.get<Trade>(
      boxName: DB.boxNameTradesV2,
      key: trade.uuid,
    );
    if (current == null) {
      throw StateError('This Rosen swap is no longer available.');
    }
    final funding = _funding(current);
    if (funding == null || funding['state'] == broadcastState) return current;
    final walletId = funding['walletId'];
    final txid = funding['txid'];
    final raw = funding['raw'];
    if (walletId is! String ||
        txid is! String ||
        raw is! String ||
        wallet.walletId != walletId ||
        !canFund(wallet, current) ||
        current.payInTxid.toLowerCase() != txid.toLowerCase() ||
        !RosenProtocol.isTransactionId(txid)) {
      throw const FormatException('Invalid Rosen funding journal.');
    }
    Future<Trade> mark(String state, {String? reason}) => _markFundingState(
      trade: current,
      walletId: walletId,
      txid: txid,
      raw: raw,
      state: state,
      reason: reason,
    );
    if (wallet is EthereumWallet) {
      final client = wallet.getEthClient();
      try {
        if (await client.getChainId() != BigInt.one) {
          throw StateError('The Ethereum node must use mainnet.');
        }
      } finally {
        await client.dispose();
      }
    }

    Future<bool> transactionExists() async {
      if (wallet is FiroWallet) {
        try {
          final found = await wallet.electrumXClient.request(
            command: 'blockchain.transaction.get',
            args: [txid, false],
          );
          if (found is! String ||
              firoTransactionFromHex(found).txid.toLowerCase() !=
                  txid.toLowerCase()) {
            throw StateError('FIRO node returned another transaction.');
          }
          return true;
        } on NoSuchTransactionException {
          return false;
        }
      }
      final client = (wallet as EthereumWallet).getEthClient();
      try {
        final transaction = await client.getTransactionByHash(txid);
        if (transaction != null &&
            transaction.hash.toLowerCase() != txid.toLowerCase()) {
          throw StateError('Ethereum node returned another transaction.');
        }
        if (transaction != null) return true;
        final receipt = await client.getTransactionReceipt(txid);
        if (receipt == null) return false;
        if (web3
                .bytesToHex(receipt.transactionHash, include0x: true)
                .toLowerCase() !=
            txid.toLowerCase()) {
          throw StateError('Ethereum node returned another receipt.');
        }
        return true;
      } finally {
        await client.dispose();
      }
    }

    if (funding['state'] == failedState) return current;
    if (await transactionExists()) {
      return mark(broadcastState);
    }
    final conflict = await _fundingConflict(
      wallet: wallet,
      funding: funding,
      txid: txid,
    );
    if (conflict == _FundingConflict.exact) {
      return mark(broadcastState);
    }
    if (conflict == _FundingConflict.confirmed) {
      if (!await transactionExists()) {
        return mark(failedState);
      }
      return mark(broadcastState);
    }
    if (conflict == _FundingConflict.unknown && await transactionExists()) {
      return mark(broadcastState);
    }
    if (conflict == _FundingConflict.pending ||
        conflict == _FundingConflict.unknown) {
      if (funding['state'] != needsAttentionState) {
        await mark(needsAttentionState, reason: 'conflict');
      }
      throw StateError(
        conflict == _FundingConflict.pending
            ? 'Another transaction is using the saved Rosen deposit funds.'
            : 'The saved Rosen deposit could not be verified.',
      );
    }
    if (funding['state'] == needsAttentionState) {
      if (!{'fees', 'conflict'}.contains(funding['reason'])) {
        throw StateError(
          'This Rosen deposit needs attention and will not be rebroadcast.',
        );
      }
    }

    final int sourceHeight;
    if (wallet is FiroWallet) {
      sourceHeight = await wallet.fetchChainHeight();
    } else {
      final client = (wallet as EthereumWallet).getEthClient();
      try {
        sourceHeight = await client.getBlockNumber();
      } finally {
        await client.dispose();
      }
    }
    try {
      await RosenExchange.validateFundingRecovery(
        current,
        sourceHeight: sourceHeight,
      );
    } on ExchangeException catch (e) {
      if (e.type != ExchangeExceptionType.quoteChanged) rethrow;
      await mark(needsAttentionState, reason: 'fees');
      throw StateError(
        'Rosen fees changed before the saved deposit could be submitted.',
      );
    }

    String response;
    try {
      if (wallet is FiroWallet) {
        if (firoTransactionFromHex(raw).txid.toLowerCase() !=
            txid.toLowerCase()) {
          throw const FormatException('FIRO funding journal hash mismatch.');
        }
        response = await wallet.electrumXClient.broadcastTransaction(
          rawTx: raw,
        );
      } else {
        final bytes = raw.toUint8ListFromHex;
        if (web3
                .bytesToHex(web3.keccak256(bytes), include0x: true)
                .toLowerCase() !=
            txid.toLowerCase()) {
          throw const FormatException(
            'Ethereum funding journal hash mismatch.',
          );
        }
        final client = (wallet as EthereumWallet).getEthClient();
        try {
          response = await client.sendRawTransaction(bytes);
        } finally {
          await client.dispose();
        }
      }
    } catch (e) {
      if (await transactionExists()) {
        return mark(broadcastState);
      }
      if (_requiresAttention(e)) {
        await mark(needsAttentionState, reason: 'rejected');
        throw StateError('The saved Rosen deposit was rejected.');
      }
      if (e is FormatException) {
        await mark(needsAttentionState, reason: 'invalid');
        throw StateError(
          'The saved Rosen deposit is invalid and needs attention.',
        );
      }
      rethrow;
    }
    if (response.toLowerCase() != txid.toLowerCase() &&
        !await transactionExists()) {
      await mark(needsAttentionState, reason: 'unexpectedResponse');
      throw StateError('The node returned an unexpected transaction ID.');
    }
    return mark(broadcastState);
  }

  static Future<Trade> recoverFundingIntent({
    required Wallet wallet,
    required Trade trade,
  }) => _walletLocks
      .putIfAbsent(wallet.walletId, Mutex.new)
      .protect(() => _recoverFundingIntent(wallet: wallet, trade: trade));

  static Future<void> _recoverOtherFunding({
    required Wallet wallet,
    required String tradeUuid,
  }) async {
    for (final trade in DB.instance.values<Trade>(
      boxName: DB.boxNameTradesV2,
    )) {
      if (trade.uuid != tradeUuid &&
          trade.exchangeName == RosenExchange.exchangeName &&
          fundingWalletId(trade) == wallet.walletId) {
        try {
          await _recoverFundingIntent(wallet: wallet, trade: trade);
        } catch (e, s) {
          Logging.instance.e(
            'A previous Rosen deposit is still pending submission',
            error: e,
            stackTrace: s,
          );
          throw StateError(
            'A previous Rosen deposit from this wallet is still being '
            'submitted.',
          );
        }
      }
    }
  }

  static Future<Trade> refreshTrade({
    required Wallet wallet,
    required Trade trade,
  }) async {
    // Refresh the persisted request if this screen holds an old quote.
    final current = RosenExchange.currentUnfunded(trade);
    RosenExchange.validatedMetadata(current);
    if (!canFund(wallet, current)) {
      throw StateError('Choose a spendable wallet on the source network.');
    }
    final int height;
    if (wallet is FiroWallet) {
      height = await wallet.fetchChainHeight();
    } else {
      final ethereum = wallet as EthereumWallet;
      if (ethereum.prefs.useTor) {
        throw StateError('Ethereum bridge funding is unavailable over Tor.');
      }
      final client = ethereum.getEthClient();
      try {
        if (await client.getChainId() != BigInt.one) {
          throw StateError('The Ethereum node must use mainnet.');
        }
        height = await client.getBlockNumber();
      } finally {
        await client.dispose();
      }
    }
    final quote = await RosenApi.instance.quote(
      fromFiro: RosenExchange.isFiro(current),
      amount: RosenProtocol.parseAmount(current.payInAmount),
      sourceHeight: height,
    );
    return RosenExchange.saveRefreshedTrade(current, quote);
  }

  static Future<TxData> prepareSend({
    required Wallet wallet,
    required Trade trade,
  }) async {
    if (!canFund(wallet, trade)) {
      throw StateError('Choose a spendable wallet on the source network.');
    }
    final metadata = RosenExchange.validatedMetadata(trade);
    final amount = Amount(
      rawValue: RosenProtocol.parseAmount(trade.payInAmount),
      fractionDigits: DefaultTokens.rsFiro.decimals,
    );
    final data = TxData(
      recipients: [
        TxRecipient(
          address: trade.payInAddress,
          amount: amount,
          isChange: false,
          addressType: wallet.cryptoCurrency.getAddressType(
            trade.payInAddress,
          )!,
        ),
      ],
      feeRateType: FeeRateType.average,
    );
    if (wallet is FiroWallet) {
      await RosenExchange.validateFunding(
        trade,
        sourceHeight: await wallet.fetchChainHeight(),
      );
      final prepared = await wallet.prepareSend(
        txData: data.copyWith(opReturnData: metadata),
      );
      // Transparent send-all subtracts the fee; the deposit must stay exact.
      if (prepared.amountWithoutChange != amount) {
        throw StateError(
          'Leave enough transparent FIRO to pay the mining fee.',
        );
      }
      return prepared;
    }

    final ethereum = wallet as EthereumWallet;
    if (ethereum.prefs.useTor) {
      throw StateError('Ethereum bridge funding is unavailable over Tor.');
    }
    final client = ethereum.getEthClient();
    try {
      final sender = await ethereum.getMyWeb3Address();
      final prep = await ethereum.internalSharedPrepareSend(
        txData: data,
        myWeb3Address: sender,
      );
      if (prep.chainId != BigInt.one) {
        throw StateError('The Ethereum node must use mainnet.');
      }
      await RosenExchange.validateFunding(
        trade,
        sourceHeight: await client.getBlockNumber(),
      );
      final contract = RosenProtocol.tokenContract;
      final decimals = await client.call(
        contract: contract,
        function: contract.function('decimals'),
        params: [],
      );
      if (decimals.single != BigInt.from(DefaultTokens.rsFiro.decimals)) {
        throw StateError('Unexpected rsFIRO token precision.');
      }
      final calldata = RosenProtocol.transferData(
        lockAddress: RosenApi.ethereumLockAddress,
        amount: amount.raw,
        metadata: metadata,
      ).toUint8ListFromHex;
      final tokenAddress = eth.EthereumAddress.fromHex(
        DefaultTokens.rsFiro.address,
      );
      await _validatePendingTransfer(client, sender, tokenAddress, calldata);
      final gas = await client.estimateGas(
        sender: sender,
        to: tokenAddress,
        data: calldata,
      );
      final gasLimit =
          (gas * BigInt.from(120) + BigInt.from(99)) ~/ BigInt.from(100);
      final maxFee = prep.maxFeePerGas;
      final fee = Amount(rawValue: gasLimit * maxFee, fractionDigits: 18);
      final ethBalance = await client.getBalance(
        sender,
        atBlock: const web3.BlockNum.pending(),
      );
      if (ethBalance.getInWei < fee.raw) {
        throw StateError('Insufficient ETH for the bridge transaction gas.');
      }
      await registerToken(ethereum);
      return data.copyWith(
        fee: fee,
        chainId: prep.chainId,
        nonce: prep.nonce,
        web3dartTransaction: web3.Transaction(
          to: tokenAddress,
          data: calldata,
          value: eth.EtherAmount.zero(),
          maxGas: gasLimit.toInt(),
          nonce: prep.nonce,
          maxFeePerGas: eth.EtherAmount.inWei(maxFee),
          maxPriorityFeePerGas: eth.EtherAmount.inWei(
            prep.maxPriorityFeePerGas,
          ),
        ),
      );
    } finally {
      await client.dispose();
    }
  }

  static Future<TxData> confirmSend({
    required Wallet wallet,
    required Trade trade,
    required TxData txData,
  }) async {
    if (!canFund(wallet, trade)) {
      throw StateError('Invalid bridge source wallet.');
    }
    final lock = _walletLocks.putIfAbsent(wallet.walletId, Mutex.new);
    return lock.protect(() async {
      String? intentTxid;
      String? intentRaw;
      String? firoTxid;
      int? ethereumNonce;
      int? fundingHeight;
      List<Map<String, Object>>? firoInputs;
      Future<void> beforeBroadcast(String raw) async {
        final txid =
            firoTxid ??
            web3.bytesToHex(
              web3.keccak256(raw.toUint8ListFromHex),
              include0x: true,
            );
        await recordFundingIntent(
          trade: trade,
          walletId: wallet.walletId,
          txid: txid,
          raw: raw,
          nonce: ethereumNonce,
          sourceHeight: fundingHeight,
          firoInputs: firoInputs,
        );
        intentTxid = txid;
        intentRaw = raw.toLowerCase();
      }

      try {
        await _recoverOtherFunding(wallet: wallet, tradeUuid: trade.uuid);
        final current = RosenExchange.currentUnfunded(trade);
        if (!canFund(wallet, current)) {
          throw StateError('Invalid bridge source wallet.');
        }
        final metadata = RosenExchange.validatedMetadata(current);
        final amount = RosenProtocol.parseAmount(current.payInAmount);
        if (txData.amountWithoutChange?.raw != amount ||
            txData.recipients?.where((e) => !e.isChange).length != 1 ||
            txData.recipients!.firstWhere((e) => !e.isChange).address !=
                current.payInAddress) {
          throw StateError('The transaction does not match this bridge swap.');
        }

        TxData sent;
        if (wallet is FiroWallet) {
          if (txData.opReturnData != metadata) {
            throw StateError('Missing Rosen OP_RETURN.');
          }
          final inputs = txData.usedUTXOs;
          if (inputs == null ||
              inputs.isEmpty ||
              inputs.any((input) => input is! StandardInput) ||
              txData.fee == null) {
            throw StateError('Invalid FIRO bridge transaction.');
          }
          final standardInputs = inputs.cast<StandardInput>();
          firoTxid = verifyFiroOpReturnTransaction(
            raw: txData.raw ?? '',
            data: metadata,
            expectedInputs: standardInputs.map(
              (input) => (
                txid: input.utxo.txid,
                vout: input.utxo.vout,
                value: input.value,
              ),
            ),
            expectedOutputs: txData.recipients!.map(
              (output) => (
                script: RosenProtocol.firoScript(output.address),
                value: output.amount.raw,
              ),
            ),
            expectedFee: txData.fee!.raw,
          );
          fundingHeight = await wallet.fetchChainHeight();
          await RosenExchange.validateFunding(
            current,
            sourceHeight: fundingHeight,
          );
          final available = <String, BigInt>{};
          for (final address in standardInputs.map((e) => e.address).toSet()) {
            if (address == null) {
              throw StateError('Invalid FIRO bridge transaction input.');
            }
            final utxos = await wallet.electrumXClient.getUTXOs(
              scripthash: wallet.cryptoCurrency.addressToScriptHash(
                address: address,
              ),
            );
            for (final utxo in utxos) {
              final value = BigInt.tryParse(utxo['value'].toString());
              if (value == null) {
                throw StateError('Invalid FIRO transaction input value.');
              }
              available['${utxo['tx_hash'].toString().toLowerCase()}:'
                      '${utxo['tx_pos']}'] =
                  value;
            }
          }
          if (standardInputs.any((input) {
            final key = '${input.utxo.txid.toLowerCase()}:${input.utxo.vout}';
            return available[key] != input.value;
          })) {
            throw StateError(
              'The FIRO transaction inputs changed. Prepare this swap again.',
            );
          }
          firoInputs = standardInputs
              .map(
                (input) => <String, Object>{
                  'txid': input.utxo.txid.toLowerCase(),
                  'vout': input.utxo.vout,
                  'scripthash': wallet.cryptoCurrency.addressToScriptHash(
                    address: input.address!,
                  ),
                },
              )
              .toList();
          sent = await wallet.confirmSend(
            txData: txData,
            beforeBroadcast: beforeBroadcast,
          );
        } else {
          final ethereum = wallet as EthereumWallet;
          if (ethereum.prefs.useTor) {
            throw StateError(
              'Ethereum bridge funding is unavailable over Tor.',
            );
          }
          final tx = txData.web3dartTransaction;
          final expected = RosenProtocol.transferData(
            lockAddress: RosenApi.ethereumLockAddress,
            amount: amount,
            metadata: metadata,
          );
          final maxGas = tx?.maxGas;
          final maxFee = tx?.maxFeePerGas?.getInWei;
          final priorityFee = tx?.maxPriorityFeePerGas?.getInWei;
          if (tx == null ||
              txData.chainId != BigInt.one ||
              tx.to?.with0x.toLowerCase() != DefaultTokens.rsFiro.address ||
              tx.value?.getInWei != BigInt.zero ||
              tx.data?.toHex != expected ||
              tx.gasPrice != null ||
              maxGas == null ||
              maxGas <= 0 ||
              tx.nonce == null ||
              tx.nonce != txData.nonce ||
              maxFee == null ||
              maxFee <= BigInt.zero ||
              priorityFee == null ||
              priorityFee.isNegative ||
              priorityFee > maxFee ||
              txData.fee?.fractionDigits != 18 ||
              txData.fee?.raw != BigInt.from(maxGas) * maxFee) {
            throw StateError('Invalid rsFIRO bridge transaction.');
          }
          ethereumNonce = tx.nonce;
          final client = ethereum.getEthClient();
          try {
            if (await client.getChainId() != BigInt.one) {
              throw StateError('The Ethereum node must use mainnet.');
            }
            fundingHeight = await client.getBlockNumber();
            await RosenExchange.validateFunding(
              current,
              sourceHeight: fundingHeight,
            );
            final sender = await ethereum.getMyWeb3Address();
            if (tx.from != null && tx.from != sender) {
              throw StateError('Invalid rsFIRO bridge transaction sender.');
            }
            if (tx.nonce !=
                await client.getTransactionCount(
                  sender,
                  atBlock: const web3.BlockNum.pending(),
                )) {
              throw StateError(
                'The wallet nonce changed. Prepare this swap again.',
              );
            }
            final ethBalance = await client.getBalance(
              sender,
              atBlock: const web3.BlockNum.pending(),
            );
            if (ethBalance.getInWei < txData.fee!.raw) {
              throw StateError(
                'Insufficient ETH for the bridge transaction gas.',
              );
            }
            await _validatePendingTransfer(client, sender, tx.to!, tx.data!);
          } finally {
            await client.dispose();
          }
          // Record token history and its contract instead of an ETH payment.
          final tokenWallet = Wallet.loadTokenWallet(
            ethWallet: ethereum,
            contract: _tokenFor(wallet),
          ) as EthTokenWallet;
          sent = await tokenWallet.confirmSend(
            txData: txData,
            beforeBroadcast: beforeBroadcast,
          );
        }
        if (intentTxid == null ||
            sent.txid?.toLowerCase() != intentTxid!.toLowerCase()) {
          throw StateError('The broadcast transaction ID changed.');
        }
        await _markFundingState(
          trade: current,
          walletId: wallet.walletId,
          txid: intentTxid!,
          raw: intentRaw!,
          state: broadcastState,
        );
        return sent;
      } catch (e, s) {
        if (intentTxid == null) rethrow;
        String? fundingState;
        try {
          final recovered = await _recoverFundingIntent(
            wallet: wallet,
            trade: trade,
          );
          fundingState = _funding(recovered)?['state'] as String?;
        } catch (recoveryError, recoveryStack) {
          final latest = DB.instance.get<Trade>(
            boxName: DB.boxNameTradesV2,
            key: trade.uuid,
          );
          fundingState = latest == null
              ? null
              : _funding(latest)?['state'] as String?;
          Logging.instance.e(
            'Rosen transaction $intentTxid remains pending recovery',
            error: recoveryError,
            stackTrace: recoveryStack,
          );
        }
        Logging.instance.e(
          'Rosen transaction $intentTxid was recorded before broadcast; '
          'the network or local update result is uncertain',
          error: e,
          stackTrace: s,
        );
        if (fundingState == failedState) {
          throw StateError('The saved Rosen deposit was rejected.');
        }
        if (fundingState == needsAttentionState) {
          throw StateError(
            'The saved Rosen deposit needs attention and was not '
            'rebroadcast.',
          );
        }
        return txData.copyWith(txid: intentTxid, txHash: intentTxid);
      }
    });
  }
}
