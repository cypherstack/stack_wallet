import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../themes/stack_colors.dart';
import '../utilities/constants.dart';
import '../utilities/text_styles.dart';
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

  @override
  String toString() =>
      "EthEIP1559Fee("
      "maxBaseFeeGwei: $maxBaseFeeGwei, "
      "priorityFeeGwei: $priorityFeeGwei, "
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
  final maxBaseController = TextEditingController();
  final priorityFeeController = TextEditingController();
  final maxBaseFocus = FocusNode();
  final priorityFeeFocus = FocusNode();

  late int gasLimit;
  double _sliderValue = 0;

  @override
  void initState() {
    super.initState();

    maxBaseController.text =
        widget.initialState?.maxBaseFeeGwei.toString() ?? "";
    priorityFeeController.text =
        widget.initialState?.priorityFeeGwei.toString() ?? "";

    gasLimit = widget.initialState?.gasLimit ?? widget.minGasLimit;
    print("asgLimit: $gasLimit");
  }

  @override
  void dispose() {
    maxBaseController.dispose();
    priorityFeeController.dispose();
    maxBaseFocus.dispose();
    priorityFeeFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Max base fee (GWEI)",
            style: STextStyles.smallMed12(context)
        ),
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
              widget.stateChanged(
                EthEIP1559Fee(
                  maxBaseFeeGwei: Decimal.tryParse(value) ?? Decimal.zero,
                  priorityFeeGwei:
                      Decimal.tryParse(priorityFeeController.text) ??
                      Decimal.zero,
                  gasLimit: gasLimit,
                ),
              );
            },
            style: STextStyles.desktopTextExtraSmall(context).copyWith(
              color:
                  Theme.of(
                    context,
                  ).extension<StackColors>()!.textFieldActiveText,
              height: 1.8,
            ),
            decoration: standardInputDecoration(
              "Leave empty to auto select nonce",
              maxBaseFocus,
              context,
              desktopMed: true,
            ).copyWith(
              contentPadding: const EdgeInsets.only(
                left: 16,
                top: 11,
                bottom: 12,
                right: 5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Max base fee (GWEI)",
            style: STextStyles.smallMed12(context)
        ),
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
              widget.stateChanged(
                EthEIP1559Fee(
                  maxBaseFeeGwei:
                      Decimal.tryParse(maxBaseController.text) ?? Decimal.zero,
                  priorityFeeGwei: Decimal.tryParse(value) ?? Decimal.zero,
                  gasLimit: gasLimit,
                ),
              );
            },
            style: STextStyles.desktopTextExtraSmall(context).copyWith(
              color:
                  Theme.of(
                    context,
                  ).extension<StackColors>()!.textFieldActiveText,
              height: 1.8,
            ),
            decoration: standardInputDecoration(
              "Leave empty to auto select nonce",
              priorityFeeFocus,
              context,
              desktopMed: true,
            ).copyWith(
              contentPadding: const EdgeInsets.only(
                left: 16,
                top: 11,
                bottom: 12,
                right: 5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Gas limit", style: STextStyles.smallMed12(context)),
            Text("$gasLimit", style: STextStyles.smallMed12(context)),
          ],
        ),
        Slider(
          value: _sliderValue,
          onChanged: (value) {
            setState(() {
              _sliderValue = value;
              final number =
                  (_sliderValue * (widget.maxGasLimit - widget.minGasLimit) +
                          widget.minGasLimit)
                      .toDouble();

              gasLimit = number.toInt();
            });
            widget.stateChanged(
              EthEIP1559Fee(
                maxBaseFeeGwei:
                    Decimal.tryParse(maxBaseController.text) ?? Decimal.zero,
                priorityFeeGwei:
                    Decimal.tryParse(priorityFeeController.text) ??
                    Decimal.zero,
                gasLimit: gasLimit,
              ),
            );
          },
        ),
      ],
    );
  }
}
