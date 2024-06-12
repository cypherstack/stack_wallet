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
      BigInt? value =
          BigInt.tryParse(_textEditingController.text.replaceAll(',', ''));
      if (value != null && value >= widget.min && value <= widget.max) {
        setState(() {
          _currentSliderValue = value.toDouble();
          widget.onFeeChanged(value);
        });
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
              SizedBox(width: 16),
              Container(
                width: 122,
                child: TextField(
                  controller: _textEditingController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    BigInt? newValue =
                        BigInt.tryParse(value.replaceAll(',', ''));
                    if (newValue != null &&
                        newValue >= widget.min &&
                        newValue <= widget.max) {
                      setState(() {
                        _currentSliderValue = newValue.toDouble();
                        widget.onFeeChanged(newValue);
                      });
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
