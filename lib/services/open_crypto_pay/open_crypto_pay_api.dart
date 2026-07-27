import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../app_config.dart';
import '../../networking/http.dart';
import '../../utilities/logger.dart';
import '../../utilities/prefs.dart';
import '../tor_service.dart';
import 'lnurl_utils.dart';
import 'models.dart';

/// Client for the Open CryptoPay standard.
///
/// See https://github.com/openCryptoPay/landingPage
class OpenCryptoPayApi {
  OpenCryptoPayApi._();

  static final OpenCryptoPayApi instance = OpenCryptoPayApi._();

  final HTTP _client = const HTTP();

  static const Duration _httpTimeout = Duration(seconds: 15);
  static const Duration _commitTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _retryBaseDelay = Duration(milliseconds: 500);

  ({InternetAddress host, int port})? get _proxyInfo =>
      AppConfig.hasFeature(AppFeature.tor) && Prefs.instance.useTor
      ? TorService.sharedInstance.getProxyInfo()
      : null;

  /// Throws if [uri] is not an absolute https URL. LUD-01 mandates HTTPS;
  /// rejecting plain http also closes off MITM and SSRF-into-loopback risks
  /// from a malicious QR.
  void _requireHttps(Uri uri, String label) {
    if (uri.scheme != 'https' || !uri.hasAuthority) {
      throw Exception('OpenCryptoPay: $label must be an https URL');
    }
  }

  /// Fetches the payment details (available methods, quote, recipient, etc)
  /// for the payment encoded in [qrUrl].
  Future<OpenCryptoPayPaymentDetails> getPaymentDetails(String qrUrl) async {
    final lnurl = LnurlUtils.extractLnurl(qrUrl);
    if (lnurl == null) {
      throw Exception('No LNURL payload found');
    }

    final apiUrl = Uri.parse(LnurlUtils.decodeLnurl(lnurl));
    _requireHttps(apiUrl, 'decoded LNURL');
    final uri = apiUrl.replace(
      queryParameters: {...apiUrl.queryParameters, 'timeout': '10'},
    );

    Logging.instance.d('OpenCryptoPay: GET $uri');
    final response = await _getWithRetry(uri);

    if (response.code == 404) {
      String message = 'No pending payment found';
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        message = json['message'] as String? ?? message;
      } catch (_) {}
      throw OpenCryptoPayNoPendingPaymentException(message);
    }
    if (response.code != 200) {
      throw Exception('OpenCryptoPay ${response.code}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final details = OpenCryptoPayPaymentDetails.fromJson(json);
    if (!details.supportsOpenCryptoPay) {
      throw Exception('OpenCryptoPay: endpoint did not return OpenCryptoPay');
    }

    // Pin all subsequent calls (callback fetch + commit) to the same host as
    // the LNURL we already trusted. Otherwise a malicious provider response
    // could redirect the txid + raw hex to an attacker-controlled host.
    final callback = Uri.tryParse(details.callback);
    if (callback == null) {
      throw Exception('OpenCryptoPay: invalid callback URL');
    }
    _requireHttps(callback, 'callback');
    if (callback.host != apiUrl.host) {
      throw Exception(
        'OpenCryptoPay: callback host ${callback.host} does not match '
        'LNURL host ${apiUrl.host}',
      );
    }

    return details;
  }

  /// Fetches the transaction details (payment address URI) for the chosen
  /// [method] and [asset].
  Future<OpenCryptoPayTransactionDetails> getTransactionDetails({
    required String callbackUrl,
    required String quoteId,
    required String method,
    required String asset,
  }) async {
    final base = Uri.parse(callbackUrl);
    _requireHttps(base, 'callback');
    final uri = base.replace(
      queryParameters: {
        ...base.queryParameters,
        'quote': quoteId,
        'method': method,
        'asset': asset,
      },
    );

    Logging.instance.d('OpenCryptoPay: GET $uri');
    final response = await _getWithRetry(uri);

    if (response.code != 200) {
      throw Exception('OpenCryptoPay ${response.code}: ${response.body}');
    }

    return OpenCryptoPayTransactionDetails.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Notifies the provider of a locally broadcast transaction so the merchant
  /// side can settle the payment.
  Future<void> commitTxId({
    required OpenCryptoPayCommit commit,
    required String txId,
  }) async {
    if (!commit.canCommitTxId) {
      throw UnsupportedError(
        'OpenCryptoPay method ${commit.method} cannot be committed with txid',
      );
    }

    await _commit(commit: commit, queryParameters: {'tx': txId});
  }

  /// Sends raw signed transaction hex to the provider for methods where the
  /// provider is responsible for broadcasting.
  Future<void> commitRawHex({
    required OpenCryptoPayCommit commit,
    required String hex,
  }) async {
    if (!commit.canCommitRawHex) {
      throw UnsupportedError(
        'OpenCryptoPay method ${commit.method} cannot be committed with hex',
      );
    }

    await _commit(commit: commit, queryParameters: {'hex': hex});
  }

  Future<void> _commit({
    required OpenCryptoPayCommit commit,
    required Map<String, String> queryParameters,
  }) async {
    final base = _commitEndpoint(commit.callbackUrl, commit.paymentId);
    _requireHttps(base, 'commit endpoint');
    final uri = base.replace(
      queryParameters: {
        ...base.queryParameters,
        'quote': commit.quoteId,
        'method': commit.method,
        'asset': commit.asset,
        ...queryParameters,
      },
    );

    Logging.instance.d('OpenCryptoPay: GET ${_redactedUri(uri)}');
    final response = await _getWithRetry(uri, timeout: _commitTimeout);
    if (response.code != 200) {
      throw Exception(
        'OpenCryptoPay commit ${response.code}: ${response.body}',
      );
    }
  }

  Uri _commitEndpoint(String callbackUrl, String paymentId) {
    final callback = Uri.parse(callbackUrl);
    if (paymentId.isEmpty) {
      throw Exception('OpenCryptoPay: quote payment id is missing');
    }
    final segments = callback.pathSegments.toList();
    final cbIndex = segments.lastIndexOf('cb');
    if (cbIndex == -1) {
      throw Exception('OpenCryptoPay: callback URL does not contain /cb/');
    }
    return callback.replace(
      pathSegments: [...segments.take(cbIndex), 'tx', paymentId],
    );
  }

  Uri _redactedUri(Uri uri) {
    if (!uri.queryParameters.containsKey('hex')) return uri;
    return uri.replace(
      queryParameters: {...uri.queryParameters, 'hex': '<redacted>'},
    );
  }

  Future<Response> _get(Uri uri, {Duration timeout = _httpTimeout}) {
    return _client
        .get(url: uri, proxyInfo: _proxyInfo, connectionTimeout: timeout)
        .timeout(timeout);
  }

  Future<Response> _getWithRetry(
    Uri uri, {
    Duration timeout = _httpTimeout,
  }) async {
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        return await _get(uri, timeout: timeout);
      } catch (e, s) {
        if (!_isRetryableNetworkError(e) || attempt == _maxRetries - 1) {
          if (attempt > 0) {
            Logging.instance.w(
              'OpenCryptoPay: request failed after ${attempt + 1} attempts',
              error: e,
              stackTrace: s,
            );
          }
          rethrow;
        }

        final delay = _retryBaseDelay * (1 << attempt);
        Logging.instance.d(
          'OpenCryptoPay: retrying in ${delay.inMilliseconds}ms '
          '(attempt ${attempt + 2}/$_maxRetries)',
        );
        await Future<void>.delayed(delay);
      }
    }

    throw StateError('OpenCryptoPay: retry loop exited unexpectedly');
  }

  bool _isRetryableNetworkError(Object error) {
    return error is TimeoutException ||
        error is SocketException ||
        error is HandshakeException ||
        error is HttpException;
  }
}

class OpenCryptoPayNoPendingPaymentException implements Exception {
  final String message;
  OpenCryptoPayNoPendingPaymentException(this.message);

  @override
  String toString() => message;
}
