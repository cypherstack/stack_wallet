import 'package:flutter/material.dart';

class PayNymBot extends StatelessWidget {
  const PayNymBot({
    Key? key,
    required this.paymentCodeString,
    this.size = 60.0,
  }) : super(key: key);

  final String paymentCodeString;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          "https://paynym.is/$paymentCodeString/avatar",
          // todo: loading indicator that doesn't lag
        ),
      ),
    );
  }
}
