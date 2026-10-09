import 'package:doh_resolver/doh_resolver.dart';
import 'package:openalias/openalias.dart' as oa;

/// Stack Wallet presentation state for an OpenAlias recipient.
///
/// The package-owned [resolved] value retains authenticated DNS evidence. This
/// wrapper deliberately does not subclass or recreate that non-forgeable type.
class OpenAliasRecipient {
  final String domain;
  final String address;
  // The alias as the user entered it, e.g. user@example.com.
  final String displayAlias;
  final oa.OpenAliasRecipient? resolved;

  const OpenAliasRecipient({
    required this.domain,
    required this.address,
    String? displayAlias,
    this.resolved,
  }) : displayAlias = displayAlias ?? domain;

  String? get application => resolved?.application;
  oa.OpenAliasRecord? get record => resolved?.record;
  AuthenticatedTxtResult? get dns => resolved?.dns;
  DnsAuthentication? get authentication => resolved?.authentication;
}

String displayOpenAlias(String input) {
  final name = input.trim().toLowerCase();
  return name.endsWith('.') ? name.substring(0, name.length - 1) : name;
}

class OpenAliasException implements Exception {
  final String message;
  const OpenAliasException(this.message);
  @override
  String toString() => message;
}

String normalizeOpenAlias(String input) {
  try {
    return oa.normalizeOpenAlias(input);
  } on oa.OpenAliasException catch (error) {
    throw OpenAliasException(error.message);
  }
}
