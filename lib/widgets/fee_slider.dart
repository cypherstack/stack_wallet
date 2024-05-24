import 'dart:math';

import 'package:flutter/material.dart';
import '../utilities/text_styles.dart';
import '../wallets/crypto_currency/coins/dogecoin.dart';
import '../wallets/crypto_currency/crypto_currency.dart';

class FeeSlider extends StatefulWidget {
  const FeeSlider({
    super.key,
    required this.onSatVByteChanged,
    required this.coin,
    this.showWU = false,
  });

  final CryptoCurrency coin;
  final bool showWU;
  final void Function(int) onSatVByteChanged;

  @override
  State<FeeSlider> createState() => _FeeSliderState();
}

class _FeeSliderState extends State<FeeSlider> {
  static const double min = 1;
  static const double max = 4;

  double sliderValue = 0;

  int rate = min.toInt();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.showWU ? "sat/WU" : "sat/vByte",
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
              final number = pow(sliderValue * (max - min) + min, 4).toDouble();
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
