import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

/// Decodes a QR code from encoded image bytes (PNG, JPEG, or anything else
/// the image package can read). Returns null if the bytes can't be decoded as
/// an image or no QR code is found.
String? decodeQrFromImageBytes(Uint8List bytes) {
  final img.Image? image;
  try {
    image = img.decodeImage(bytes);
  } catch (_) {
    return null;
  }
  return image == null ? null : decodeQrFromImage(image);
}

/// Decodes a QR code from [image], whatever its bit depth, channel count or
/// palette. Returns null if no QR code is found.
String? decodeQrFromImage(img.Image image) {
  final LuminanceSource source;
  try {
    source = RGBLuminanceSource(
      image.width,
      image.height,
      _argbPixels(image),
    );
  } catch (_) {
    return null;
  }

  // HybridBinarizer thresholds locally and copes with uneven lighting in a
  // webcam frame far better. Keep the global one as a fallback.
  for (final Binarizer binarizer in [
    HybridBinarizer(source),
    GlobalHistogramBinarizer(source),
  ]) {
    try {
      final result = QRCodeReader().decode(BinaryBitmap(binarizer));
      if (result.text.isNotEmpty) {
        return result.text;
      }
    } catch (_) {
      // No QR code found with this binarizer.
    }
  }
  return null;
}

/// Packs [image] into the 0xAARRGGBB ints RGBLuminanceSource expects.
///
/// convert() keeps the source format unless told otherwise, so a 1-bit PNG
/// (Python qrcode's default) stays bit-packed and a 16-bit one keeps 2 bytes
/// per channel. Force 8-bit RGBA, which also resolves palettes. Transparent
/// pixels are composited onto white so a dark-on-transparent code still has
/// a light background.
Int32List _argbPixels(img.Image image) {
  final rgba = image.convert(format: img.Format.uint8, numChannels: 4);
  final bytes = rgba.getBytes(order: img.ChannelOrder.rgba);
  final pixels = Int32List(image.width * image.height);
  for (var i = 0, j = 0; i < pixels.length; i++, j += 4) {
    final a = bytes[j + 3];
    int r = bytes[j], g = bytes[j + 1], b = bytes[j + 2];
    if (a != 255) {
      r = (r * a + 255 * (255 - a)) ~/ 255;
      g = (g * a + 255 * (255 - a)) ~/ 255;
      b = (b * a + 255 * (255 - a)) ~/ 255;
    }
    pixels[i] = 0xFF000000 | (r << 16) | (g << 8) | b;
  }
  return pixels;
}
