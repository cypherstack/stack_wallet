import 'package:flutter/material.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';

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
      child: Stack(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const LoadingIndicator(),
          ),
          SizedBox(
            width: size,
            height: size,
            child: Image.network(
              "https://paynym.is/$paymentCodeString/avatar",
            ),
          ),
        ],
      ),
    );
  }
}
