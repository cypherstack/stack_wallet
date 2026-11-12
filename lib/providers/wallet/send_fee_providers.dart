import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/paymint/fee_object_model.dart';
import '../../services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import '../../services/event_bus/global_event_bus.dart';
import '../../utilities/address_utils.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/enums/fee_rate_type_enum.dart';
import '../../utilities/logger.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../../wallets/crypto_currency/interfaces/electrumx_currency_interface.dart';
import '../../wallets/crypto_currency/intermediate/cryptonote_currency.dart';
import '../../wallets/crypto_currency/intermediate/nano_currency.dart';
import '../../wallets/isar/providers/eth/current_token_wallet_provider.dart';
import '../../wallets/isar/providers/wallet_info_provider.dart';
import '../../wallets/wallet/impl/firo_wallet.dart';
import '../../wallets/wallet/wallet.dart';
import '../../wallets/wallet/wallet_mixin_interfaces/sync_dependent_fee_estimate_interface.dart';
import '../global/wallets_provider.dart';
import '../ui/fee_rate_type_state_provider.dart';
import '../ui/preview_tx_button_state_provider.dart';
import 'public_private_balance_state_provider.dart';

typedef _FeeKey = ({
  FeeRateType feeRateType,
  Amount? amount,
  bool isSpark,
  String? opReturnData,
  Object spendable,
});

class _Request<T extends Object> {
  _Request(this.future) {
    future.then<void>((answer) {
      value = answer;
      // A FutureBuilder given the request later builds its answer at once.
      future = SynchronousFuture(answer);
    }, onError: (Object _) {});
  }

  Future<T> future;
  T? value;
}

class SendFeeRates {
  SendFeeRates(this._read, {required this._walletId, required this._isToken})
    : _feesByRate = {};

  SendFeeRates._refreshed(SendFeeRates previous)
    : _read = previous._read,
      _walletId = previous._walletId,
      _isToken = previous._isToken,
      _feesByRate = previous._feesByRate;

  final Reader _read;
  final String _walletId;
  final bool _isToken;

  /// Fees estimated at each fee rate, so fresh rates at the same rate reuse
  /// them, and Spark fees.
  final Map<Object, Amount> _feesByRate;
  final _estimates = <_FeeKey, _Request<Amount>>{};
  _Request<FeeObject>? _rates;

  Wallet get _wallet => _read(pWallets).getWallet(_walletId);

  Wallet get _feeWallet =>
      _isToken && coin is Ethereum ? _read(pCurrentTokenWallet)! : _wallet;

  late final CryptoCurrency coin = _wallet.cryptoCurrency;

  Future<FeeObject> get rates =>
      (_rates ??= _Request(_logged(() => _feeWallet.fees))).future;

  SendFeeRates refreshed() => SendFeeRates._refreshed(this);

  /// The rates and fees that have not arrived are asked again.
  void _retry() {
    if (_rates?.value == null) _rates = null;
    _estimates.removeWhere((_, estimate) => estimate.value == null);
  }

  /// One request for everything the fee depends on, which [read] reads.
  Future<Amount> estimate(
    Reader read,
    FeeRateType feeRateType, {
    Amount? amount,
  }) {
    final key = _key(read, feeRateType, amount);
    if (_wallet case SyncDependentFeeEstimateInterface(canEstimateFee: false)
        when !_estimates.containsKey(key)) {
      // The wallet's next sync status rebuilds the widget [read] belongs to,
      // which asks again.
      read(_pWalletSyncStatusChange(_walletId));
      return Completer<Amount>().future;
    }
    return _estimates.putIfAbsent(key, () => _Request(_estimate(key))).future;
  }

  _FeeKey _key(Reader read, FeeRateType feeRateType, Amount? amount) {
    final isSpark = _isSparkFee(coin, read(publicPrivateBalanceStateProvider));
    final balance = isSpark ? pWalletBalanceTertiary : pWalletBalance;
    final spendable = read(balance(_walletId)).spendable;
    return (
      feeRateType: feeRateType,
      amount:
          _isFeeAmountIndependent(coin) ||
              amount == null ||
              amount.raw == BigInt.zero
          ? null
          : amount,
      isSpark: isSpark,
      opReturnData: coin is Firo && !isSpark ? read(pOpReturnData) : null,
      // The fee depends on the coins the wallet can spend, or only on having
      // some when it ignores the amount.
      spendable: _isFeeAmountIndependent(coin)
          ? spendable.raw > BigInt.zero
          : spendable,
    );
  }

  Future<Amount> _estimate(_FeeKey key) async {
    // The form may be closed once the rates arrive.
    final (wallet, feeWallet) = (_wallet, _feeWallet);
    final zero = Amount.zeroWith(fractionDigits: coin.fractionDigits);
    final amount = key.amount ?? zero;
    if (key.isSpark) {
      return _feesByRate[(key.amount, key.spendable)] ??= await _logged(
        () => (wallet as FiroWallet).estimateFeeForSpark(amount),
      );
    }
    if (key.feeRateType.isCustom) {
      if (coin is CryptonoteCurrency) {
        throw ArgumentError("custom fee not available for monero");
      }
      // The send forms hide the estimated fee at the Custom level.
      return zero;
    }

    final rates = await this.rates;
    final feeRate = switch (key.feeRateType) {
      FeeRateType.fast => rates.fast,
      FeeRateType.slow => rates.slow,
      _ => rates.medium,
    };
    final byRate = (feeRate, key.amount, key.opReturnData, key.spendable);
    final known = _feesByRate[byRate];
    if (known != null) return known;

    final fee = await _logged(() => feeWallet.estimateFeeFor(amount, feeRate));
    final opReturnData = key.opReturnData ?? "";
    final opReturnFee = wallet is FiroWallet && opReturnData.isNotEmpty
        ? wallet.estimateTxFee(
            vSize: AddressUtils.opReturnOutputVSizeFromHex(opReturnData),
            feeRatePerKB: feeRate,
          )
        : 0;
    return _feesByRate[byRate] =
        fee + opReturnFee.toAmountAsRaw(fractionDigits: fee.fractionDigits);
  }

  Future<T> _logged<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (error, stackTrace) {
      Logging.instance.w(
        "Failed to calculate ${coin.prettyName}${_isToken ? " token" : ""} "
        "fees: ",
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

final _pWalletSyncStatusChange = StreamProvider.autoDispose
    .family<WalletSyncStatusChangedEvent, String>(
      (ref, walletId) => GlobalEventBus.instance
          .on<WalletSyncStatusChangedEvent>()
          .where((event) => event.walletId == walletId),
    );

bool _isSparkFee(CryptoCurrency coin, BalanceType balanceType) =>
    coin is Firo && balanceType == BalanceType.private;

bool _isFeeAmountIndependent(CryptoCurrency coin) =>
    coin is Ethereum || coin is Solana || coin is Stellar || coin is Cardano;

/// Stellar and Cardano give the same fee at every rate.
bool canPickFeeRateType(CryptoCurrency coin, BalanceType balanceType) =>
    !_isSparkFee(coin, balanceType) && coin is! Stellar && coin is! Cardano;

bool canUseCustomFee(CryptoCurrency coin) =>
    coin is ElectrumXCurrencyInterface || coin is Ethereum;

Iterable<FeeRateType> sendFeeRateTypes(CryptoCurrency coin) =>
    FeeRateType.values.where((e) => !e.isCustom || canUseCustomFee(coin));

/// The custom fee inputs start over each time the Custom level shows, and any
/// send form can change the level. They also start over once the balance sent
/// from hides them.
void listenForCustomFeeLevel(
  WidgetRef ref,
  CryptoCurrency coin,
  VoidCallback onToggled,
) {
  ref.listen<FeeRateType>(pFeeRateType, (previous, next) {
    if (previous?.isCustom != next.isCustom) onToggled();
  });
  ref.listen<BalanceType>(publicPrivateBalanceStateProvider, (_, next) {
    if (!canPickFeeRateType(coin, next)) onToggled();
  });
}

bool hasSendFee(CryptoCurrency coin) =>
    coin is! Epiccash &&
    coin is! Mimblewimblecoin &&
    coin is! NanoCurrency &&
    coin is! Tezos;

String estimatedTimeToBeIncludedInNextBlock(
  int targetBlockTime,
  int estimatedNumberOfBlocks,
) {
  final time = targetBlockTime * estimatedNumberOfBlocks;
  final hours = (time / 3600).floor();
  if (hours > 0) return "~$hours hour${hours > 1 ? "s" : ""}";
  final minutes = (time / 60).toStringAsFixed(1);
  if (minutes == "1.0") return "~1 minute";
  return "~${minutes.endsWith(".0") ? (time / 60).floor() : minutes} minutes";
}

String sendFeeTime(
  CryptoCurrency coin,
  FeeObject rates,
  FeeRateType feeRateType,
) => estimatedTimeToBeIncludedInNextBlock(
  coin.targetBlockTimeSeconds,
  switch (feeRateType) {
    FeeRateType.fast => rates.numberOfBlocksFast,
    FeeRateType.slow => rates.numberOfBlocksSlow,
    _ => rates.numberOfBlocksAverage,
  },
);

/// Amount edits and balance switches ask again for a fee that failed or
/// hangs.
mixin SendFeeForm<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  late SendFeeRates fees;
  Amount? feeAmount;
  Amount? _typedFeeAmount;
  Timer? _typing;
  Object? _feeChoice;

  bool get _isTyping => _typing?.isActive ?? false;

  void followFeeAmount(Amount? amount) {
    _typedFeeAmount = amount;
    _typing?.cancel();
    _typing = Timer(
      const Duration(milliseconds: 500),
      () => setFeeAmount(amount),
    );
  }

  void setFeeAmount(Amount? amount) {
    _typing?.cancel();
    setState(() {
      fees._retry();
      feeAmount = amount;
    });
  }

  void retryFee() => setFeeAmount(_isTyping ? _typedFeeAmount : feeAmount);

  /// Leaving the amount [fields] applies the amount being typed at once.
  void retryFeeOnFocusLoss(List<FocusNode> fields) {
    for (final field in fields) {
      field.addListener(() {
        if (mounted && !fields.any((field) => field.hasFocus)) retryFee();
      });
    }
  }

  Future<Amount> watchFee() =>
      fees.estimate(ref.watch, ref.watch(pFeeRateType), amount: feeAmount);

  /// Null until the fee of [watchFee] arrives.
  Amount? get shownFee => fees
      ._estimates[fees._key(ref.read, ref.read(pFeeRateType), feeAmount)]
      ?.value;

  /// The form takes over the choice's fresh rates once the chosen fee arrives
  /// at them, so a refresh that fails keeps the fee shown.
  Future<void> chooseFee(
    Future<void> Function(SendFeeRates fees, Amount? amount) show,
  ) async {
    if (_isTyping) setFeeAmount(_typedFeeAmount);
    final choice = _feeChoice = Object();
    final amount = feeAmount;
    final refreshed = fees.refreshed();
    await show(refreshed, amount);
    final feeRateType = ref.read(pFeeRateType);
    final chosen = await refreshed
        .estimate(ref.read, feeRateType, amount: amount)
        .then<Amount?>((fee) => fee, onError: (Object _) => null);
    // The latest choice wins.
    if (!mounted || !identical(_feeChoice, choice) || chosen == null) return;
    // The Custom level has its fee before the rates arrive.
    if (refreshed._rates?.value == null) return;
    // The fee may follow another amount by now, and the same fee gains
    // nothing.
    if (fees._key(ref.read, feeRateType, amount) ==
            fees._key(ref.read, feeRateType, feeAmount) &&
        shownFee != chosen) {
      setState(() => fees = refreshed);
    }
  }

  @override
  void dispose() {
    _typing?.cancel();
    super.dispose();
  }
}
