import '../../app_config.dart';
import '../../utilities/prefs.dart';
import '../tor_service.dart';
import 'doh_open_alias.dart';
import 'open_alias.dart';

class OpenAliasService {
  final bool Function() _externalCalls;
  final bool Function() _useTor;
  final bool Function() _supportsTor;
  final Future<List<String>> Function(String, bool) _lookup;

  OpenAliasService({
    bool Function()? externalCalls,
    bool Function()? useTor,
    bool Function()? supportsTor,
    Future<List<String>> Function(String, bool)? lookup,
  }) : _externalCalls = externalCalls ?? (() => Prefs.instance.externalCalls),
       _useTor = useTor ?? (() => Prefs.instance.useTor),
       _supportsTor =
           supportsTor ?? (() => AppConfig.hasFeature(AppFeature.tor)),
       _lookup = lookup ?? _lookupDns;

  static Future<List<String>> _lookupDns(String domain, bool useTor) =>
      const DohOpenAlias().lookup(
        domain,
        proxyInfo: useTor ? TorService.sharedInstance.getProxyInfo() : null,
      );

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
      final records = await _lookup(domain, useTor);
      if (_useTor() != useTor || !_externalCalls()) {
        throw const OpenAliasException(
          'Privacy settings changed. '
          'Please look up the alias again.',
        );
      }
      return selectOpenAliasRecipient(
        domain: domain,
        records: records,
        validateAddress: validateAddress,
      );
    } on OpenAliasException {
      rethrow;
    } catch (_) {
      throw const OpenAliasException(
        'OpenAlias lookup is unavailable. '
        'Check your connection and Tor settings.',
      );
    }
  }
}
