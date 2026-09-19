import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../app_config.dart';
import '../networking/http.dart';
import '../utilities/prefs.dart';
import '../services/tor_service.dart';

/// Fetches and displays an image through the app's HTTP client,
/// respecting Tor proxy settings. Use this instead of [Image.network]
/// when the request must route through Tor.
class OrdinalImage extends StatefulWidget {
  const OrdinalImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.filterQuality = FilterQuality.none,
  });

  final String url;
  final BoxFit fit;
  final FilterQuality filterQuality;

  @override
  State<OrdinalImage> createState() => _OrdinalImageState();
}

class _OrdinalImageState extends State<OrdinalImage> {
  late Future<Uint8List> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchImage();
  }

  @override
  void didUpdateWidget(OrdinalImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _future = _fetchImage();
    }
  }

  Future<Uint8List> _fetchImage() async {
    final response = await const HTTP().get(
      url: Uri.parse(widget.url),
      proxyInfo: !AppConfig.hasFeature(AppFeature.tor)
          ? null
          : Prefs.instance.useTor
          ? TorService.sharedInstance.getProxyInfo()
          : null,
    );

    if (response.code != 200) {
      throw Exception('Failed to load image: status=${response.code}');
    }

    return Uint8List.fromList(response.bodyBytes);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit: widget.fit,
            filterQuality: widget.filterQuality,
          );
        } else if (snapshot.hasError) {
          return const Center(child: Icon(Icons.broken_image));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
