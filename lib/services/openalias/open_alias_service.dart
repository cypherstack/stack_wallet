import 'dart:io';
import 'dart:math';

import 'package:dnssec_resolver/dnssec_resolver.dart';
import 'package:doh_resolver/doh_resolver_io.dart';
import 'package:openalias/openalias.dart' as oa;

import '../../app_config.dart';
import '../../utilities/prefs.dart';
import '../tor_service.dart';
import 'open_alias.dart';

class OpenAliasService {
  static const directConnectTimeout = Duration(seconds: 5);
  static const directRequestTimeout = Duration(seconds: 12);
  static const directLookupTimeout = Duration(seconds: 20);
  // Over Tor each connection also waits for the exit stream and TLS via Tor.
  static const torConnectTimeout = Duration(seconds: 10);
  static const torRequestTimeout = Duration(seconds: 20);
  static const torLookupTimeout = Duration(seconds: 40);

  final bool Function() _externalCalls;
  final bool Function() _useTor;
  final bool Function() _supportsTor;
  final List<DnsValidator> _trustedValidators;
  final ({InternetAddress host, int port}) Function() _torProxy;
  late final Future<AuthenticatedTxtResult> Function(String, bool) _lookup;

  OpenAliasService({
    bool Function()? externalCalls,
    bool Function()? useTor,
    bool Function()? supportsTor,
    Future<AuthenticatedTxtResult> Function(String, bool)? lookup,
    List<DnsValidator>? trustedValidators,
    ({InternetAddress host, int port}) Function()? torProxy,
  }) : _externalCalls = externalCalls ?? (() => Prefs.instance.externalCalls),
       _useTor = useTor ?? (() => Prefs.instance.useTor),
       _supportsTor =
           supportsTor ?? (() => AppConfig.hasFeature(AppFeature.tor)),
       _trustedValidators = trustedValidators ?? [DnssecResolver.validator],
       _torProxy =
           torProxy ?? (() => TorService.sharedInstance.getProxyInfo()) {
    _lookup = lookup ?? _lookupDns;
  }

  Future<AuthenticatedTxtResult> _lookupDns(String domain, bool useTor) async {
    final proxy = useTor ? _torProxy() : null;
    final transport = IoDohTransport(
      proxy: proxy == null
          ? null
          : SocksProxy(
              proxy.host,
              proxy.port,
              // A fresh Tor circuit for each lookup.
              credentials: SocksCredentials.isolation(_isolationToken()),
            ),
      proxyDestination: proxy == null ? null : InternetAddress('8.8.8.8'),
      connectionTimeout: useTor ? torConnectTimeout : directConnectTimeout,
      requestTimeout: useTor ? torRequestTimeout : directRequestTimeout,
    );
    try {
      return await DnssecResolver(
        timeout: useTor ? torLookupTimeout : directLookupTimeout,
        transport: OpenAliasDnsTransport(transport, () {
          if (!_externalCalls() || _useTor() != useTor) return false;
          if (useTor) {
            if (!_supportsTor()) return false;
            final current = _torProxy();
            return current.host.address == proxy!.host.address &&
                current.port == proxy.port;
          }
          return true;
        }),
      ).lookupTxt(domain);
    } finally {
      await transport.close();
    }
  }

  static String _isolationToken() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Future<OpenAliasRecipient> resolve(
    String input, {
    required bool Function(String) validateAddress,
  }) async {
    final domain = normalizeOpenAlias(input);
    if (!_externalCalls()) {
      throw const OpenAliasException(
        'OpenAlias lookups are off in Incognito mode. To use OpenAlias, '
        'switch ${AppConfig.prefix} Experience to Easy Crypto in Advanced '
        'settings.',
      );
    }
    final useTor = _useTor();
    if (useTor && !_supportsTor()) {
      throw const OpenAliasException('Tor is unavailable. No lookup was sent.');
    }
    try {
      final recipient = await oa.OpenAliasResolver(
        application: 'xmr',
        requiredAuthentication: DnsAuthentication.locallyValidated,
        trustedValidators: _trustedValidators,
        validateAddress: validateAddress,
        lookup: (name) async {
          final result = await _lookup(name, useTor);
          if (_useTor() != useTor || !_externalCalls()) {
            throw const OpenAliasException(
              'Privacy settings changed. Please look up the alias again.',
            );
          }
          return result;
        },
      ).resolve(domain);
      return OpenAliasRecipient(
        domain: recipient.domain,
        address: recipient.address,
        resolved: recipient,
      );
    } on OpenAliasException {
      rethrow;
    } on oa.OpenAliasException catch (error) {
      throw OpenAliasException(switch (error.code) {
        oa.OpenAliasError.authenticationUnavailable =>
          'Local DNSSEC verification failed. '
              'Ask the recipient for a verified alias or address.',
        oa.OpenAliasError.noRecord =>
          'No Monero OpenAlias record was found for $domain.',
        oa.OpenAliasError.invalidAddress =>
          'This alias contains an invalid Monero address for this wallet.',
        oa.OpenAliasError.ambiguous =>
          'This alias has multiple Monero addresses. '
              'Ask the recipient for an address.',
        oa.OpenAliasError.questionMismatch =>
          'The DNS response does not match this alias.',
        _ => error.message,
      });
    } on DnsException catch (error) {
      throw OpenAliasException(switch (error.code) {
        DnsError.authenticationUnavailable =>
          'DNSSEC verification failed or is unavailable. '
              'Ask the recipient for a verified alias or address.',
        DnsError.noRecords => 'No OpenAlias record exists for $domain.',
        DnsError.queryFailed =>
          'The DNS lookup for $domain failed. No address was accepted.',
        DnsError.questionMismatch =>
          'The DNS response does not match this alias.',
        DnsError.aliasLoop => 'The alias has a DNS loop.',
        DnsError.aliasAmbiguous => 'The DNS alias is ambiguous.',
        DnsError.aliasTooLong => 'The DNS alias chain is too long.',
        DnsError.responseTooLarge => 'The DNS response is too large.',
        DnsError.malformedResponse ||
        DnsError.invalidName => 'Invalid DNS response.',
        DnsError.transport || DnsError.cancelled || DnsError.timedOut =>
          'OpenAlias lookup failed. Check your connection and try again.',
      });
    } catch (_) {
      throw const OpenAliasException(
        'OpenAlias lookup is unavailable. '
        'Check your connection and Tor settings.',
      );
    }
  }
}

class OpenAliasDnsTransport implements DohWireTransport {
  final DohWireTransport transport;
  final bool Function() allowed;
  OpenAliasDnsTransport(this.transport, this.allowed);

  @override
  DnsOperation<DohHttpResponse> startWire(
    Uri uri,
    List<int> query, {
    required int maxResponseBytes,
  }) {
    // Key lookups need current permission, just like the initial TXT query.
    if (!allowed()) {
      throw const DnsException(
        DnsError.cancelled,
        'DNS privacy settings changed',
      );
    }
    return transport.startWire(uri, query, maxResponseBytes: maxResponseBytes);
  }
}
