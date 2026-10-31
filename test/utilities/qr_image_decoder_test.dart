import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:stackwallet/utilities/qr_image_decoder.dart';
import 'package:zxing2/qrcode.dart';

const _address = "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq";

/// Renders [text] as a black-on-white QR code in 8-bit RGB.
img.Image _qrImage(String text, {int scale = 8, int border = 4}) {
  final matrix = Encoder.encode(text, ErrorCorrectionLevel.m).matrix!;
  final size = (matrix.width + 2 * border) * scale;
  final image = img.Image(width: size, height: size);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));
  for (var y = 0; y < matrix.height; y++) {
    for (var x = 0; x < matrix.width; x++) {
      if (matrix.get(x, y) == 1) {
        img.fillRect(
          image,
          x1: (x + border) * scale,
          y1: (y + border) * scale,
          x2: (x + border + 1) * scale - 1,
          y2: (y + border + 1) * scale - 1,
          color: img.ColorRgb8(0, 0, 0),
        );
      }
    }
  }
  return image;
}

Uint8List _png(img.Image image) => Uint8List.fromList(img.encodePng(image));

void main() {
  final rgb = _qrImage(_address);

  final variants = <String, img.Image>{
    "1-bit grayscale": rgb.convert(format: img.Format.uint1, numChannels: 1),
    "1-bit palette": rgb.convert(
      format: img.Format.uint1,
      numChannels: 1,
      withPalette: true,
    ),
    "8-bit grayscale": rgb.convert(numChannels: 1),
    "8-bit palette": img.quantize(rgb, numberOfColors: 2),
    "16-bit grayscale": rgb.convert(format: img.Format.uint16, numChannels: 1),
    "8-bit RGB": rgb,
    "8-bit RGBA": rgb.convert(numChannels: 4),
  };

  for (final entry in variants.entries) {
    test("decodes a ${entry.key} PNG", () {
      final bytes = _png(entry.value);
      final decoded = img.decodePng(bytes)!;
      expect(decoded.width, rgb.width);
      expect(decodeQrFromImageBytes(bytes), _address);
    });
  }

  test("decodes a 1-bit PNG with a 1-bit format after decoding", () {
    final decoded = img.decodePng(
      _png(rgb.convert(format: img.Format.uint1, numChannels: 1)),
    )!;
    // This is the case the old code got wrong: convert(numChannels: 4) kept
    // the 1-bit format and handed bit-packed bytes to RGBLuminanceSource.
    expect(decoded.format, img.Format.uint1);
    expect(decodeQrFromImage(decoded), _address);
  });

  test("decodes a large camera-sized frame scaled down to maxDimension", () {
    // A QR code held up to a 3264x2448 webcam, filling about a third of the
    // frame's height.
    final frame = img.Image(width: 3264, height: 2448);
    img.fill(frame, color: img.ColorRgb8(200, 200, 200));
    final code = _qrImage(_address, scale: 18);
    img.compositeImage(frame, code, dstX: 1200, dstY: 700);
    final jpeg = img.decodeJpg(img.encodeJpg(frame, quality: 85))!;
    expect(decodeQrFromImage(jpeg, maxDimension: 1280), _address);
  });

  test("leaves images within maxDimension alone", () {
    expect(decodeQrFromImage(rgb, maxDimension: 1280), _address);
  });

  test("decodes a JPEG", () {
    final bytes = Uint8List.fromList(img.encodeJpg(rgb, quality: 85));
    expect(decodeQrFromImageBytes(bytes), _address);
  });

  test("decodes a black-on-transparent RGBA PNG", () {
    final image = img.Image(
      width: rgb.width,
      height: rgb.height,
      numChannels: 4,
    );
    for (final p in rgb) {
      final dark = p.r < 128;
      image.setPixelRgba(p.x, p.y, 0, 0, 0, dark ? 255 : 0);
    }
    expect(decodeQrFromImageBytes(_png(image)), _address);
  });

  test("returns null for an image without a QR code", () {
    final blank = img.Image(width: 64, height: 64);
    img.fill(blank, color: img.ColorRgb8(255, 255, 255));
    expect(decodeQrFromImageBytes(_png(blank)), isNull);
  });

  test("returns null for bytes that are not an image", () {
    expect(decodeQrFromImageBytes(Uint8List.fromList([1, 2, 3, 4])), isNull);
  });
}
