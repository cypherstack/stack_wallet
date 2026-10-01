class OpenAliasRecipient {
  final String domain;
  final String address;
  // The alias as the user entered it, e.g. user@example.com.
  final String displayAlias;

  const OpenAliasRecipient({
    required this.domain,
    required this.address,
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
  var name = input.trim();
  if (name.codeUnits.any((code) => code > 127)) {
    throw const OpenAliasException(
      'Use punycode for international domain names.',
    );
  }
  name = name.toLowerCase();
  if (name.split('@').length > 2) {
    throw const OpenAliasException(
      'Enter a domain or an email-style OpenAlias.',
    );
  }
  name = name.replaceAll('@', '.');
  if (name.endsWith('.')) name = name.substring(0, name.length - 1);
  // Underscores are valid in DNS names (RFC 2181), e.g. _service labels.
  final label = RegExp(r'^[a-z0-9_](?:[a-z0-9_-]{0,61}[a-z0-9_])?$');
  if (name.length > 253 ||
      !name.contains('.') ||
      !name.split('.').every(label.hasMatch) ||
      RegExp(r'^[0-9.]+$').hasMatch(name) ||
      name.endsWith('.onion')) {
    throw const OpenAliasException(
      'Enter a valid domain. Use punycode for international names.',
    );
  }
  return name;
}

Map<String, String>? parseOpenAliasRecord(String record) {
  if (record.length > 4096) {
    throw const OpenAliasException('The OpenAlias record is too large.');
  }
  final prefix = RegExp(r'^oa1:xmr(?:\s|$)').firstMatch(record);
  if (prefix == null) return null;
  final fields = <String, String>{};
  final body = record.substring(prefix.end);
  final parts = <String>[];
  var quoted = false;
  var escaped = false;
  var field = StringBuffer();
  for (final code in body.codeUnits) {
    final char = String.fromCharCode(code);
    if (code < 32 && char != '\t') {
      throw const OpenAliasException('The OpenAlias record is malformed.');
    }
    if (escaped) {
      field.write(char);
      escaped = false;
      continue;
    }
    if (char == '\\') {
      escaped = true;
      continue;
    }
    if (char == '"') quoted = !quoted;
    if (char == ';' && !quoted) {
      parts.add(field.toString());
      field = StringBuffer();
    } else {
      field.write(char);
    }
  }
  if (quoted || escaped) {
    throw const OpenAliasException('The OpenAlias record is malformed.');
  }
  parts.add(field.toString());
  for (final part in parts) {
    if (part.trim().isEmpty) continue;
    final equals = part.indexOf('=');
    if (equals < 1) {
      throw const OpenAliasException('The OpenAlias record is malformed.');
    }
    final key = part.substring(0, equals).trim();
    var value = part.substring(equals + 1).trim();
    if (!RegExp(r'^[a-z_]+$').hasMatch(key) || fields.containsKey(key)) {
      throw const OpenAliasException(
        'The OpenAlias record has duplicate or invalid fields.',
      );
    }
    if (value.startsWith('"') && value.endsWith('"') && value.length >= 2) {
      value = value.substring(1, value.length - 1);
    } else if (value.contains('"')) {
      throw const OpenAliasException('The OpenAlias record is malformed.');
    }
    fields[key] = value;
  }
  return fields;
}

OpenAliasRecipient selectOpenAliasRecipient({
  required String domain,
  required List<String> records,
  required bool Function(String) validateAddress,
}) {
  if (records.length > 64) {
    throw const OpenAliasException('Too many DNS records.');
  }
  final addresses = <String>{};
  for (final record in records) {
    final fields = parseOpenAliasRecord(record);
    if (fields == null) continue;
    if (fields['tx_payment_id']?.isNotEmpty ?? false) {
      throw const OpenAliasException(
        'This alias requires a separate payment ID, which is not supported.',
      );
    }
    final address = fields['recipient_address'];
    if (address == null || !validateAddress(address)) {
      throw const OpenAliasException(
        'This alias contains an invalid Monero address for this wallet.',
      );
    }
    addresses.add(address);
  }
  if (addresses.isEmpty) {
    throw const OpenAliasException('No Monero OpenAlias record was found.');
  }
  if (addresses.length != 1) {
    throw const OpenAliasException(
      'This alias has multiple Monero addresses. '
      'Ask the recipient for an address.',
    );
  }
  return OpenAliasRecipient(domain: domain, address: addresses.single);
}
