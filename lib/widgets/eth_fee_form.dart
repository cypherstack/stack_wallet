import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../services/ethereum/ethereum_api.dart';
import '../themes/stack_colors.dart';
import '../utilities/amount/amount.dart';
import '../utilities/amount/amount_field_relocalization.dart';
import '../utilities/amount/amount_input_formatter.dart';
import '../utilities/constants.dart';
import '../utilities/integer_input.dart';
import '../utilities/text_styles.dart';
import '../utilities/util.dart';
import 'stack_text_field.dart';

@immutable
class EthEIP1559Fee {
  final Decimal maxFeePerGasGwei;
  final Decimal maxPriorityFeePerGasGwei;
  final int gasLimit;

  const EthEIP1559Fee({
    required this.maxFeePerGasGwei,
    required this.maxPriorityFeePerGasGwei,
    required this.gasLimit,
  });

  BigInt get maxFeePerGasWei => maxFeePerGasGwei.shift(9).toBigInt();
  BigInt get maxPriorityFeePerGasWei =>
      maxPriorityFeePerGasGwei.shift(9).toBigInt();

  bool get hasValidFeeCaps =>
      maxFeePerGasGwei > Decimal.zero &&
      maxPriorityFeePerGasGwei >= Decimal.zero &&
      maxFeePerGasGwei >= maxPriorityFeePerGasGwei;

  @override
  String toString() =>
      "EthEIP1559Fee("
      "maxFeePerGasGwei: $maxFeePerGasGwei, "
      "maxPriorityFeePerGasGwei: $maxPriorityFeePerGasGwei, "
      "maxFeePerGasWei: $maxFeePerGasWei, "
      "maxPriorityFeePerGasWei: $maxPriorityFeePerGasWei, "
      "gasLimit: $gasLimit)";
}

class EthFeeForm extends StatefulWidget {
  EthFeeForm({
    super.key,
    required this.locale,
    this.minGasLimit = 21000,
    this.maxGasLimit = 30000000,
    this.initialState,
    required this.stateChanged,
  }) : assert(
         initialState == null ||
             (initialState.hasValidFeeCaps &&
                 initialState.gasLimit >= minGasLimit &&
                 initialState.gasLimit <= maxGasLimit),
       );

  final int minGasLimit;
  final int maxGasLimit;
  final String locale;

  final EthEIP1559Fee? initialState;

  final void Function(EthEIP1559Fee?) stateChanged;

  @override
  State<EthFeeForm> createState() => _EthFeeFormState();
}

class _EthFeeFormState extends State<EthFeeForm> {
  static const _textFadeDuration = Duration(milliseconds: 300);

  final maxFeePerGasController = TextEditingController();
  final maxPriorityFeePerGasController = TextEditingController();
  final gasLimitController = TextEditingController();
  final maxFeePerGasFocus = FocusNode();
  final maxPriorityFeePerGasFocus = FocusNode();
  final gasLimitFocus = FocusNode();

  late int _gasLimitCache;
  late Decimal _maxFeePerGasGwei;
  late Decimal _maxPriorityFeePerGasGwei;
  bool _maxFeePerGasIsValid = false;
  bool _maxPriorityFeePerGasIsValid = false;
  bool _gasLimitIsValid = true;

  EthEIP1559Fee get _current => EthEIP1559Fee(
    maxFeePerGasGwei: _maxFeePerGasGwei,
    maxPriorityFeePerGasGwei: _maxPriorityFeePerGasGwei,
    gasLimit: _gasLimitCache,
  );

  // Blank or separator-only input is invalid, not zero: a zero max fee cannot
  // cover a positive network base fee and would fail at build time.
  Amount? _parseFeeInput(String value) {
    return Amount.tryParseEditableAmount(
      value,
      locale: widget.locale,
      fractionDigits: 9,
    );
  }

  void _maxFeePerGasChanged(String value) {
    final amount = _parseFeeInput(value);
    setState(() {
      _maxFeePerGasIsValid = amount != null && amount.raw > BigInt.zero;
      if (amount != null) {
        _maxFeePerGasGwei = amount.decimal;
      }
    });
    _notifyStateChanged();
  }

  void _maxPriorityFeePerGasChanged(String value) {
    final amount = _parseFeeInput(value);
    setState(() {
      _maxPriorityFeePerGasIsValid =
          amount != null && amount.raw >= BigInt.zero;
      if (amount != null) {
        _maxPriorityFeePerGasGwei = amount.decimal;
      }
    });
    _notifyStateChanged();
  }

  bool get _feeCapsAreConsistent =>
      _maxFeePerGasGwei >= _maxPriorityFeePerGasGwei;

  void _notifyStateChanged() {
    widget.stateChanged(
      _maxFeePerGasIsValid &&
              _maxPriorityFeePerGasIsValid &&
              _feeCapsAreConsistent &&
              _gasLimitIsValid
          ? _current
          : null,
    );
  }

  String _currentBase = "Current: ";
  String _currentPriority = "Current: ";
  ({Decimal base, Decimal lowPriority, Decimal highPriority})? _gasOracleFees;

  void _updateGasOracleLabels() {
    final fees = _gasOracleFees;
    if (fees == null) return;

    final currentBaseFee = Amount.formatFixedDecimal(
      fees.base,
      fractionDigits: 3,
      locale: widget.locale,
    );
    final lowPriorityFee = Amount.formatFixedDecimal(
      fees.lowPriority,
      fractionDigits: 3,
      locale: widget.locale,
    );
    final highPriorityFee = Amount.formatFixedDecimal(
      fees.highPriority,
      fractionDigits: 3,
      locale: widget.locale,
    );
    _currentBase = "Current: $currentBaseFee GWEI";
    _currentPriority = "Current: $lowPriorityFee - $highPriorityFee GWEI";
  }

  @override
  void didUpdateWidget(EthFeeForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locale != widget.locale) {
      relocalizeAmountController(
        maxFeePerGasController,
        sourceLocale: oldWidget.locale,
        targetLocale: widget.locale,
      );
      relocalizeAmountController(
        maxPriorityFeePerGasController,
        sourceLocale: oldWidget.locale,
        targetLocale: widget.locale,
      );
      _updateGasOracleLabels();
    }
  }

  void _checkNetworkGas() async {
    final gas = await EthereumAPI.getGasOracle();

    if (mounted && gas.value != null) {
      final fees = (
        base: gas.value!.suggestBaseFee,
        lowPriority: gas.value!.lowPriority,
        highPriority: gas.value!.highPriority,
      );
      setState(() {
        _gasOracleFees = fees;
        _updateGasOracleLabels();
      });
    }
  }

  Timer? _gasTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNetworkGas();
      _gasTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _checkNetworkGas(),
      );
    });

    _gasLimitCache = widget.initialState?.gasLimit ?? widget.minGasLimit;
    _maxFeePerGasGwei = widget.initialState?.maxFeePerGasGwei ?? Decimal.zero;
    _maxPriorityFeePerGasGwei =
        widget.initialState?.maxPriorityFeePerGasGwei ?? Decimal.zero;
    _maxFeePerGasIsValid =
        widget.initialState != null &&
        widget.initialState!.maxFeePerGasGwei > Decimal.zero;
    _maxPriorityFeePerGasIsValid =
        widget.initialState != null &&
        widget.initialState!.maxPriorityFeePerGasGwei >= Decimal.zero;
    final maxFeePerGas = widget.initialState?.maxFeePerGasGwei;
    final maxPriorityFeePerGas = widget.initialState?.maxPriorityFeePerGasGwei;
    maxFeePerGasController.text = maxFeePerGas == null
        ? ""
        : Amount.formatEditableDecimal(maxFeePerGas, locale: widget.locale);
    maxPriorityFeePerGasController.text = maxPriorityFeePerGas == null
        ? ""
        : Amount.formatEditableDecimal(
            maxPriorityFeePerGas,
            locale: widget.locale,
          );
    gasLimitController.text = _gasLimitCache.toString();
  }

  @override
  void dispose() {
    _gasTimer?.cancel();
    _gasTimer = null;
    maxFeePerGasController.dispose();
    maxPriorityFeePerGasController.dispose();
    gasLimitController.dispose();
    maxFeePerGasFocus.dispose();
    maxPriorityFeePerGasFocus.dispose();
    gasLimitFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Max fee per gas (GWEI)", style: STextStyles.smallMed12(context)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
          child: TextField(
            key: const Key("ethMaxFeePerGasField"),
            minLines: 1,
            maxLines: 1,
            controller: maxFeePerGasController,
            readOnly: false,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              AmountInputFormatter(
                controller: maxFeePerGasController,
                decimals: 9,
                locale: widget.locale,
              ),
            ],
            focusNode: maxFeePerGasFocus,
            onChanged: _maxFeePerGasChanged,
            style: Util.isDesktop
                ? STextStyles.desktopTextExtraSmall(context).copyWith(
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.textFieldActiveText,
                    height: 1.8,
                  )
                : STextStyles.field(context),
            decoration:
                standardInputDecoration(
                  null,
                  maxFeePerGasFocus,
                  context,
                  desktopMed: Util.isDesktop,
                ).copyWith(
                  contentPadding: EdgeInsets.only(
                    left: 16,
                    top: Util.isDesktop ? 11 : 6,
                    bottom: Util.isDesktop ? 12 : 8,
                    right: 5,
                  ),
                ),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: _textFadeDuration,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Text(
            _currentBase,
            key: ValueKey(
              _currentBase,
            ), // Important: ensures AnimatedSwitcher sees the text change
            style: STextStyles.smallMed12(context),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Max priority fee per gas (GWEI)",
          style: STextStyles.smallMed12(context),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
          child: TextField(
            key: const Key("ethMaxPriorityFeePerGasField"),
            minLines: 1,
            maxLines: 1,
            controller: maxPriorityFeePerGasController,
            readOnly: false,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              AmountInputFormatter(
                controller: maxPriorityFeePerGasController,
                decimals: 9,
                locale: widget.locale,
              ),
            ],
            focusNode: maxPriorityFeePerGasFocus,
            onChanged: _maxPriorityFeePerGasChanged,
            style: Util.isDesktop
                ? STextStyles.desktopTextExtraSmall(context).copyWith(
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.textFieldActiveText,
                    height: 1.8,
                  )
                : STextStyles.field(context),
            decoration:
                standardInputDecoration(
                  null,
                  maxPriorityFeePerGasFocus,
                  context,
                  desktopMed: Util.isDesktop,
                ).copyWith(
                  contentPadding: EdgeInsets.only(
                    left: 16,
                    top: Util.isDesktop ? 11 : 6,
                    bottom: Util.isDesktop ? 12 : 8,
                    right: 5,
                  ),
                ),
          ),
        ),
        if (_maxFeePerGasIsValid &&
            _maxPriorityFeePerGasIsValid &&
            !_feeCapsAreConsistent)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              "Max priority fee must not exceed max fee",
              style: STextStyles.errorSmall(context),
            ),
          ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: _textFadeDuration,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Text(
            _currentPriority,
            key: ValueKey(
              _currentPriority,
            ), // Important: ensures AnimatedSwitcher sees the text change
            style: STextStyles.smallMed12(context),
          ),
        ),
        const SizedBox(height: 20),
        Text("Gas limit", style: STextStyles.smallMed12(context)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
          child: TextField(
            key: const Key("ethFeeGasLimitField"),
            minLines: 1,
            maxLines: 1,
            controller: gasLimitController,
            readOnly: false,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.number,
            focusNode: gasLimitFocus,
            onChanged: (value) {
              final intValue = tryParseIntegerInput(
                value,
                minimum: widget.minGasLimit,
                maximum: widget.maxGasLimit,
              );
              setState(() {
                _gasLimitIsValid = intValue != null;
                if (intValue != null) {
                  _gasLimitCache = intValue;
                }
              });
              _notifyStateChanged();
            },
            style: Util.isDesktop
                ? STextStyles.desktopTextExtraSmall(context).copyWith(
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.textFieldActiveText,
                    height: 1.8,
                  )
                : STextStyles.field(context),
            decoration:
                standardInputDecoration(
                  null,
                  gasLimitFocus,
                  context,
                  desktopMed: Util.isDesktop,
                ).copyWith(
                  contentPadding: EdgeInsets.only(
                    left: 16,
                    top: Util.isDesktop ? 11 : 6,
                    bottom: Util.isDesktop ? 12 : 8,
                    right: 5,
                  ),
                ),
          ),
        ),
        if (!_gasLimitIsValid)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              "Enter a whole number from "
              "${widget.minGasLimit} to ${widget.maxGasLimit}",
              style: STextStyles.errorSmall(context),
            ),
          ),
      ],
    );
  }
}
