import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:stackwallet/utilities/camera_preview_frame.dart';
import 'package:zxing2/qrcode.dart';

const _text = "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq";

/// Paints a QR code with a red marker in its top-left corner, so a capture
/// shows whether it was flipped.
class _QrPainter extends CustomPainter {
  _QrPainter(this.modules);

  /// True for dark modules, row by row.
  final List<List<bool>> modules;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    const border = 4;
    final module = size.width / (modules.length + 2 * border);
    final black = Paint()
      ..color = Colors.black
      // Hairline seams between anti-aliased modules throw off zxing.
      ..isAntiAlias = false;
    for (var y = 0; y < modules.length; y++) {
      for (var x = 0; x < modules[y].length; x++) {
        if (modules[y][x]) {
          canvas.drawRect(
            Rect.fromLTWH(
              (x + border) * module,
              (y + border) * module,
              module,
              module,
            ),
            black,
          );
        }
      }
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, module * 2, module * 2),
      Paint()..color = const Color(0xFFFF0000),
    );
  }

  @override
  bool shouldRepaint(_QrPainter oldDelegate) => false;
}

void main() {
  testWidgets("reads a QR code back from a mirrored preview capture", (
    tester,
  ) async {
    final matrix = Encoder.encode(_text, ErrorCorrectionLevel.m).matrix!;
    final modules = [
      for (var y = 0; y < matrix.height; y++)
        [for (var x = 0; x < matrix.width; x++) matrix.get(x, y) == 1],
    ];
    // Whole logical pixels per module.
    final side = (modules.length + 8) * 4.0;
    final key = GlobalKey();
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: key,
          child: SizedBox(
            width: side,
            height: side,
            // Mirrored like the camera_windows preview.
            child: Transform.flip(
              flipX: true,
              child: CustomPaint(painter: _QrPainter(modules)),
            ),
          ),
        ),
      ),
    );

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final (width, height, rgba) = (await tester.runAsync(() async {
      final frame = await boundary.toImage(pixelRatio: 2);
      try {
        final bytes = await frame.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        return (frame.width, frame.height, bytes!.buffer.asUint8List());
      } finally {
        frame.dispose();
      }
    }))!;

    expect((width, height), (side * 2, side * 2));
    expect(blankPreviewFrame(rgba), isNull);

    final image = imageFromMirroredPreviewRgba(
      rgba,
      width: width,
      height: height,
    );

    // The marker is back in the top-left once flipped.
    final marker = image.getPixel(4, 4);
    expect([marker.r, marker.g, marker.b], [255, 0, 0]);
    final opposite = image.getPixel(width - 5, 4);
    expect([opposite.r, opposite.g, opposite.b], [255, 255, 255]);

    final source = RGBLuminanceSource(
      width,
      height,
      image.getBytes(order: img.ChannelOrder.abgr).buffer.asInt32List(),
    );
    final result = QRCodeReader().decode(BinaryBitmap(HybridBinarizer(source)));
    expect(result.text, _text);
  });

  testWidgets("sees a capture with nothing painted as transparent", (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: key,
          child: const SizedBox(width: 50, height: 40),
        ),
      ),
    );

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final rgba = (await tester.runAsync(() async {
      final frame = await boundary.toImage();
      try {
        final bytes = await frame.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        return bytes!.buffer.asUint8List();
      } finally {
        frame.dispose();
      }
    }))!;

    expect(blankPreviewFrame(rgba), BlankPreviewFrame.transparent);
  });
}
