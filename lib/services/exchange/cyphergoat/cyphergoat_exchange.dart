import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';

import '../../../app_config.dart';
import '../../../exceptions/exchange/exchange_exception.dart';
import '../../../models/exchange/response_objects/estimate.dart';
import '../../../models/exchange/response_objects/range.dart';
import '../../../models/exchange/response_objects/trade.dart';
import '../../../models/isar/exchange_cache/currency.dart';
import '../../../models/isar/exchange_cache/pair.dart';
import '../exchange.dart';
import '../exchange_response.dart';
import 'cyphergoat_api.dart';

class _CgCoin {
  final String ticker;
  final String name;
  final String network;
  final double? min;

  const _CgCoin({
    required this.ticker,
    required this.name,
    required this.network,
    this.min,
  });
}

// Static coin list derived from CypherGoat's coins.json.
const List<_CgCoin> _kCgCoins = [
  _CgCoin(ticker: 'btc', name: 'Bitcoin', network: 'btc', min: 4.449e-05),
  _CgCoin(
    ticker: 'btc',
    name: 'Bitcoin (Lightning)',
    network: 'lightning',
    min: 4.449e-05,
  ),
  _CgCoin(ticker: 'eth', name: 'Ethereum', network: 'eth', min: 0.001114),
  _CgCoin(ticker: 'xmr', name: 'Monero', network: 'xmr', min: 0.01886),
  _CgCoin(ticker: 'ltc', name: 'Litecoin', network: 'ltc', min: 0.04444),
  _CgCoin(ticker: 'bch', name: 'Bitcoin Cash', network: 'bch'),
  _CgCoin(ticker: 'doge', name: 'Dogecoin', network: 'doge', min: 22.59),
  _CgCoin(ticker: 'bnb', name: 'Binance Coin', network: 'bnb', min: 0.005711),
  _CgCoin(ticker: 'sol', name: 'Solana', network: 'sol', min: 0.0238),
  _CgCoin(ticker: 'xtz', name: 'Tezos', network: 'xtz', min: 6.336),
  _CgCoin(ticker: 'ada', name: 'Cardano', network: 'ada', min: 5.868),
  _CgCoin(ticker: 'xrp', name: 'Ripple', network: 'xrp', min: 1.678),
  _CgCoin(ticker: 'trx', name: 'Tron', network: 'trx', min: 14.58),
  _CgCoin(ticker: 'link', name: 'Chainlink', network: 'link', min: 0.2014),
  _CgCoin(ticker: 'usdc', name: 'USDC (Ethereum)', network: 'usdc'),
  _CgCoin(ticker: 'xno', name: 'Nano', network: 'xno', min: 5.393),
  _CgCoin(ticker: 'usdc', name: 'USDC (Polygon)', network: 'poly'),
  _CgCoin(ticker: 'usdc', name: 'USDC (Solana)', network: 'sol'),
  _CgCoin(ticker: 'usdc', name: 'USDC (Algorand)', network: 'algo'),
  _CgCoin(ticker: 'usdc', name: 'USDC (BSC)', network: 'bsc'),
  _CgCoin(ticker: 'usdc', name: 'USDC (Optimism)', network: 'op'),
  _CgCoin(ticker: 'usdc', name: 'USDC (Base)', network: 'base'),
  _CgCoin(ticker: 'usdc', name: 'USDC (Tron)', network: 'tron'),
  _CgCoin(ticker: 'usdt', name: 'Tether USD (Ethereum)', network: 'eth'),
  _CgCoin(ticker: 'usdt', name: 'Tether USD (Tron)', network: 'tron'),
  _CgCoin(ticker: 'usdt', name: 'Tether USD (Polygon)', network: 'poly'),
  _CgCoin(ticker: 'usdt', name: 'Tether USD (BSC)', network: 'bsc'),
  _CgCoin(ticker: 'usdt', name: 'Tether USD (Solana)', network: 'sol'),
  _CgCoin(ticker: 'usdt', name: 'Tether USD (Algorand)', network: 'algo'),
  _CgCoin(ticker: 'busd', name: 'Binance USD (BSC)', network: 'bsc'),
  _CgCoin(ticker: 'busd', name: 'Binance USD (Ethereum)', network: 'eth'),
  _CgCoin(ticker: 'dai', name: 'Dai (Ethereum)', network: 'eth'),
  _CgCoin(ticker: 'dai', name: 'Dai (BSC)', network: 'bsc'),
  _CgCoin(ticker: 'dai', name: 'Dai (Polygon)', network: 'poly'),
  _CgCoin(ticker: 'dai', name: 'Dai (Optimism)', network: 'op'),
  _CgCoin(ticker: 'tusd', name: 'True USD', network: 'tusd'),
  _CgCoin(ticker: 'tusd', name: 'True USD (Tron)', network: 'tron'),
  _CgCoin(ticker: 'shib', name: 'Shiba Inu', network: 'shib', min: 10000),
  _CgCoin(ticker: 'dot', name: 'Polkadot', network: 'dot', min: 1.272),
  _CgCoin(ticker: 'etc', name: 'Ethereum Classic', network: 'etc', min: 0.2318),
  _CgCoin(ticker: 'zec', name: 'Zcash', network: 'zec', min: 0.2),
  _CgCoin(ticker: 'hive', name: 'Hive', network: 'hive', min: 24.06),
  _CgCoin(ticker: 'bdx', name: 'Beldex', network: 'bdx', min: 65.93),
  _CgCoin(ticker: 'wow', name: 'Wownero', network: 'wow', min: 163.8),
  _CgCoin(ticker: 'ban', name: 'Banano', network: 'banano', min: 2614.0),
  _CgCoin(ticker: 'arrr', name: 'Pirate Chain', network: 'arrr', min: 4.8),
  _CgCoin(
    ticker: 'arrrbsc',
    name: 'Pirate Chain (BSC)',
    network: 'arrrbsc',
    min: 4.8,
  ),
  _CgCoin(ticker: 'dcr', name: 'Decred', network: 'dcr', min: 0.3045),
  _CgCoin(ticker: 'aave', name: 'Aave', network: 'aave', min: 0.01574),
  _CgCoin(ticker: 'avax', name: 'Avalanche', network: 'avax', min: 0.4263),
  _CgCoin(
    ticker: 'bat',
    name: 'Basic Attention Token',
    network: 'bat',
    min: 32.09,
  ),
  _CgCoin(ticker: 'link', name: 'Chainlink (BSC)', network: 'bsc', min: 0.2014),
  _CgCoin(ticker: 'gusd', name: 'Gemini Dollar', network: 'gusd'),
  _CgCoin(ticker: 'paxg', name: 'Paxos Gold', network: 'paxg', min: 0.002),
  _CgCoin(ticker: 'hbar', name: 'Hedera', network: 'hbar', min: 12),
  _CgCoin(ticker: 'ark', name: 'Ark', network: 'ark', min: 10.96),
  _CgCoin(ticker: 'firo', name: 'Firo', network: 'firo', min: 14.24),
  _CgCoin(
    ticker: 'wbtc',
    name: 'Wrapped Bitcoin',
    network: 'wbtc',
    min: 4.444e-05,
  ),
  _CgCoin(ticker: '1inch', name: '1inch', network: '1inch', min: 19.87),
  _CgCoin(ticker: 'dash', name: 'Dash', network: 'dash', min: 0.2152),
  _CgCoin(ticker: 'zano', name: 'Zano', network: 'zano', min: 0.3358),
  _CgCoin(ticker: 'tel', name: 'Telcoin', network: 'tel', min: 1001.0),
  _CgCoin(ticker: 'leo', name: 'Leo Token', network: 'leo', min: 2),
  _CgCoin(ticker: 'fusd', name: 'Freedom Dollar', network: 'fusd', min: 25),
  _CgCoin(ticker: 'apt', name: 'Aptos', network: 'apt', min: 1.134),
  _CgCoin(ticker: 'sui', name: 'Sui', network: 'sui', min: 1.449),
  _CgCoin(ticker: 'nvdax', name: 'NVIDIA xStock', network: 'nvdax', min: 0.8),
  _CgCoin(ticker: 'spyx', name: 'SP500 xStock', network: 'spyx', min: 0.3),
  _CgCoin(ticker: 'tslax', name: 'TSLA xStock', network: 'tslax', min: 0.4),
  _CgCoin(ticker: 'qqqx', name: 'Nasdaq xStock', network: 'qqqx', min: 0.3),
  _CgCoin(ticker: 'crclx', name: 'Circle xStock', network: 'crclx', min: 1.3),
  _CgCoin(
    ticker: 'mstrx',
    name: 'MicroStrategy xStock',
    network: 'mstrx',
    min: 0.4,
  ),
  _CgCoin(ticker: 'aaplx', name: 'Apple xStock', network: 'aaplx', min: 0.6),
  _CgCoin(ticker: 'coinx', name: 'Coinbase xStock', network: 'coinx', min: 0.5),
  _CgCoin(
    ticker: 'googlx',
    name: 'Alphabet xStock',
    network: 'googlx',
    min: 0.7,
  ),
  _CgCoin(ticker: 'amznx', name: 'Amazon xStock', network: 'amznx', min: 0.6),
  _CgCoin(ticker: 'metax', name: 'Meta xStock', network: 'metax', min: 0.2),
  _CgCoin(
    ticker: 'hoodx',
    name: 'Robinhood xStock',
    network: 'hoodx',
    min: 1.3,
  ),
  _CgCoin(ticker: 'gmex', name: 'Gamestop xStock', network: 'gmex', min: 5),
];

class CypherGoatExchange extends Exchange {
  CypherGoatExchange._();

  static CypherGoatExchange? _instance;
  static CypherGoatExchange get instance =>
      _instance ??= CypherGoatExchange._();

  static const exchangeName = "CypherGoat";

  @override
  String get name => exchangeName;

  @override
  bool get supportsRefundAddress => false;

  @override
  Future<ExchangeResponse<List<Currency>>> getAllCurrencies(
    bool fixedRate,
  ) async {
    try {
      if (fixedRate) {
        return ExchangeResponse(
          exception: ExchangeException(
            "CypherGoat does not support fixed rate",
            ExchangeExceptionType.generic,
          ),
        );
      }

      final currencies = _kCgCoins
          .map(
            (c) => Currency(
              exchangeName: exchangeName,
              ticker: c.ticker,
              name: c.name,
              network: c.network,
              image: "",
              isFiat: false,
              rateType: SupportedRateType.estimated,
              isStackCoin: AppConfig.isStackCoin(c.ticker),
              tokenContract: null,
              isAvailable: true,
            ),
          )
          .toList();

      return ExchangeResponse(value: currencies);
    } catch (e) {
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  @override
  Future<ExchangeResponse<Range>> getRange(
    String from,
    String? fromNetwork,
    String to,
    String? toNetwork,
    bool fixedRate,
  ) async {
    try {
      if (fixedRate) {
        return ExchangeResponse(
          exception: ExchangeException(
            "CypherGoat does not support fixed rate",
            ExchangeExceptionType.generic,
          ),
        );
      }

      // Use the min from the static coin list as a quick offline fallback.
      final coin = _kCgCoins.where(
        (c) =>
            c.ticker.toLowerCase() == from.toLowerCase() &&
            (fromNetwork == null ||
                c.network.toLowerCase() == fromNetwork.toLowerCase()),
      );

      Decimal? min;
      if (coin.isNotEmpty && coin.first.min != null) {
        min = Decimal.parse(coin.first.min.toString());
      }

      // Fetch live min from the API.
      final response = await CypherGoatAPI.getEstimate(
        coin1: from,
        network1: fromNetwork ?? from,
        coin2: to,
        network2: toNetwork ?? to,
        amount: (min ?? Decimal.one).toString(),
      );

      if (response.value != null) {
        final liveMin = response.value!.min;
        if (liveMin > Decimal.zero) {
          min = liveMin;
        }
      }

      return ExchangeResponse(value: Range(min: min, max: null));
    } catch (e) {
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  @override
  Future<ExchangeResponse<List<Estimate>>> getEstimates(
    String from,
    String? fromNetwork,
    String to,
    String? toNetwork,
    Decimal amount,
    bool fixedRate,
    bool reversed,
  ) async {
    try {
      if (fixedRate) {
        return ExchangeResponse(
          exception: ExchangeException(
            "CypherGoat does not support fixed rate",
            ExchangeExceptionType.generic,
          ),
        );
      }
      if (reversed) {
        return ExchangeResponse(
          exception: ExchangeException(
            "CypherGoat does not support reversed estimates",
            ExchangeExceptionType.generic,
          ),
        );
      }

      final response = await CypherGoatAPI.getEstimate(
        coin1: from,
        network1: fromNetwork ?? from,
        coin2: to,
        network2: toNetwork ?? to,
        amount: amount.toString(),
      );

      if (response.value == null) {
        return ExchangeResponse(exception: response.exception);
      }

      final data = response.value!;
      final estimateIdStr = data.rates.estimateId.toString();

      final List<Estimate> estimates = [];
      for (final quote in response.value!.rates.results) {
        final provider = quote.exchange.toLowerCase();
        if (provider != "changenow" &&
            provider != "letsexchange" &&
            provider != "exolix") {
          estimates.add(
            Estimate(
              estimatedAmount: quote.amount,
              fixedRate: false,
              reversed: false,
              exchangeProvider: quote.exchange,
              rateId: estimateIdStr,
              // exchangeProviderLogo: quote.providerLogo,
              // kycRating: quote.kycRating,
            ),
          );
        }
      }

      estimates.sort((a, b) => b.estimatedAmount.compareTo(a.estimatedAmount));

      if (estimates.isEmpty) {
        return ExchangeResponse(
          exception: ExchangeException(
            "No rates available for this pair",
            ExchangeExceptionType.orderNotFound,
          ),
        );
      }

      return ExchangeResponse(value: estimates);
    } on ExchangeException catch (e) {
      return ExchangeResponse(exception: e);
    } catch (e) {
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

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
  }) async {
    try {
      if (fixedRate) {
        throw ExchangeException(
          "CypherGoat does not support fixed rate",
          ExchangeExceptionType.generic,
        );
      }
      if (reversed) {
        throw ExchangeException(
          "CypherGoat does not support reversed trades",
          ExchangeExceptionType.generic,
        );
      }
      if (estimate == null) {
        throw ExchangeException(
          "An estimate is required to create a CypherGoat trade",
          ExchangeExceptionType.generic,
        );
      }

      final response = await CypherGoatAPI.createSwap(
        coin1: from,
        network1: fromNetwork ?? from,
        coin2: to,
        network2: toNetwork ?? to,
        amount: amount.toString(),
        partner: estimate.exchangeProvider,
        address: addressTo,
        estimateId: estimate.rateId,
      );

      if (response.value == null) {
        return ExchangeResponse(exception: response.exception);
      }

      final tx = response.value!;

      return ExchangeResponse(
        value: Trade(
          uuid: const Uuid().v1(),
          tradeId: tx.cgid ?? tx.id,
          rateType: "estimated",
          direction: "direct",
          timestamp: tx.createdAt,
          updatedAt: tx.createdAt,
          payInCurrency: tx.coin1.toUpperCase(),
          payInAmount: tx.sendAmount.toString(),
          payInAddress: tx.address,
          payInNetwork: tx.network1,
          payInExtraId: tx.memo ?? "",
          payInTxid: "",
          payOutCurrency: tx.coin2.toUpperCase(),
          payOutAmount: tx.estimateAmount.toString(),
          payOutAddress: tx.destinationAddress,
          payOutNetwork: tx.network2,
          payOutExtraId: "",
          payOutTxid: "",
          refundAddress: "",
          refundExtraId: "",
          status: tx.status,
          exchangeName: exchangeName,
          other: tx.track,
        ),
      );
    } on ExchangeException catch (e) {
      return ExchangeResponse(exception: e);
    } catch (e) {
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  @override
  Future<ExchangeResponse<Trade>> getTrade(String tradeId) async {
    try {
      final response = await CypherGoatAPI.getTransaction(cgid: tradeId);

      if (response.value == null) {
        return ExchangeResponse(exception: response.exception);
      }

      final tx = response.value!;

      return ExchangeResponse(
        value: Trade(
          uuid: const Uuid().v1(),
          tradeId: tx.cgid ?? tradeId,
          rateType: "estimated",
          direction: "direct",
          timestamp: tx.createdAt,
          updatedAt: DateTime.now(),
          payInCurrency: tx.coin1.toUpperCase(),
          payInAmount: tx.sendAmount.toString(),
          payInAddress: tx.address,
          payInNetwork: tx.network1,
          payInExtraId: tx.memo ?? "",
          payInTxid: "",
          payOutCurrency: tx.coin2.toUpperCase(),
          payOutAmount: tx.estimateAmount.toString(),
          payOutAddress: tx.destinationAddress,
          payOutNetwork: tx.network2,
          payOutExtraId: "",
          payOutTxid: "",
          refundAddress: "",
          refundExtraId: "",
          status: tx.status,
          exchangeName: exchangeName,
          other: tx.track,
        ),
      );
    } on ExchangeException catch (e) {
      return ExchangeResponse(exception: e);
    } catch (e) {
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }

  @override
  Future<ExchangeResponse<List<Trade>>> getTrades() async {
    throw UnimplementedError(
      "CypherGoat does not provide a trade history endpoint",
    );
  }

  @override
  Future<ExchangeResponse<Trade>> updateTrade(Trade trade) async {
    try {
      final response = await CypherGoatAPI.getTransaction(cgid: trade.tradeId);

      if (response.value == null) {
        return ExchangeResponse(exception: response.exception);
      }

      final tx = response.value!;

      return ExchangeResponse(
        value: Trade(
          uuid: trade.uuid,
          tradeId: trade.tradeId,
          rateType: trade.rateType,
          direction: trade.direction,
          timestamp: trade.timestamp,
          updatedAt: DateTime.now(),
          payInCurrency: tx.coin1.toUpperCase(),
          payInAmount: tx.sendAmount.toString(),
          payInAddress: tx.address,
          payInNetwork: trade.payInNetwork,
          payInExtraId: tx.memo ?? trade.payInExtraId,
          payInTxid: trade.payInTxid,
          payOutCurrency: tx.coin2.toUpperCase(),
          payOutAmount: tx.estimateAmount.toString(),
          payOutAddress: tx.destinationAddress,
          payOutNetwork: trade.payOutNetwork,
          payOutExtraId: trade.payOutExtraId,
          payOutTxid: trade.payOutTxid,
          refundAddress: trade.refundAddress,
          refundExtraId: trade.refundExtraId,
          status: tx.status,
          exchangeName: exchangeName,
          other: tx.track,
        ),
      );
    } on ExchangeException catch (e) {
      return ExchangeResponse(exception: e);
    } catch (e) {
      return ExchangeResponse(
        exception: ExchangeException(
          e.toString(),
          ExchangeExceptionType.generic,
        ),
      );
    }
  }
}
