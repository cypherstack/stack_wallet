import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_config.dart';
import '../services/tor_service.dart';
import '../utilities/prefs.dart';
import 'http.dart';

/// Fetches [url] through the app's [HTTP] client, routing over Tor when it is
/// enabled. Throws if Tor is enabled but not connected, so nothing falls back
/// to clearnet.
Future<Uint8List> fetchTorAwareBytes(String url) async {
  final response = await const HTTP().get(
    url: Uri.parse(url),
    proxyInfo: !AppConfig.hasFeature(AppFeature.tor)
        ? null
        : Prefs.instance.useTor
        ? TorService.sharedInstance.getProxyInfo()
        : null,
  );

  if (response.code != 200) {
    throw Exception("Failed to load $url: status=${response.code}");
  }

  return Uint8List.fromList(response.bodyBytes);
}

/// Drop-in replacement for [NetworkImage] that respects the Tor preference.
/// Use with [Image] instead of [Image.network], which always goes clearnet.
@immutable
class TorAwareNetworkImage extends ImageProvider<TorAwareNetworkImage> {
  const TorAwareNetworkImage(this.url);

  final String url;

  @override
  Future<TorAwareNetworkImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<TorAwareNetworkImage>(this);

  @override
  ImageStreamCompleter loadImage(
    TorAwareNetworkImage key,
    ImageDecoderCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiFrameImageStreamCompleter(
      codec: _load(key, decode, chunkEvents),
      chunkEvents: chunkEvents.stream,
      scale: 1.0,
      debugLabel: key.url,
    );
  }

  Future<ui.Codec> _load(
    TorAwareNetworkImage key,
    ImageDecoderCallback decode,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    try {
      // Lets loadingBuilder show its indicator while the request runs.
      chunkEvents.add(
        const ImageChunkEvent(
          cumulativeBytesLoaded: 0,
          expectedTotalBytes: null,
        ),
      );
      final bytes = await fetchTorAwareBytes(key.url);
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      return await decode(buffer);
    } catch (_) {
      // Don't keep a failed load in the cache.
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });
      rethrow;
    } finally {
      unawaited(chunkEvents.close());
    }
  }

  @override
  bool operator ==(Object other) =>
      other is TorAwareNetworkImage && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() =>
      "${objectRuntimeType(this, "TorAwareNetworkImage")}"
      "(\"$url\")";
}

/// Drop-in replacement for the loader behind [SvgPicture.network] that
/// respects the Tor preference.
/// Use as `SvgPicture(TorAwareSvgNetworkLoader(url))`.
@immutable
class TorAwareSvgNetworkLoader extends SvgLoader<Uint8List> {
  const TorAwareSvgNetworkLoader(this.url);

  final String url;

  @override
  Future<Uint8List?> prepareMessage(BuildContext? context) =>
      fetchTorAwareBytes(url);

  @override
  String provideSvg(Uint8List? message) =>
      utf8.decode(message!, allowMalformed: true);

  @override
  bool operator ==(Object other) =>
      other is TorAwareSvgNetworkLoader && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
