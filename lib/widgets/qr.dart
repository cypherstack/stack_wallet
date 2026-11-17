import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Centralised Qr code image widget
class QR extends StatelessWidget {
  const QR({
    super.key,
    required this.data,
    this.size,
    this.padding,
    this.errorStateBuilder,
  });

  final String data;
  final double? size;
  final EdgeInsets? padding;

  /// Shown instead of the code when [data] does not fit in one.
  final QrErrorBuilder? errorStateBuilder;

  @override
  Widget build(BuildContext context) {
    final errorBuilder = errorStateBuilder ?? _defaultError;
    late final QrCode qr;
    try {
      qr = QrCode.fromData(
        data: data,
        errorCorrectLevel: QrErrorCorrectLevel.L,
      );
      // fromData selects a version, but qr only discovers that version 40 is
      // also too small when its encoded bytes are requested. QrImageView uses
      // this cached data, so validation does not encode the QR a second time.
      // ignore: invalid_use_of_internal_member
      qr.dataCache;
    } catch (error) {
      return SizedBox(
        width: size,
        height: size,
        child: errorBuilder(context, error),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: QrImageView.withQr(
        qr: qr,
        size: size,
        padding: padding ?? const EdgeInsets.all(10),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        errorStateBuilder: errorBuilder,
        // backgroundColor:
        // Theme.of(context).extension<StackColors>()!.background,
        // foregroundColor: Theme.of(context)
        //     .extension<StackColors>()!
        //     .accentColorDark,
      ),
    );
  }

  static Widget _defaultError(BuildContext context, Object? error) {
    return const ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            "Too much data to show as a QR code",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }
}
