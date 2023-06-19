import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class FeeSlider extends StatefulWidget {
  const FeeSlider({
    super.key,
    required this.onSatVByteChanged,
  });

  final void Function(int) onSatVByteChanged;

  @override
  State<FeeSlider> createState() => _FeeSliderState();
}

class _FeeSliderState extends State<FeeSlider> {
  static const int min = 1;
  static const int max = 4;

  double sliderValue = 0;

  int rate = min;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "sat/vByte",
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
              rate = pow(sliderValue * (max - min) + min, 4).toInt();
            });
            widget.onSatVByteChanged(rate);
          },
        ),
      ],
    );
  }
}
