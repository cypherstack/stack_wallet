import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../services/ethereum/ethereum_api.dart';
import '../themes/stack_colors.dart';
import '../utilities/constants.dart';
import '../utilities/text_styles.dart';
import '../utilities/util.dart';
import 'stack_text_field.dart';

@immutable
class EthEIP1559Fee {
  final Decimal maxBaseFeeGwei;
  final Decimal priorityFeeGwei;
  final int gasLimit;

  const EthEIP1559Fee({
    required this.maxBaseFeeGwei,
    required this.priorityFeeGwei,
    required this.gasLimit,
  });

  BigInt get maxBaseFeeWei => maxBaseFeeGwei.shift(9).toBigInt();
  BigInt get priorityFeeWei => priorityFeeGwei.shift(9).toBigInt();

  @override
  String toString() =>
      "EthEIP1559Fee("
      "maxBaseFeeGwei: $maxBaseFeeGwei, "
      "priorityFeeGwei: $priorityFeeGwei, "
      "maxBaseFeeWei: $maxBaseFeeWei, "
      "priorityFeeWei: $priorityFeeWei, "
      "gasLimit: $gasLimit)";
}

class EthFeeForm extends StatefulWidget {
  EthFeeForm({
    super.key,
    this.minGasLimit = 21000,
    this.maxGasLimit = 30000000,
    this.initialState,
    required this.stateChanged,
  }) : assert(
         initialState == null ||
             (initialState.gasLimit >= minGasLimit &&
                 initialState.gasLimit <= maxGasLimit),
       );

  final int minGasLimit;
  final int maxGasLimit;

  final EthEIP1559Fee? initialState;

  final void Function(EthEIP1559Fee) stateChanged;

  @override
  State<EthFeeForm> createState() => _EthFeeFormState();
}

class _EthFeeFormState extends State<EthFeeForm> {
  static const _textFadeDuration = Duration(milliseconds: 300);

  final maxBaseController = TextEditingController();
  final priorityFeeController = TextEditingController();
  final gasLimitController = TextEditingController();
  final maxBaseFocus = FocusNode();
  final priorityFeeFocus = FocusNode();
  final gasLimitFocus = FocusNode();

  late int _gasLimitCache;

  EthEIP1559Fee get _current => EthEIP1559Fee(
    maxBaseFeeGwei: Decimal.tryParse(maxBaseController.text) ?? Decimal.zero,
    priorityFeeGwei:
        Decimal.tryParse(priorityFeeController.text) ?? Decimal.zero,
    gasLimit: int.parse(gasLimitController.text),
  );

  String _currentBase = "Current: ";
  String _currentPriority = "Current: ";

  void _checkNetworkGas() async {
    final gas = await EthereumAPI.getGasOracle();

    if (mounted) {
      setState(() {
        _currentBase =
            "Current: ${gas.value!.suggestBaseFee.toStringAsFixed(3)} GWEI";
        _currentPriority =
            "Current: ${gas.value!.lowPriority.toStringAsFixed(3)} - ${gas.value!.highPriority.toStringAsFixed(3)} GWEI";
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

    maxBaseController.text =
        widget.initialState?.maxBaseFeeGwei.toString() ?? "";
    priorityFeeController.text =
        widget.initialState?.priorityFeeGwei.toString() ?? "";

    _gasLimitCache = widget.initialState?.gasLimit ?? widget.minGasLimit;
    gasLimitController.text = _gasLimitCache.toString();
  }

  @override
  void dispose() {
    _gasTimer?.cancel();
    _gasTimer = null;
    maxBaseController.dispose();
    priorityFeeController.dispose();
    gasLimitController.dispose();
    maxBaseFocus.dispose();
    priorityFeeFocus.dispose();
    gasLimitFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Max base fee (GWEI)", style: STextStyles.smallMed12(context)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
          child: TextField(
            minLines: 1,
            maxLines: 1,
            controller: maxBaseController,
            readOnly: false,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            focusNode: maxBaseFocus,
            onChanged: (value) {
              widget.stateChanged(_current);
            },
            style:
                Util.isDesktop
                    ? STextStyles.desktopTextExtraSmall(context).copyWith(
                      color:
                          Theme.of(
                            context,
                          ).extension<StackColors>()!.textFieldActiveText,
                      height: 1.8,
                    )
                    : STextStyles.field(context),
            decoration: standardInputDecoration(
              null,
              maxBaseFocus,
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
          transitionBuilder:
              (child, animation) =>
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
        Text("Priority fee (GWEI)", style: STextStyles.smallMed12(context)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
          child: TextField(
            minLines: 1,
            maxLines: 1,
            controller: priorityFeeController,
            readOnly: false,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            focusNode: priorityFeeFocus,
            onChanged: (value) {
              widget.stateChanged(_current);
            },
            style:
                Util.isDesktop
                    ? STextStyles.desktopTextExtraSmall(context).copyWith(
                      color:
                          Theme.of(
                            context,
                          ).extension<StackColors>()!.textFieldActiveText,
                      height: 1.8,
                    )
                    : STextStyles.field(context),
            decoration: standardInputDecoration(
              null,
              priorityFeeFocus,
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
          transitionBuilder:
              (child, animation) =>
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
            minLines: 1,
            maxLines: 1,
            controller: gasLimitController,
            readOnly: false,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            focusNode: gasLimitFocus,
            onChanged: (value) {
              final intValue = int.tryParse(value);
              if (intValue == null) {
                gasLimitController.text = _gasLimitCache.toString();
                return;
              }

              _gasLimitCache = intValue;

              widget.stateChanged(_current);
            },
            style:
                Util.isDesktop
                    ? STextStyles.desktopTextExtraSmall(context).copyWith(
                      color:
                          Theme.of(
                            context,
                          ).extension<StackColors>()!.textFieldActiveText,
                      height: 1.8,
                    )
                    : STextStyles.field(context),
            decoration: standardInputDecoration(
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
      ],
    );
  }
}
