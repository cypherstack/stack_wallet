import 'dart:convert';
import 'dart:typed_data';

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
/// A single linear scan rather than regexes: it keeps document order (text,
/// inline images, proxy images and file links interleaved as they appear),
/// tolerates `>` inside quoted attribute values, accepts either quote style,
/// and runs in O(content length) with no catastrophic backtracking. Attachment
/// `<img>`/`<a>` become media segments and their markup never leaks into text.
List<MessageContentSegment> _parseSegments(String content) {
  final segments = <MessageContentSegment>[];
  final text = StringBuffer();

  void flushText() {
    final decoded = (unescapeHtml(text.toString()) ?? '').trim();
    if (decoded.isNotEmpty) segments.add(MessageTextSegment(decoded));
    text.clear();
  }

  final n = content.length;
  var i = 0;
  while (i < n) {
    final lt = content.indexOf('<', i);
    if (lt < 0) {
      text.write(content.substring(i));
      break;
    }
    if (lt > i) text.write(content.substring(i, lt));

    // HTML comment: skip past the closing `-->` (drop its contents entirely).
    if (content.startsWith('<!--', lt)) {
      final end = content.indexOf('-->', lt + 4);
      i = end < 0 ? n : end + 3;
      continue;
    }

    final gt = _tagEnd(content, lt);
    if (gt < 0) {
      // No closing `>`; the remainder can't be a tag, render it as text.
      text.write(content.substring(lt));
      break;
    }
    final tag = content.substring(lt, gt + 1);
    i = gt + 1;

    switch (_tagName(tag)) {
      case 'br':
        text.write('\n');
      case 'img':
        final src = unescapeHtml(_attr(tag, 'src'));
        if (src == null) break;
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
                filename: _emptyOrNull(unescapeHtml(_attr(tag, 'alt'))),
              ),
            );
          }
        }
      case 'a':
        final href = unescapeHtml(_attr(tag, 'href'));
        if (href != null && _isAttachmentProxy(href)) {
          // Consume through the matching </a>; its inner text is the link label
          // and must not also be emitted as body text.
          final close = _findClose(content, i, 'a');
          final inner = content.substring(i, close?.start ?? n);
          i = close?.end ?? n;
          final proxyPath = _proxyPathOf(href);
          if (proxyPath != null) {
            flushText();
            segments.add(
              MessageFileLinkSegment(
                proxyPath: proxyPath,
                filename: _emptyOrNull(_stripHtml(inner)),
              ),
            );
          }
        }
      // Any other tag (div, span, closing tags, ...) contributes no markup;
      // surrounding text flows through the buffer.
    }
  }
  flushText();
  return segments;
}

/// Index of the `>` that closes the tag starting at [lt], skipping any `>` that
/// sits inside a quoted attribute value. Returns -1 if the tag is unterminated.
int _tagEnd(String s, int lt) {
  var i = lt + 1;
  String? quote;
  while (i < s.length) {
    final c = s[i];
    if (quote != null) {
      if (c == quote) quote = null;
    } else if (c == '"' || c == "'") {
      quote = c;
    } else if (c == '>') {
      return i;
    }
    i++;
  }
  return -1;
}

/// The lowercased tag name from a raw tag string like `<img ...>` or `</a>`.
String _tagName(String tag) {
  var i = 1; // skip '<'
  if (i < tag.length && tag[i] == '/') i++; // closing tag
  final start = i;
  while (i < tag.length) {
    final c = tag[i];
    if (c == ' ' ||
        c == '\t' ||
        c == '\n' ||
        c == '\r' ||
        c == '>' ||
        c == '/') {
      break;
    }
    i++;
  }
  return tag.substring(start, i).toLowerCase();
}

/// Find the closing `</name>` at or after [from], validating that `</name` is
/// followed only by optional whitespace then `>` (so `</article>` doesn't match
/// `</a>`). Returns the `<` index and the index just past `>`.
({int start, int end})? _findClose(String s, int from, String name) {
  final lower = s.toLowerCase();
  final needle = '</$name';
  var idx = lower.indexOf(needle, from);
  while (idx >= 0) {
    var j = idx + needle.length;
    while (j < s.length &&
        (s[j] == ' ' || s[j] == '\t' || s[j] == '\n' || s[j] == '\r')) {
      j++;
    }
    if (j < s.length && s[j] == '>') {
      return (start: idx, end: j + 1);
    }
    idx = lower.indexOf(needle, idx + needle.length);
  }
  return null;
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

String? _attr(String tag, String name) {
  final re = RegExp(
    '\\b$name\\s*=\\s*(?:"([^"]*)"|\'([^\']*)\')',
    caseSensitive: false,
  );
  final m = re.firstMatch(tag);
  if (m == null) return null;
  return m.group(1) ?? m.group(2);
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

String _stripHtml(String html) {
  final noTags = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
  return unescapeHtml(noTags)!.replaceAll(RegExp(r'\s+'), ' ').trim();
}

final _entityRe = RegExp(r'&(#[xX]?[0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);');

const _namedEntities = <String, String>{
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': ' ',
  'mdash': '—',
  'ndash': '–',
  'hellip': '…',
  'copy': '©',
  'reg': '®',
  'trade': '™',
  'euro': '€',
  'pound': '£',
  'lsquo': '‘',
  'rsquo': '’',
  'ldquo': '“',
  'rdquo': '”',
};

/// Decode the HTML entities the ticket API emits, in a single pass so a decoded
/// `&` can't be re-read as the start of another entity (e.g. `&amp;lt;` decodes
/// to the literal `&lt;`, not `<`). Covers the named entities plus numeric
/// (`&#NN;`) and hex (`&#xNN;`) references; unknown entities are left as-is.
/// Returns null for null input so it can be threaded through nullable attribute
/// lookups.
String? unescapeHtml(String? s) {
  if (s == null) return null;
  return s.replaceAllMapped(_entityRe, (m) {
    final body = m.group(1)!;
    if (body.startsWith('#')) {
      final isHex = body.length > 1 && (body[1] == 'x' || body[1] == 'X');
      final code = int.tryParse(
        isHex ? body.substring(2) : body.substring(1),
        radix: isHex ? 16 : 10,
      );
      if (code == null || code < 0 || code > 0x10FFFF) return m.group(0)!;
      try {
        return String.fromCharCode(code);
      } catch (_) {
        return m.group(0)!;
      }
    }
    return _namedEntities[body] ?? m.group(0)!;
  });
}
