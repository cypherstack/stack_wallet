import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utilities/amount/amount.dart';
import '../utilities/amount/amount_formatter.dart';
import '../wallets/crypto_currency/crypto_currency.dart'; // Update with your actual path

class BoostFeeSlider extends ConsumerStatefulWidget {
  final CryptoCurrency coin;
  final Function(BigInt) onFeeChanged;
  final BigInt min;
  final BigInt max;

  BoostFeeSlider({
    super.key,
    required this.coin,
    required this.onFeeChanged,
    required this.min,
    required this.max,
  });

  @override
  _BoostFeeSliderState createState() => _BoostFeeSliderState();
}

class _BoostFeeSliderState extends ConsumerState<BoostFeeSlider> {
  double _currentSliderValue = 0;
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _currentSliderValue = widget.min.toDouble();
    _textEditingController = TextEditingController(
      text: ref.read(pAmountFormatter(widget.coin)).format(
            Amount(
                rawValue: BigInt.from(_currentSliderValue),
                fractionDigits: widget.coin.fractionDigits),
            withUnitName: false,
          ),
    );
    _textEditingController.addListener(() {
      final double? value =
          double.tryParse(_textEditingController.text.replaceAll(',', ''));
      if (value != null) {
        final BigInt bigIntValue = BigInt.from(
            value * BigInt.from(10).pow(widget.coin.fractionDigits).toInt());
        if (bigIntValue >= widget.min && bigIntValue <= widget.max) {
          setState(() {
            _currentSliderValue = value;
            widget.onFeeChanged(bigIntValue);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _currentSliderValue,
                  min: widget.min.toDouble(),
                  max: widget.max.toDouble(),
                  divisions: (widget.max - widget.min).toInt(),
                  label: ref.read(pAmountFormatter(widget.coin)).format(Amount(
                      rawValue: BigInt.from(_currentSliderValue),
                      fractionDigits: widget.coin.fractionDigits)),
                  onChanged: (value) {
                    setState(() {
                      _currentSliderValue = value;
                      _textEditingController.text = ref
                          .read(pAmountFormatter(widget.coin))
                          .format(Amount(
                              rawValue: BigInt.from(_currentSliderValue),
                              fractionDigits: widget.coin.fractionDigits));
                      widget.onFeeChanged(BigInt.from(_currentSliderValue));
                    });
                  },
                ),
              ),
              SizedBox(
                width: 16 + // Left and right padding.
                    122 / 8 * widget.coin.fractionDigits + // Variable width.
                    8 * widget.coin.ticker.length, // End padding for ticker.
                child: TextField(
                  controller: _textEditingController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final double? newValue =
                        double.tryParse(value.replaceAll(',', ''));
                    if (newValue != null) {
                      final BigInt bigIntValue = BigInt.from(newValue *
                          BigInt.from(10)
                              .pow(widget.coin.fractionDigits)
                              .toInt());
                      if (bigIntValue >= widget.min &&
                          bigIntValue <= widget.max) {
                        setState(() {
                          _currentSliderValue = newValue;
                          widget.onFeeChanged(bigIntValue);
                        });
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
