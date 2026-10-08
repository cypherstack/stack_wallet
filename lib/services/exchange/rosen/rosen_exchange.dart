import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';

import '../../../db/hive/db.dart';
import '../../../exceptions/exchange/exchange_exception.dart';
import '../../../models/exchange/response_objects/estimate.dart';
import '../../../models/exchange/response_objects/range.dart';
import '../../../models/exchange/response_objects/trade.dart';
import '../../../models/isar/exchange_cache/currency.dart';
import '../../../models/isar/exchange_cache/pair.dart';
import '../../../models/trade_wallet_lookup.dart';
import '../../../utilities/default_eth_tokens.dart';
import '../../ethereum/ethereum_api.dart';
import '../exchange.dart';
import '../exchange_response.dart';
import 'rosen_api.dart';
import 'rosen_protocol.dart';

class RosenExchange extends Exchange {
  RosenExchange._();
  static final instance = RosenExchange._();
  static const exchangeName = 'Rosen Bridge';

  @override
  String get name => exchangeName;
  @override
  bool get supportsRefundAddress => false;
  @override
  bool get supportsExtraId => false;

  static bool isFiro(Trade trade) =>
      trade.payInCurrency.toUpperCase() == 'FIRO';

  static bool _pair(String from, String? fromNet, String to, String? toNet) =>
      (from.toUpperCase() == 'FIRO' &&
          fromNet == 'firo' &&
          to.toUpperCase() == 'RSFIRO' &&
          toNet == 'eth') ||
      (from.toUpperCase() == 'RSFIRO' &&
          fromNet == 'eth' &&
          to.toUpperCase() == 'FIRO' &&
          toNet == 'firo');

  static void _checkPair(
    String from,
    String? fromNet,
    String to,
    String? toNet,
    bool fixed,
    bool reversed,
  ) {
    if (!_pair(from, fromNet, to, toNet) || fixed || reversed) {
      throw const FormatException(
        'Rosen supports estimated FIRO ↔ rsFIRO (Ethereum) swaps using the send amount.',
      );
    }
  }

  Future<ExchangeResponse<T>> _response<T>(Future<T> Function() action) async {
    try {
      return ExchangeResponse(value: await action());
    } catch (e) {
      return ExchangeResponse(
        exception: e is ExchangeException
            ? e
            : ExchangeException(e.toString(), ExchangeExceptionType.generic),
      );
    }
  }

  @override
  Future<ExchangeResponse<List<Currency>>> getAllCurrencies(bool fixedRate) =>
      _response(
        () async => fixedRate
            ? []
            : [
                Currency(
                  exchangeName: name,
                  ticker: 'FIRO',
                  name: 'Firo',
                  network: 'firo',
                  image: '',
                  isFiat: false,
                  rateType: SupportedRateType.estimated,
                  isStackCoin: true,
                  tokenContract: null,
                  isAvailable: true,
                ),
                Currency(
                  exchangeName: name,
                  ticker: DefaultTokens.rsFiro.symbol,
                  name: DefaultTokens.rsFiro.name,
                  network: 'eth',
                  image: '',
                  isFiat: false,
                  rateType: SupportedRateType.estimated,
                  isStackCoin: false,
                  tokenContract: DefaultTokens.rsFiro.address,
                  isAvailable: true,
                ),
              ],
      );

  @override
  Future<ExchangeResponse<Range>> getRange(
    String from,
    String? fromNetwork,
    String to,
    String? toNetwork,
    bool fixedRate,
  ) => _response(() async {
    _checkPair(from, fromNetwork, to, toNetwork, fixedRate, false);
    final quote = await RosenApi.instance.quote(
      fromFiro: from.toUpperCase() == 'FIRO',
      amount: BigInt.zero,
    );
    return Range(
      min: Decimal.parse(RosenProtocol.formatAmount(quote.minimum)),
      max: Decimal.parse(RosenProtocol.formatAmount(RosenProtocol.maxAmount)),
    );
  });

  @override
  Future<ExchangeResponse<List<Estimate>>> getEstimates(
    String from,
    String? fromNetwork,
    String to,
    String? toNetwork,
    Decimal amount,
    bool fixedRate,
    bool reversed,
  ) => _response(() async {
    _checkPair(from, fromNetwork, to, toNetwork, fixedRate, reversed);
    final rawAmount = RosenProtocol.parseAmount(amount.toString());
    final quote = await RosenApi.instance.quote(
      fromFiro: from.toUpperCase() == 'FIRO',
      amount: rawAmount,
    );
    if (rawAmount < quote.minimum || quote.receiveAmount <= BigInt.zero) {
      throw const FormatException('Amount is below the Rosen bridge minimum.');
    }
    return [
      Estimate(
        estimatedAmount: Decimal.parse(
          RosenProtocol.formatAmount(quote.receiveAmount),
        ),
        fixedRate: false,
        reversed: false,
        rateId: '${from.toLowerCase()}:${quote.fingerprint}',
        exchangeProvider: name,
        warningMessage: from.toUpperCase() == 'FIRO'
            ? 'Uses transparent FIRO only. Bridge fees are included; mining fees are additional.'
            : 'Uses rsFIRO on Ethereum. ETH is required for gas; bridge fees are included.',
      ),
    ];
  });

  @override
  Future<ExchangeResponse<Trade>> createTrade({
    required String from,
    required String to,
    required String? fromNetwork,
    required String? toNetwork,
    required bool fixedRate,
    required Decimal amount,
    required String addressTo,
    String? extraId,
    required String addressRefund,
    required String refundExtraId,
    Estimate? estimate,
    required bool reversed,
  }) => _response(() async {
    _checkPair(from, fromNetwork, to, toNetwork, fixedRate, reversed);
    if ((extraId?.isNotEmpty ?? false) ||
        addressRefund.isNotEmpty ||
        refundExtraId.isNotEmpty) {
      throw const FormatException(
        'Rosen does not support memo or refund addresses.',
      );
    }
    final fromFiro = from.toUpperCase() == 'FIRO';
    final rawAmount = RosenProtocol.parseAmount(amount.toString());
    final quote = await RosenApi.instance.quote(
      fromFiro: fromFiro,
      amount: rawAmount,
    );
    if (estimate != null &&
        (estimate.rateId != '${from.toLowerCase()}:${quote.fingerprint}' ||
            quote.receiveAmount <= BigInt.zero ||
            estimate.estimatedAmount !=
                Decimal.parse(
                  RosenProtocol.formatAmount(quote.receiveAmount),
                ))) {
      throw ExchangeException(
        'Rosen fees changed. Refresh the swap quote before continuing.',
        ExchangeExceptionType.quoteChanged,
      );
    }
    if (rawAmount < quote.minimum || quote.receiveAmount <= BigInt.zero) {
      throw const FormatException('Amount is below the Rosen bridge minimum.');
    }
    final receiveAmount = RosenProtocol.formatAmount(quote.receiveAmount);
    final id = const Uuid().v4();
    final now = DateTime.now();
    final trade = Trade(
      uuid: id,
      tradeId: id,
      rateType: 'estimated',
      direction: 'direct',
      timestamp: now,
      updatedAt: now,
      payInCurrency: fromFiro ? 'FIRO' : 'rsFIRO',
      payInAmount: RosenProtocol.formatAmount(rawAmount),
      payInAddress: fromFiro
          ? RosenApi.firoLockAddress
          : RosenApi.ethereumLockAddress,
      payInNetwork: fromNetwork!,
      payInExtraId: '',
      payInTxid: '',
      payOutCurrency: fromFiro ? 'rsFIRO' : 'FIRO',
      payOutAmount: receiveAmount,
      payOutAddress: addressTo,
      payOutNetwork: toNetwork!,
      payOutExtraId: '',
      payOutTxid: '',
      refundAddress: '',
      refundExtraId: '',
      status: 'Waiting',
      exchangeName: name,
      other: jsonEncode({
        'version': 1,
        'bridgeFee': quote.bridgeFee.toString(),
        'networkFee': quote.networkFee.toString(),
        'tokenContract': DefaultTokens.rsFiro.address,
      }),
    );
    validatedMetadata(trade);
    return trade;
  });

  static Trade _latest(Trade trade) =>
      DB.instance.get<Trade>(boxName: DB.boxNameTradesV2, key: trade.uuid) ??
      trade;

  static Future<Trade> _markFundingObserved(Trade trade) {
    final db = DB.instance;
    return db.mutex.protect(() async {
      final trades = db.hive.box<Trade>(DB.boxNameTradesV2);
      final current = trades.get(trade.uuid);
      if (current == null) return trade;
      final data = jsonDecode(current.other!) as Map<String, dynamic>;
      final value = data['funding'];
      if (value is! Map || value['state'] == 'broadcast') return current;
      final funding = Map<String, dynamic>.from(value);
      final walletId = funding['walletId'];
      final txid = funding['txid'];
      if (walletId is! String ||
          txid is! String ||
          txid != current.payInTxid.toLowerCase()) {
        return current;
      }
      final updated = current.copyWith(
        other: jsonEncode({
          ...data,
          'funding': {...funding, 'state': 'broadcast'},
        }),
      );
      await db.hive
          .box<TradeWalletLookup>(DB.boxNameTradeLookup)
          .put(
            current.uuid,
            TradeWalletLookup(
              uuid: current.uuid,
              txid: txid,
              tradeId: current.tradeId,
              walletIds: [walletId],
            ),
          );
      await trades.put(current.uuid, updated);
      return updated;
    });
  }

  static bool sameVersion(Trade first, Trade second) =>
      jsonEncode(first.toMap()) == jsonEncode(second.toMap());

  static void requireUnfunded(Trade trade) {
    if (trade.payInTxid.isNotEmpty ||
        trade.payOutTxid.isNotEmpty ||
        !{'new', 'waiting'}.contains(trade.status.toLowerCase())) {
      throw StateError('Only an unfunded Rosen swap can be refreshed or sent.');
    }
  }

  static Trade currentUnfunded(Trade trade) {
    final current = DB.instance.get<Trade>(
      boxName: DB.boxNameTradesV2,
      key: trade.uuid,
    );
    if (current == null) {
      throw StateError('This Rosen swap is no longer available.');
    }
    requireUnfunded(current);
    if (!sameVersion(trade, current)) {
      throw ExchangeException(
        'This swap quote was updated. Refresh it before sending.',
        ExchangeExceptionType.quoteChanged,
      );
    }
    return current;
  }

  /// Replace only quote-dependent fields, retaining the user's amount and destination.
  static Trade refreshCandidate(Trade trade, RosenQuote quote) {
    requireUnfunded(trade);
    final amount = RosenProtocol.parseAmount(trade.payInAmount);
    if (amount < quote.minimum ||
        quote.receiveAmount <= BigInt.zero ||
        amount - quote.bridgeFee - quote.networkFee != quote.receiveAmount) {
      throw const FormatException('Amount is below the Rosen bridge minimum.');
    }
    final data = jsonDecode(trade.other!) as Map<String, dynamic>;
    data.remove('metadata');
    final updated = trade.copyWith(
      updatedAt: DateTime.now(),
      payOutAmount: RosenProtocol.formatAmount(quote.receiveAmount),
      other: jsonEncode({
        ...data,
        'bridgeFee': quote.bridgeFee.toString(),
        'networkFee': quote.networkFee.toString(),
      }),
    );
    validatedMetadata(updated);
    return updated;
  }

  static Future<Trade> saveRefreshedTrade(
    Trade original,
    RosenQuote quote,
  ) async {
    final db = DB.instance;
    return db.mutex.protect(() async {
      currentUnfunded(original);
      final updated = refreshCandidate(original, quote);
      await db.hive.box<Trade>(DB.boxNameTradesV2).put(original.uuid, updated);
      return updated;
    });
  }

  /// Rebuild metadata from the trade, and fail closed on edited or stale records.
  static String validatedMetadata(Trade trade) {
    _checkPair(
      trade.payInCurrency,
      trade.payInNetwork,
      trade.payOutCurrency,
      trade.payOutNetwork,
      false,
      false,
    );
    if (trade.exchangeName != exchangeName) {
      throw StateError('Not a Rosen swap.');
    }
    final data = jsonDecode(trade.other!) as Map<String, dynamic>;
    final bridgeFee = BigInt.parse(data['bridgeFee'] as String);
    final networkFee = BigInt.parse(data['networkFee'] as String);
    final amount = RosenProtocol.parseAmount(trade.payInAmount);
    if (data['version'] != 1 ||
        data['tokenContract'] != DefaultTokens.rsFiro.address ||
        amount <= bridgeFee + networkFee ||
        amount - bridgeFee - networkFee !=
            RosenProtocol.parseAmount(trade.payOutAmount) ||
        trade.payInAddress !=
            (isFiro(trade)
                ? RosenApi.firoLockAddress
                : RosenApi.ethereumLockAddress)) {
      throw const FormatException('Invalid Rosen swap data.');
    }
    return RosenProtocol.metadata(
      fromFiro: isFiro(trade),
      destination: trade.payOutAddress,
      bridgeFee: bridgeFee,
      networkFee: networkFee,
    );
  }

  static Future<void> _validateCurrentFees(
    Trade trade, {
    int? sourceHeight,
  }) async {
    validatedMetadata(trade);
    final data = jsonDecode(trade.other!) as Map<String, dynamic>;
    final quote = await RosenApi.instance.quote(
      fromFiro: isFiro(trade),
      amount: RosenProtocol.parseAmount(trade.payInAmount),
      sourceHeight: sourceHeight,
    );
    if (!quote.hasFees(
      BigInt.parse(data['bridgeFee'] as String),
      BigInt.parse(data['networkFee'] as String),
    )) {
      throw ExchangeException(
        'Rosen fees changed. Refresh the swap quote before sending.',
        ExchangeExceptionType.quoteChanged,
      );
    }
  }

  static Future<void> validateFunding(Trade trade, {int? sourceHeight}) async {
    currentUnfunded(trade);
    await _validateCurrentFees(trade, sourceHeight: sourceHeight);
    currentUnfunded(trade);
  }

  static Future<void> validateFundingRecovery(
    Trade trade, {
    int? sourceHeight,
  }) => _validateCurrentFees(trade, sourceHeight: sourceHeight);

  @override
  Future<ExchangeResponse<Trade>> updateTrade(Trade trade) =>
      _response(() async {
        trade = _latest(trade);
        if (trade.payInTxid.isEmpty ||
            {'finished', 'failed'}.contains(trade.status.toLowerCase())) {
          return trade;
        }
        final event = await RosenApi.instance.getEvent(trade.payInTxid);
        trade = _latest(trade);
        if ({'finished', 'failed'}.contains(trade.status.toLowerCase())) {
          return trade;
        }
        if (event == null) {
          final receiptStatus = isFiro(trade)
              ? null
              : await EthereumAPI.getTransactionReceiptStatus(
                  trade.payInTxid,
                  confirmations: RosenApi.ethereumConfirmationWindow,
                );
          if (receiptStatus != null) trade = await _markFundingObserved(trade);
          final currentStatus = trade.status.toLowerCase();
          return trade.copyWith(
            status: receiptStatus == false
                ? 'Failed'
                : {'exchanging', 'sending'}.contains(currentStatus)
                ? trade.status
                : receiptStatus == null && currentStatus == 'verifying'
                ? 'Verifying'
                : 'Confirming',
            updatedAt: DateTime.now(),
          );
        }
        final fromFiro = isFiro(trade);
        final data = jsonDecode(trade.other!) as Map<String, dynamic>;
        if (event['fromChain'] != (fromFiro ? 'firo' : 'ethereum') ||
            event['toChain'] != (fromFiro ? 'ethereum' : 'firo') ||
            (fromFiro
                ? (event['toAddress'] as String).toLowerCase() !=
                      trade.payOutAddress.toLowerCase()
                : event['toAddress'] != trade.payOutAddress) ||
            event['sourceChainTokenId'].toString().toLowerCase() !=
                (fromFiro ? 'firo' : DefaultTokens.rsFiro.address) ||
            event['bridgeFee'].toString() != data['bridgeFee'] ||
            event['networkFee'].toString() != data['networkFee'] ||
            BigInt.parse(event['amount'].toString()) !=
                RosenProtocol.parseAmount(trade.payInAmount)) {
          throw const FormatException('Rosen event does not match this swap.');
        }
        trade = await _markFundingObserved(trade);
        final payoutTxid = event['paymentTxId'] as String?;
        final hasPayout = RosenProtocol.isTransactionId(payoutTxid);
        final status = RosenProtocol.swapStatus(
          event['status'].toString(),
          payoutTxid,
        );
        return trade.copyWith(
          status: status,
          payOutTxid: hasPayout ? payoutTxid : trade.payOutTxid,
          updatedAt: DateTime.now(),
        );
      });

  @override
  Future<ExchangeResponse<Trade>> getTrade(String tradeId) async {
    final trades = DB.instance
        .values<Trade>(boxName: DB.boxNameTradesV2)
        .where((e) => e.tradeId == tradeId && e.exchangeName == name);
    if (trades.isEmpty) {
      return ExchangeResponse(
        exception: ExchangeException(
          'Rosen swap not found locally.',
          ExchangeExceptionType.orderNotFound,
        ),
      );
    }
    return updateTrade(trades.first);
  }

  @override
  Future<ExchangeResponse<List<Trade>>> getTrades() => _response(
    () async => DB.instance
        .values<Trade>(boxName: DB.boxNameTradesV2)
        .where((e) => e.exchangeName == name)
        .toList(),
  );
}
