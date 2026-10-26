import 'dart:io';

import 'package:cs_openalias/cs_openalias.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_config.dart';
import '../../utilities/logger.dart';
import '../../utilities/prefs.dart';
import '../tor_service.dart';

final pOpenAliasService = Provider<OpenAliasService>((_) => OpenAliasService());

const openAliasLookupFailedTitle = 'OpenAlias lookup failed';

String openAliasErrorMessage(CsOpenAliasException e, String coinName) =>
    switch (e) {
      CsOpenAliasInvalidAliasException() =>
        'Enter a valid address or OpenAlias.',
      CsOpenAliasNoRecordException() =>
        'No $coinName OpenAlias record was found for ${e.alias}.',
      CsOpenAliasInvalidRecordException() =>
        'This alias has an invalid or unsupported $coinName record for this '
            'wallet.',
      CsOpenAliasDnssecException() =>
        'DNSSEC verification failed or is unavailable. Ask the recipient for a '
            'verified alias or address.',
      CsOpenAliasNetworkException() =>
        'OpenAlias lookup failed. Check your connection and try again.',
      CsOpenAliasCancelledException() => 'OpenAlias lookup cancelled.',
    };

String openAliasKey(String input) => input.trim().toLowerCase();

typedef OpenAliasLookup = CsOpenAliasOperation<CsOpenAliasRecipient> Function(
  String alias, {
  required bool Function(String address) isValidAddress,
  required String application,
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

  /// Looks up the [application] record of [alias], through Tor when Tor is
  /// on. Throws [OpenAliasUnavailableException] without sending anything when
  /// Incognito mode is on or Tor is on but unavailable.
  CsOpenAliasOperation<CsOpenAliasRecipient> lookup(
    String alias, {
    required bool Function(String address) isValidAddress,
    required String application,
  }) {
    final route = _route();
    final unavailable = route.unavailable;
    if (unavailable != null) {
      throw OpenAliasUnavailableException(unavailable);
    }
    return _lookup(
      alias,
      isValidAddress: isValidAddress,
      application: application,
      proxy: route.proxy,
    );
  }

  /// Starts [lookup] for the alias typed into a send field.
  OpenAliasResolution resolve(
    String input, {
    required bool Function(String address) isValidAddress,
    required String application,
    required String coinName,
  }) => OpenAliasResolution._(
    () =>
        lookup(input, isValidAddress: isValidAddress, application: application),
    alias: openAliasKey(input),
    coinName: coinName,
  );

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

sealed class OpenAliasOutcome {
  const OpenAliasOutcome();
}

final class OpenAliasResolved extends OpenAliasOutcome {
  const OpenAliasResolved({required this.alias, required this.address});

  final String alias;
  final String address;
}

final class OpenAliasFailed extends OpenAliasOutcome {
  const OpenAliasFailed(this.message);

  String get title => openAliasLookupFailedTitle;
  final String message;
}

final class OpenAliasCancelled extends OpenAliasOutcome {
  const OpenAliasCancelled();
}

/// A lookup started by [OpenAliasService.resolve].
final class OpenAliasResolution {
  OpenAliasResolution._(
    CsOpenAliasOperation<CsOpenAliasRecipient> Function() start, {
    required String alias,
    required String coinName,
  }) {
    outcome = _run(start, alias, coinName);
  }

  late final Future<OpenAliasOutcome> outcome;
  CsOpenAliasOperation<CsOpenAliasRecipient>? _operation;
  bool _cancelled = false;

  void cancel() {
    _cancelled = true;
    _operation?.cancel();
  }

  Future<OpenAliasOutcome> _run(
    CsOpenAliasOperation<CsOpenAliasRecipient> Function() start,
    String alias,
    String coinName,
  ) async {
    try {
      _operation = start();
      final address = (await _operation!.result).address;
      if (_cancelled) return const OpenAliasCancelled();
      return OpenAliasResolved(alias: alias, address: address);
    } catch (e, s) {
      if (_cancelled) return const OpenAliasCancelled();
      Logging.instance.w("OpenAlias lookup failed", error: e, stackTrace: s);
      return OpenAliasFailed(
        e is CsOpenAliasException
            ? openAliasErrorMessage(e, coinName)
            : e.toString(),
      );
    }
  }
}
