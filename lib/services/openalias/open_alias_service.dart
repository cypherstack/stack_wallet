import 'dart:io';

import 'package:cs_openalias/cs_openalias.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_config.dart';
import '../../utilities/prefs.dart';
import '../tor_service.dart';

final pOpenAliasService = Provider<OpenAliasService>((_) => OpenAliasService());

const openAliasLookupFailedTitle = 'OpenAlias lookup failed';

String openAliasErrorMessage(CsOpenAliasException e) => switch (e) {
  CsOpenAliasInvalidAliasException() => 'Enter a valid address or OpenAlias.',
  CsOpenAliasNoRecordException() =>
    'No Monero OpenAlias record was found for ${e.alias}.',
  CsOpenAliasInvalidRecordException() =>
    'This alias has an invalid or unsupported Monero record for this wallet.',
  CsOpenAliasDnssecException() =>
    'DNSSEC verification failed or is unavailable. Ask the recipient for a '
        'verified alias or address.',
  CsOpenAliasNetworkException() =>
    'OpenAlias lookup failed. Check your connection and try again.',
  CsOpenAliasCancelledException() => 'OpenAlias lookup cancelled.',
};

typedef OpenAliasLookup = CsOpenAliasOperation<CsOpenAliasRecipient> Function(
  String alias, {
  required bool Function(String address) isValidAddress,
  required CsOpenAliasProxy? proxy,
});

/// Thrown by [OpenAliasService.lookup] when no lookup may be sent.
final class OpenAliasUnavailableException implements Exception {
  const OpenAliasUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Starts OpenAlias lookups that follow the Incognito and Tor settings.
class OpenAliasService {
  OpenAliasService({
    bool Function()? externalCalls,
    bool Function()? useTor,
    bool Function()? supportsTor,
    ({InternetAddress host, int port}) Function()? torProxy,
    OpenAliasLookup? lookup,
  }) : _externalCalls = externalCalls ?? (() => Prefs.instance.externalCalls),
       _useTor = useTor ?? (() => Prefs.instance.useTor),
       _supportsTor =
           supportsTor ?? (() => AppConfig.hasFeature(AppFeature.tor)),
       _torProxy = torProxy ?? (() => TorService.sharedInstance.getProxyInfo()),
       _lookup = lookup ?? resolveOpenAlias;

  final bool Function() _externalCalls;
  final bool Function() _useTor;
  final bool Function() _supportsTor;
  final ({InternetAddress host, int port}) Function() _torProxy;
  final OpenAliasLookup _lookup;

  /// Why no lookup can be sent now, or null when one can.
  String? unavailableReason() => _route().unavailable;

  /// Looks up [alias], through Tor when Tor is on. Throws
  /// [OpenAliasUnavailableException] without sending anything when Incognito
  /// mode is on or Tor is on but unavailable.
  CsOpenAliasOperation<CsOpenAliasRecipient> lookup(
    String alias, {
    required bool Function(String address) isValidAddress,
  }) {
    final route = _route();
    final unavailable = route.unavailable;
    if (unavailable != null) {
      throw OpenAliasUnavailableException(unavailable);
    }
    return _lookup(alias, isValidAddress: isValidAddress, proxy: route.proxy);
  }

  ({String? unavailable, CsOpenAliasProxy? proxy}) _route() {
    if (!_externalCalls()) {
      return (
        unavailable:
            'OpenAlias lookups are off in Incognito mode. To use OpenAlias, '
            'switch ${AppConfig.prefix} Experience to Easy Crypto in Advanced '
            'settings.',
        proxy: null,
      );
    }
    if (!_useTor()) {
      return (unavailable: null, proxy: null);
    }
    if (_supportsTor()) {
      try {
        final info = _torProxy();
        return (
          unavailable: null,
          proxy: CsOpenAliasProxy(address: info.host.address, port: info.port),
        );
      } catch (_) {
        // Tor is not connected; never fall back to a direct lookup.
      }
    }
    return (
      unavailable: 'Tor is unavailable. No lookup was sent.',
      proxy: null,
    );
  }
}
