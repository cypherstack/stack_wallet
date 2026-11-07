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

  /// Shown instead of the code when [data] does not fit in one. Defaults to
  /// a short message.
  final QrErrorBuilder? errorStateBuilder;

  /// Whether [data] fits in a level L code. qr 3 only finds out while
  /// painting, after qr_flutter's own validation passed, so oversized data
  /// would throw during build instead of reaching errorStateBuilder.
  static Object? _encodingError(String data) {
    try {
      QrImage.withMaskPattern(
        QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.L),
        0,
      );
      return null;
    } on InputTooLongException catch (e) {
      return e;
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorBuilder = errorStateBuilder ?? _defaultError;
    final error = _encodingError(data);
    if (error != null) {
      return SizedBox(
        width: size,
        height: size,
        child: errorBuilder(context, error),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: QrImageView(
        data: data,
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
