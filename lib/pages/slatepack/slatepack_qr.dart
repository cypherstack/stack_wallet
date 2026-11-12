import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../themes/stack_colors.dart';
import '../../utilities/text_styles.dart';
import '../../widgets/qr.dart';
import '../../widgets/rounded_container.dart';

/// Most bytes one QR code holds: version 40 in byte mode at error correction
/// level L, which is the level [QR] draws at. Anything up to that is drawn. A
/// code near the limit is dense, and tapping it shows it full size.
const kSlatepackQrMaxBytes = 2953;

bool slatepackFitsQr(String text) =>
    utf8.encode(text).length <= kSlatepackQrMaxBytes;

/// QR code for a slatepack, or a note when it is too long for one. Tapping
/// the code shows it full size.
class SlatepackQr extends StatelessWidget {
  const SlatepackQr({
    super.key,
    required this.data,
    required this.noun,
    this.size = 220,
  });

  final String data;

  /// "slate" or "slatepack", for the too-long note.
  final String noun;
  final double size;

  Future<void> _enlarge(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final side = math.min(math.min(screen.width, screen.height) - 64, 640.0);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => GestureDetector(
        onTap: () => Navigator.of(dialogContext).pop(),
        child: Center(
          child: QR(data: data, size: side),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!slatepackFitsQr(data)) {
      return RoundedContainer(
        key: const Key("slatepackQrTooLong"),
        color: Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
        child: Text(
          "This $noun is too long for a QR code. "
          "Copy, share or save it instead.",
          style: STextStyles.label(context),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          key: const Key("slatepackQrCode"),
          onTap: () => _enlarge(context),
          child: QR(data: data, size: size),
        ),
        const SizedBox(height: 4),
        Text("Tap to enlarge", style: STextStyles.label(context)),
      ],
    );
  }
}
