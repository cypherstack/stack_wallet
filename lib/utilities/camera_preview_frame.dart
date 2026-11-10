import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Why a frame captured from a camera preview can't be scanned.
enum BlankPreviewFrame {
  /// Nothing was drawn: the preview texture has no camera frame yet, or the
  /// camera has been closed.
  transparent,

  /// Every visible pixel is black or close to it, as with a closed privacy
  /// shutter.
  black,
}

// Sensor noise keeps a covered webcam from being exactly 0.
const _blackLevel = 16;

/// Returns why [rgba] can't be scanned, or null if it has picture content.
///
/// [rgba] is tightly packed 8-bit RGBA, as from
/// `ui.Image.toByteData(format: ui.ImageByteFormat.rawRgba)`.
BlankPreviewFrame? blankPreviewFrame(Uint8List rgba) {
  var anyVisible = false;
  for (var i = 0; i + 3 < rgba.length; i += 4) {
    if (rgba[i + 3] == 0) continue;
    anyVisible = true;
    if (rgba[i] > _blackLevel ||
        rgba[i + 1] > _blackLevel ||
        rgba[i + 2] > _blackLevel) {
      return null;
    }
  }
  return anyVisible ? BlankPreviewFrame.black : BlankPreviewFrame.transparent;
}

/// Builds an image from an RGBA capture of a horizontally mirrored camera
/// preview, flipped back so a QR code in it reads the right way round.
///
/// [rgba] is tightly packed 8-bit RGBA of [width] x [height] pixels.
img.Image imageFromMirroredPreviewRgba(
  Uint8List rgba, {
  required int width,
  required int height,
}) {
  if (width <= 0 || height <= 0) {
    throw ArgumentError("Invalid frame size ${width}x$height");
  }
  final byteLength = width * height * 4;
  if (rgba.length < byteLength) {
    throw ArgumentError.value(
      rgba.length,
      "rgba",
      "Too short for a ${width}x$height RGBA frame",
    );
  }

  // sublist copies into a fresh buffer, so the 32-bit view is aligned even
  // if the caller's bytes start at an odd offset.
  final src = rgba.sublist(0, byteLength).buffer.asUint32List();
  final flipped = Uint32List(width * height);
  for (var y = 0; y < height; y++) {
    final row = y * width;
    final last = row + width - 1;
    for (var x = 0; x < width; x++) {
      flipped[row + x] = src[last - x];
    }
  }

  return img.Image.fromBytes(
    width: width,
    height: height,
    bytes: flipped.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
}

/// A 64-bit FNV-1a hash of [rgba], for telling a new camera frame from a
/// repeat of the last one.
///
/// Frames from a live sensor never repeat byte for byte, so two captures
/// with the same fingerprint mean the preview has stopped updating. This is
/// a full pass over the buffer; an indexed loop keeps it to a few
/// milliseconds for a 1280 px frame.
int previewFrameFingerprint(Uint8List rgba) {
  var hash = 0xcbf29ce484222325;
  final length = rgba.length;
  for (var i = 0; i < length; i++) {
    hash ^= rgba[i];
    hash *= 0x100000001b3;
  }
  return hash;
}
