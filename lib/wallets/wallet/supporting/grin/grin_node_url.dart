import 'grin_transport.dart';

class GrinNodeUrlException implements Exception {
  GrinNodeUrlException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The base URL the Grin library is given for a node. The library appends
/// `/v2/foreign` itself.
///
/// The scheme comes from [host] when it has one, otherwise from [useSSL].
/// [port] replaces any port in [host] when it is positive. Onion nodes are
/// reached over `http://` only: rustls cannot accept their self-signed
/// certificates.
String grinNodeUrl({
  required String host,
  required int port,
  required bool useSSL,
}) {
  final trimmed = host.trim();
  if (trimmed.isEmpty) {
    throw GrinNodeUrlException("The node address is empty.");
  }

  final onion = isOnionHost(trimmed);
  final hasScheme = trimmed.contains("://");
  final String text;
  if (hasScheme) {
    text = trimmed;
  } else {
    text = "${(useSSL && !onion) ? "https" : "http"}://$trimmed";
  }

  final Uri uri;
  try {
    uri = Uri.parse(text);
  } on FormatException {
    throw GrinNodeUrlException("The node address is not a valid URL.");
  }

  final scheme = uri.scheme.toLowerCase();
  if (scheme != "http" && scheme != "https") {
    throw GrinNodeUrlException("The node address must use http or https.");
  }
  if (uri.host.isEmpty) {
    throw GrinNodeUrlException("The node address has no host.");
  }
  if (uri.userInfo.isNotEmpty) {
    throw GrinNodeUrlException(
      "Put the node API secret in its own field, not in the address.",
    );
  }
  if (onion && scheme == "https") {
    throw GrinNodeUrlException("Onion nodes must use http://.");
  }
  if (uri.hasQuery || uri.hasFragment) {
    throw GrinNodeUrlException("The node address must not have a query.");
  }

  var path = uri.path;
  while (path.endsWith("/")) {
    path = path.substring(0, path.length - 1);
  }

  return Uri(
    scheme: scheme,
    host: uri.host,
    port: port > 0 ? port : (uri.hasPort ? uri.port : null),
    path: path,
  ).toString();
}
