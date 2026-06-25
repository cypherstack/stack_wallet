import 'dart:convert';
import 'dart:typed_data';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parseFragment;

class TicketMessage {
  final DateTime timestamp;
  final bool fromAgent;
  final String content;

  TicketMessage({
    required this.timestamp,
    required this.fromAgent,
    required this.content,
  });

  /// [content] parsed once into ordered renderable segments: plain-text runs,
  /// decoded inline base64 images, and `/attachment-proxy/` images and file
  /// links, kept in the order they appear in the message.
  late final List<MessageContentSegment> contentSegments = _parseSegments(
    content,
  );

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      timestamp: DateTime.parse(json['timestamp'] as String),
      fromAgent: json['from_agent'] as bool,
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    "timestamp": timestamp.toIso8601String(),
    "from_agent": fromAgent,
    "content": content,
  };

  @override
  String toString() => toMap().toString();
}

/// A renderable piece of a ticket message, in document order.
sealed class MessageContentSegment {}

/// A run of plain text (structural tags stripped, entities decoded).
class MessageTextSegment extends MessageContentSegment {
  MessageTextSegment(this.text);
  final String text;
}

/// A decoded inline base64 (data-URI) image.
class MessageImageSegment extends MessageContentSegment {
  MessageImageSegment(this.bytes);
  final Uint8List bytes;
}

/// An authenticated `/attachment-proxy/` image, fetched on demand with the
/// current token. [proxyPath] is the attachment-proxy path (query/fragment
/// stripped); [filename] is the `alt` text when present.
class MessageProxyImageSegment extends MessageContentSegment {
  MessageProxyImageSegment({required this.proxyPath, this.filename});
  final String proxyPath;
  final String? filename;
}

/// An authenticated `/attachment-proxy/` file link, opened in the browser.
/// [proxyPath] is the attachment-proxy path; [filename] is the link text.
class MessageFileLinkSegment extends MessageContentSegment {
  MessageFileLinkSegment({required this.proxyPath, this.filename});
  final String proxyPath;
  final String? filename;
}

/// Parse a ticket message's HTML [content] into ordered renderable segments.
///
/// Walks the parsed DOM in document order so text, inline images, proxy images
/// and file links render where they appear. Attachment `<img>`/`<a>` become
/// media segments and their markup is never shown as text; other markup is
/// flattened to its text. The parser handles malformed/adversarial HTML and
/// entity decoding, so there's no hand-rolled tokeniser to keep correct.
List<MessageContentSegment> _parseSegments(String content) {
  final segments = <MessageContentSegment>[];
  final text = StringBuffer();

  void flushText() {
    final trimmed = text.toString().trim();
    if (trimmed.isNotEmpty) segments.add(MessageTextSegment(trimmed));
    text.clear();
  }

  void visit(dom.Node node) {
    if (node is dom.Text) {
      text.write(node.data);
      return;
    }
    if (node is! dom.Element) return;

    switch (node.localName) {
      case 'br':
        text.write('\n');
        return;
      case 'img':
        final src = node.attributes['src'];
        if (src == null) return;
        final bytes = _decodeInlineImage(src);
        if (bytes != null) {
          flushText();
          segments.add(MessageImageSegment(bytes));
        } else if (_isAttachmentProxy(src)) {
          final proxyPath = _proxyPathOf(src);
          if (proxyPath != null) {
            flushText();
            segments.add(
              MessageProxyImageSegment(
                proxyPath: proxyPath,
                filename: _emptyOrNull(node.attributes['alt']),
              ),
            );
          }
        }
        return;
      case 'a':
        final href = node.attributes['href'];
        if (href != null && _isAttachmentProxy(href)) {
          final proxyPath = _proxyPathOf(href);
          if (proxyPath != null) {
            flushText();
            segments.add(
              MessageFileLinkSegment(
                proxyPath: proxyPath,
                filename: _emptyOrNull(node.text),
              ),
            );
          }
          // The link text is its label, not body text; don't recurse.
          return;
        }
    }

    for (final child in node.nodes) {
      visit(child);
    }
  }

  for (final node in parseFragment(content).nodes) {
    visit(node);
  }
  flushText();
  return segments;
}

final _whitespaceRe = RegExp(r'\s');

// Decoded inline images are cached by their base64 payload and reused across
// rebuilds. refreshOne rebuilds TicketMessage objects every ~30s poll, so
// without this the `late final` memo re-decodes each poll and hands a fresh
// Uint8List to Image.memory; MemoryImage compares bytes by identity, so that's
// an image cache miss -> re-decode + GPU re-upload + a visible flicker every
// poll. Returning the same instance keeps the provider equal so the cache hits.
// Bounded by total decoded size so large/many inline images can't grow it
// without limit.
const int _kInlineImageCacheMaxBytes = 16 * 1024 * 1024;
final _inlineImageCache = <String, Uint8List>{};
int _inlineImageCacheBytes = 0;

/// Decode a `data:image/<type>;base64,<data>` URI to bytes, or null if [src] is
/// not such a data URI or the payload doesn't decode. Cached by payload.
Uint8List? _decodeInlineImage(String src) {
  if (!src.startsWith('data:image/')) return null;
  const marker = ';base64,';
  final idx = src.indexOf(marker);
  if (idx < 0) return null;
  final b64 = src.substring(idx + marker.length).replaceAll(_whitespaceRe, '');
  if (b64.isEmpty) return null;

  final cached = _inlineImageCache.remove(b64);
  if (cached != null) {
    _inlineImageCache[b64] = cached; // move to most-recently-used
    return cached;
  }

  final Uint8List bytes;
  try {
    bytes = base64Decode(b64);
  } catch (_) {
    return null;
  }
  _inlineImageCache[b64] = bytes;
  _inlineImageCacheBytes += bytes.length;
  while (_inlineImageCacheBytes > _kInlineImageCacheMaxBytes &&
      _inlineImageCache.length > 1) {
    final oldest = _inlineImageCache.keys.first;
    _inlineImageCacheBytes -= _inlineImageCache.remove(oldest)?.length ?? 0;
  }
  return bytes;
}

bool _isAttachmentProxy(String url) => url.contains('/attachment-proxy/');

String? _proxyPathOf(String url) {
  const marker = '/attachment-proxy/';
  final idx = url.indexOf(marker);
  if (idx < 0) return null;
  var rest = url.substring(idx + marker.length);
  final q = rest.indexOf(RegExp(r'[?#]'));
  if (q >= 0) rest = rest.substring(0, q);
  if (rest.isEmpty) return null;
  // Percent-encoded path separators (`%2f`, `%5c`) survive Uri.path
  // normalisation un-decoded, so the dot-segment check below would miss a
  // traversal smuggled through them; reject those outright.
  final lower = rest.toLowerCase();
  if (lower.contains('%2f') || lower.contains('%5c')) return null;
  // Reject anything that still escapes the attachment-proxy namespace once the
  // path is normalised (literal `../`, or `%2e%2e` which Uri does decode). The
  // result is interpolated into a request URL that carries the user's auth
  // token, so a traversal could otherwise point that authenticated request at
  // another endpoint on the host.
  final Uri probe;
  try {
    probe = Uri.parse('https://x$marker$rest');
  } catch (_) {
    return null;
  }
  if (!probe.path.startsWith(marker) || probe.path.length <= marker.length) {
    return null;
  }
  return rest;
}

String? _emptyOrNull(String? s) {
  if (s == null) return null;
  final t = s.trim();
  return t.isEmpty ? null : t;
}
