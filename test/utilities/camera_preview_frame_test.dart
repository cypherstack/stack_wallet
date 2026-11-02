import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:stackwallet/utilities/camera_preview_frame.dart';

/// Packs one RGBA pixel per entry, in row order.
Uint8List _rgba(List<List<int>> pixels) =>
    Uint8List.fromList([for (final p in pixels) ...p]);

void main() {
  group("imageFromMirroredPreviewRgba", () {
    test("flips each row back", () {
      // 3x2, every pixel distinct.
      final rgba = _rgba([
        [1, 2, 3, 255], [4, 5, 6, 255], [7, 8, 9, 255], //
        [10, 11, 12, 255], [13, 14, 15, 255], [16, 17, 18, 255],
      ]);

      final image = imageFromMirroredPreviewRgba(rgba, width: 3, height: 2);

      expect(image.width, 3);
      expect(image.height, 2);
      expect(image.numChannels, 4);
      List<num> rgbaAt(int x, int y) {
        final p = image.getPixel(x, y);
        return [p.r, p.g, p.b, p.a];
      }

      expect(rgbaAt(0, 0), [7, 8, 9, 255]);
      expect(rgbaAt(1, 0), [4, 5, 6, 255]);
      expect(rgbaAt(2, 0), [1, 2, 3, 255]);
      expect(rgbaAt(0, 1), [16, 17, 18, 255]);
      expect(rgbaAt(2, 1), [10, 11, 12, 255]);
    });

    test("undoes a mirrored capture of a whole image", () {
      final original = img.Image(width: 40, height: 30, numChannels: 4);
      for (final p in original) {
        p
          ..r = (p.x * 6) % 256
          ..g = (p.y * 8) % 256
          ..b = (p.x + p.y) % 256
          ..a = 255;
      }
      final mirrored = img.flipHorizontal(original.clone());
      final rgba = mirrored.getBytes(order: img.ChannelOrder.rgba);

      final image = imageFromMirroredPreviewRgba(rgba, width: 40, height: 30);

      expect(
        image.getBytes(order: img.ChannelOrder.rgba),
        original.getBytes(order: img.ChannelOrder.rgba),
      );
    });

    test("accepts bytes at an unaligned offset", () {
      final backing = Uint8List(1 + 2 * 4);
      backing.setAll(1, [1, 2, 3, 255, 4, 5, 6, 255]);
      final view = Uint8List.view(backing.buffer, 1, 8);

      final image = imageFromMirroredPreviewRgba(view, width: 2, height: 1);

      expect(image.getPixel(0, 0).r, 4);
      expect(image.getPixel(1, 0).r, 1);
    });

    test("rejects a buffer that is too short", () {
      expect(
        () => imageFromMirroredPreviewRgba(Uint8List(15), width: 2, height: 2),
        throwsArgumentError,
      );
      expect(
        () => imageFromMirroredPreviewRgba(Uint8List(0), width: 0, height: 0),
        throwsArgumentError,
      );
    });
  });

  group("blankPreviewFrame", () {
    test("reports a frame with nothing drawn as transparent", () {
      expect(
        blankPreviewFrame(Uint8List(4 * 16)),
        BlankPreviewFrame.transparent,
      );
      expect(blankPreviewFrame(Uint8List(0)), BlankPreviewFrame.transparent);
    });

    test("reports black and near-black frames as black", () {
      expect(
        blankPreviewFrame(_rgba(List.filled(16, [0, 0, 0, 255]))),
        BlankPreviewFrame.black,
      );
      expect(
        blankPreviewFrame(
          _rgba([
            [3, 9, 1, 255],
            [16, 12, 0, 255],
            [0, 0, 0, 0],
          ]),
        ),
        BlankPreviewFrame.black,
      );
    });

    test("accepts a frame with any picture content", () {
      expect(
        blankPreviewFrame(
          _rgba([
            [0, 0, 0, 0],
            [0, 0, 0, 255],
            [0, 0, 200, 255],
          ]),
        ),
        isNull,
      );
    });

    test("ignores color in fully transparent pixels", () {
      expect(
        blankPreviewFrame(
          _rgba([
            [255, 255, 255, 0],
            [0, 0, 0, 0],
          ]),
        ),
        BlankPreviewFrame.transparent,
      );
    });
  });
}
