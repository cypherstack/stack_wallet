import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:stackwallet/models/exchange/aggregate_currency.dart';
import 'package:stackwallet/models/exchange/response_objects/estimate.dart';
import 'package:stackwallet/services/exchange/exchange.dart';
import 'package:stackwallet/utilities/enums/exchange_rate_type_enum.dart';
import 'package:stackwallet/utilities/logger.dart';

class ExchangeFormState extends ChangeNotifier {
  Exchange? _exchange;
  Exchange get exchange => _exchange ??= Exchange.defaultExchange;

  ExchangeRateType _exchangeRateType = ExchangeRateType.estimated;
  ExchangeRateType get exchangeRateType => _exchangeRateType;
  set exchangeRateType(ExchangeRateType exchangeRateType) {
    _exchangeRateType = exchangeRateType;
    //
  }

  Estimate? _estimate;
  Estimate? get estimate => _estimate;

  bool _reversed = false;
  bool get reversed => _reversed;
  set reversed(bool reversed) {
    _reversed = reversed;
    //
  }

  Decimal? _rate;
  Decimal? get rate => _rate;
  // set rate(Decimal? rate) {
  //   _rate = rate;
  //   //
  // }

  Decimal? _sendAmount;
  Decimal? get sendAmount => _sendAmount;
  // set sendAmount(Decimal? sendAmount) {
  //   _sendAmount = sendAmount;
  //   //
  // }

  Decimal? _receiveAmount;
  Decimal? get receiveAmount => _receiveAmount;
  set receiveAmount(Decimal? receiveAmount) {
    _receiveAmount = receiveAmount;
    //
  }

  AggregateCurrency? _sendCurrency;
  AggregateCurrency? get sendCurrency => _sendCurrency;
  // set sendCurrency(Currency? sendCurrency) {
  //   _sendCurrency = sendCurrency;
  //   //
  // }

  AggregateCurrency? _receiveCurrency;
  AggregateCurrency? get receiveCurrency => _receiveCurrency;
  // set receiveCurrency(Currency? receiveCurrency) {
  //   _receiveCurrency = receiveCurrency;
  //   //
  // }

  Decimal? _minSendAmount;
  Decimal? get minSendAmount => _minSendAmount;
  // set minSendAmount(Decimal? minSendAmount) {
  //   _minSendAmount = minSendAmount;
  //   //
  // }

  Decimal? _minReceiveAmount;
  Decimal? get minReceiveAmount => _minReceiveAmount;
  // set minReceiveAmount(Decimal? minReceiveAmount) {
  //   _minReceiveAmount = minReceiveAmount;
  //   //
  // }

  Decimal? _maxSendAmount;
  Decimal? get maxSendAmount => _maxSendAmount;
  // set maxSendAmount(Decimal? maxSendAmount) {
  //   _maxSendAmount = maxSendAmount;
  //   //
  // }

  Decimal? _maxReceiveAmount;
  Decimal? get maxReceiveAmount => _maxReceiveAmount;
  // set maxReceiveAmount(Decimal? maxReceiveAmount) {
  //   _maxReceiveAmount = maxReceiveAmount;
  //   //
  // }

  //============================================================================
  // computed properties
  //============================================================================

  String? get fromTicker => _sendCurrency?.ticker;
  String? get toTicker => _receiveCurrency?.ticker;

  String get fromAmountString => _sendAmount?.toStringAsFixed(8) ?? "";
  String get toAmountString => _receiveAmount?.toStringAsFixed(8) ?? "";

  bool get canExchange {
    return sendCurrency != null &&
        receiveCurrency != null &&
        sendAmount != null &&
        sendAmount! >= Decimal.zero &&
        receiveAmount != null &&
        rate != null &&
        rate! >= Decimal.zero &&
        sendCurrency!.forExchange(exchange.name) != null &&
        receiveCurrency!.forExchange(exchange.name) != null &&
        warning.isEmpty;
  }

  String get warning {
    if (reversed) {
      if (_receiveCurrency != null && _receiveAmount != null) {
        if (_minReceiveAmount != null &&
            _receiveAmount! < _minReceiveAmount! &&
            _receiveAmount! > Decimal.zero) {
          return "Min receive amount ${_minReceiveAmount!.toString()} ${_receiveCurrency!.ticker.toUpperCase()}";
        } else if (_maxReceiveAmount != null &&
            _receiveAmount! > _maxReceiveAmount!) {
          return "Max receive amount ${_maxReceiveAmount!.toString()} ${_receiveCurrency!.ticker.toUpperCase()}";
        }
      }
    } else {
      if (_sendCurrency != null && _sendAmount != null) {
        if (_minSendAmount != null &&
            _sendAmount! < _minSendAmount! &&
            _sendAmount! > Decimal.zero) {
          return "Min send amount ${_minSendAmount!.toString()} ${_sendCurrency!.ticker.toUpperCase()}";
        } else if (_maxSendAmount != null && _sendAmount! > _maxSendAmount!) {
          return "Max send amount ${_maxSendAmount!.toString()} ${_sendCurrency!.ticker.toUpperCase()}";
        }
      }
    }

    return "";
  }

  //============================================================================
  // public state updaters
  //============================================================================

  Future<void> updateExchange({
    required Exchange exchange,
    required bool shouldUpdateData,
    required bool shouldNotifyListeners,
  }) async {
    _exchange = exchange;
    if (shouldUpdateData) {
      await _updateRangesAndEstimate(
        shouldNotifyListeners: false,
      );
    }

    if (shouldNotifyListeners) {
      _notify();
    }
  }

  void setCurrencies(AggregateCurrency? from, AggregateCurrency? to) {
    _sendCurrency = from;
    _receiveCurrency = to;
  }

  void reset({
    required bool shouldNotifyListeners,
  }) {
    _exchange = null;
    _reversed = false;
    _rate = null;
    _sendAmount = null;
    _receiveAmount = null;
    _sendCurrency = null;
    _receiveCurrency = null;
    _minSendAmount = null;
    _minReceiveAmount = null;
    _maxSendAmount = null;
    _maxReceiveAmount = null;

    if (shouldNotifyListeners) {
      _notify();
    }
  }

  Future<void> setSendAmountAndCalculateReceiveAmount(
    Decimal? newSendAmount,
    bool shouldNotifyListeners,
  ) async {
    if (newSendAmount == null) {
      // todo: check if this breaks things and stuff
      _receiveAmount = null;
      _sendAmount = null;
    } else {
      if (newSendAmount <= Decimal.zero) {
        _receiveAmount = Decimal.zero;
      }

      _sendAmount = newSendAmount;
      _reversed = false;

      await _updateRangesAndEstimate(
        shouldNotifyListeners: false,
      );
    }

    if (shouldNotifyListeners) {
      _notify();
    }
  }

  Future<void> setReceivingAmountAndCalculateSendAmount(
    Decimal? newReceiveAmount,
    bool shouldNotifyListeners,
  ) async {
    if (newReceiveAmount == null) {
      // todo: check if this breaks things and stuff
      _receiveAmount = null;
      _sendAmount = null;
    } else {
      if (newReceiveAmount <= Decimal.zero) {
        _sendAmount = Decimal.zero;
      }

      _receiveAmount = newReceiveAmount;
      _reversed = true;

      await _updateRangesAndEstimate(
        shouldNotifyListeners: false,
      );
    }

    if (shouldNotifyListeners) {
      _notify();
    }
  }

  Future<void> updateSendCurrency(
    AggregateCurrency sendCurrency,
    bool shouldNotifyListeners,
  ) async {
    try {
      _sendCurrency = sendCurrency;
      _minSendAmount = null;
      _maxSendAmount = null;

      if (_receiveCurrency == null) {
        _rate = null;
      } else {
        await _updateRangesAndEstimate(
          shouldNotifyListeners: false,
        );
      }
      if (shouldNotifyListeners) {
        _notify();
      }
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Error);
    }
  }

  Future<void> updateReceivingCurrency(
    AggregateCurrency receiveCurrency,
    bool shouldNotifyListeners,
  ) async {
    try {
      _receiveCurrency = receiveCurrency;
      _minReceiveAmount = null;
      _maxReceiveAmount = null;

      if (_sendCurrency == null) {
        _rate = null;
      } else {
        await _updateRangesAndEstimate(
          shouldNotifyListeners: false,
        );
      }
      if (shouldNotifyListeners) {
        _notify();
      }
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Error);
    }
  }

  Future<void> swap({
    required bool shouldNotifyListeners,
  }) async {
    final Decimal? temp = sendAmount;
    _sendAmount = receiveAmount;
    _receiveAmount = temp;

    _minSendAmount = null;
    _maxSendAmount = null;
    _minReceiveAmount = null;
    _maxReceiveAmount = null;

    final AggregateCurrency? tmp = sendCurrency;
    _sendCurrency = receiveCurrency;
    _receiveCurrency = tmp;

    await _updateRangesAndEstimate(
      shouldNotifyListeners: false,
    );

    if (shouldNotifyListeners) {
      _notify();
    }
  }

  Future<void> refresh() => _updateRangesAndEstimate(
        shouldNotifyListeners: true,
      );

  //============================================================================
  // private state updaters
  //============================================================================

  Future<void> _updateRangesAndEstimate({
    required bool shouldNotifyListeners,
  }) async {
    try {
      // switch (exchange.name) {
      //   case ChangeNowExchange.exchangeName:
      //     if (!_exchangeSupported(
      //       exchangeName: exchange.name,
      //       sendCurrency: sendCurrency,
      //       receiveCurrency: receiveCurrency,
      //       exchangeRateType: exchangeRateType,
      //     )) {
      //       _exchange = MajesticBankExchange.instance;
      //     }
      //     break;
      //   case MajesticBankExchange.exchangeName:
      //     if (!_exchangeSupported(
      //       exchangeName: exchange.name,
      //       sendCurrency: sendCurrency,
      //       receiveCurrency: receiveCurrency,
      //       exchangeRateType: exchangeRateType,
      //     )) {
      //       _exchange = ChangeNowExchange.instance;
      //     }
      //     break;
      // }

      await _updateRanges(shouldNotifyListeners: false);
      await _updateEstimate(shouldNotifyListeners: false);
      if (shouldNotifyListeners) {
        _notify();
      }
    } catch (_) {
      //
    }
  }

  Future<void> _updateRanges({
    required bool shouldNotifyListeners,
  }) async {
    // if (exchange?.name == SimpleSwapExchange.exchangeName) {
    //   reversed = false;
    // }
    final _send = sendCurrency;
    final _receive = receiveCurrency;
    if (_send == null || _receive == null) {
      Logging.instance.log(
        "Tried to $runtimeType.updateRanges where ( $_send || $_receive) for: $exchange",
        level: LogLevel.Info,
      );
      return;
    }
    final response = await exchange.getRange(
      _send.ticker,
      _receive.ticker,
      exchangeRateType == ExchangeRateType.fixed,
    );

    if (response.value == null) {
      Logging.instance.log(
        "Tried to $runtimeType.updateRanges for: $exchange where response: $response",
        level: LogLevel.Info,
      );
      return;
    }
    final responseReversed = await exchange.getRange(
      _receive.ticker,
      _send.ticker,
      exchangeRateType == ExchangeRateType.fixed,
    );

    if (responseReversed.value == null) {
      Logging.instance.log(
        "Tried to $runtimeType.updateRanges for: $exchange where response: $responseReversed",
        level: LogLevel.Info,
      );
      return;
    }

    final range = response.value!;
    final rangeReversed = responseReversed.value!;

    _minSendAmount = range.min;
    _maxSendAmount = range.max;
    _minReceiveAmount = rangeReversed.min;
    _maxReceiveAmount = rangeReversed.max;

    //todo: check if print needed
    // debugPrint(
    //     "updated range for: $exchange for $_fromTicker-$_toTicker: $range");

    if (shouldNotifyListeners) {
      _notify();
    }
  }

  Future<void> _updateEstimate({
    required bool shouldNotifyListeners,
  }) async {
    // if (exchange?.name == SimpleSwapExchange.exchangeName) {
    //   reversed = false;
    // }
    final amount = reversed ? receiveAmount : sendAmount;
    if (sendCurrency == null ||
        receiveCurrency == null ||
        amount == null ||
        amount <= Decimal.zero) {
      Logging.instance.log(
        "Tried to $runtimeType.updateEstimate for: $exchange where (from: $sendCurrency || to: $receiveCurrency || amount: $amount)",
        level: LogLevel.Info,
      );
      return;
    }
    final response = await exchange.getEstimate(
      sendCurrency!.ticker,
      receiveCurrency!.ticker,
      amount,
      exchangeRateType == ExchangeRateType.fixed,
      reversed,
    );

    if (response.value == null) {
      Logging.instance.log(
        "Tried to $runtimeType.updateEstimate for: $exchange where response: $response",
        level: LogLevel.Info,
      );
      return;
    }

    _estimate = response.value!;

    if (reversed) {
      _sendAmount = _estimate!.estimatedAmount;
    } else {
      _receiveAmount = _estimate!.estimatedAmount;
    }

    _rate =
        (receiveAmount! / sendAmount!).toDecimal(scaleOnInfinitePrecision: 12);

    //todo: check if print needed
    // debugPrint(
    //     "updated estimate for: $exchange for $fromTicker-$toTicker: $estimate");

    if (shouldNotifyListeners) {
      _notify();
    }
  }

  //============================================================================

  void _notify() {
    debugPrint("ExFState NOTIFY: ${toString()}");
    notifyListeners();
  }

  bool _exchangeSupported({
    required String exchangeName,
    required AggregateCurrency? sendCurrency,
    required AggregateCurrency? receiveCurrency,
    required ExchangeRateType exchangeRateType,
  }) {
    final send = sendCurrency?.forExchange(exchangeName);
    if (send == null) return false;

    final rcv = receiveCurrency?.forExchange(exchangeName);
    if (rcv == null) return false;

    if (exchangeRateType == ExchangeRateType.fixed) {
      return send.supportsFixedRate && rcv.supportsFixedRate;
    } else {
      return send.supportsEstimatedRate && rcv.supportsEstimatedRate;
    }
  }

  @override
  String toString() {
    return "{"
        "\n\t exchange: $exchange,"
        "\n\t exchangeRateType: $exchangeRateType,"
        "\n\t sendCurrency: $sendCurrency,"
        "\n\t receiveCurrency: $receiveCurrency,"
        "\n\t rate: $rate,"
        "\n\t reversed: $reversed,"
        "\n\t sendAmount: $sendAmount,"
        "\n\t receiveAmount: $receiveAmount,"
        "\n\t estimate: $estimate,"
        "\n\t minSendAmount: $minSendAmount,"
        "\n\t maxSendAmount: $maxSendAmount,"
        "\n\t minReceiveAmount: $minReceiveAmount,"
        "\n\t maxReceiveAmount: $maxReceiveAmount,"
        "\n\t canExchange: $canExchange,"
        "\n\t warning: $warning,"
        "\n}";
  }
}
