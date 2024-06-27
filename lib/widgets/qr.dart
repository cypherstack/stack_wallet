import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Centralised Qr code image widget
class QR extends StatelessWidget {
  const QR({super.key, required this.data, this.size, this.padding});

  final String data;
  final double? size;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: data,
      size: size,
      padding: padding ?? const EdgeInsets.all(10),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      // backgroundColor:
      // Theme.of(context).extension<StackColors>()!.background,
      // foregroundColor: Theme.of(context)
      //     .extension<StackColors>()!
      //     .accentColorDark,
    );
  }
}
