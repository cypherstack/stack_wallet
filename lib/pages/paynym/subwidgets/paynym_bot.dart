import 'package:flutter/material.dart';
import 'package:stackduo/widgets/loading_indicator.dart';

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
          loadingBuilder: (context, child, loadingProgress) =>
              loadingProgress == null
                  ? child
                  : const Center(
                      child: LoadingIndicator(),
                    ),
        ),
      ),
    );
  }
}
