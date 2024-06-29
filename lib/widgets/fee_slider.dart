import 'dart:math';

import 'package:flutter/material.dart';

import '../utilities/text_styles.dart';
import '../wallets/crypto_currency/crypto_currency.dart';

/// This has limitations. At least one of [pow] or [min] must be set to 1
class FeeSlider extends StatefulWidget {
  const FeeSlider({
    super.key,
    required this.onSatVByteChanged,
    required this.coin,
    this.min = 1,
    this.max = 5,
    this.pow = 4,
    this.showWU = false,
    this.overrideLabel,
  });

  final CryptoCurrency coin;
  final double min;
  final double max;
  final double pow;
  final bool showWU;
  final void Function(int) onSatVByteChanged;
  final String? overrideLabel;

  @override
  State<FeeSlider> createState() => _FeeSliderState();
}

class _FeeSliderState extends State<FeeSlider> {
  double sliderValue = 0;

  late int rate;

  @override
  void initState() {
    rate = widget.min.toInt();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.overrideLabel ?? (widget.showWU ? "sat/WU" : "sat/vByte"),
              style: STextStyles.smallMed12(context),
            ),
            Text(
              "$rate",
              style: STextStyles.smallMed12(context),
            ),
          ],
        ),
        Slider(
          value: sliderValue,
          onChanged: (value) {
            setState(() {
              sliderValue = value;
              final number = pow(
                sliderValue * (widget.max - widget.min) + widget.min,
                widget.pow,
              ).toDouble();
              if (widget.coin is Dogecoin) {
                rate = (number * 1000).toInt();
              } else {
                rate = number.toInt();
              }
            });
            widget.onSatVByteChanged(rate);
          },
        ),
      ],
    );
  }
}
