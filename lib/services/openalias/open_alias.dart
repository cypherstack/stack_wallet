import 'package:openalias/openalias.dart' as oa;

class OpenAliasRecipient extends oa.OpenAliasRecipient {
  // The alias as the user entered it, e.g. user@example.com.
  final String displayAlias;

  const OpenAliasRecipient({
    required super.domain,
    required super.address,
    super.application,
    super.record,
    super.dns,
    String? displayAlias,
  }) : displayAlias = displayAlias ?? domain;
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
