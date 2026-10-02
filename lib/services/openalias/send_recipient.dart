import 'open_alias.dart';

enum SendRecipientKind { literal, openAlias, invalid }

// Local send-field classification only. Literal-address validators remain
// unchanged, and an alias is not a usable transaction recipient until resolved.
class SendRecipient {
  final SendRecipientKind kind;
  final String destination;

  const SendRecipient._(this.kind, this.destination);

  factory SendRecipient.classify(
    String input, {
    required bool supportsOpenAlias,
    required bool Function(String) validateAddress,
  }) {
    final destination = input.trim();
    if (validateAddress(destination)) {
      return SendRecipient._(SendRecipientKind.literal, destination);
    }
    if (supportsOpenAlias) {
      try {
        return SendRecipient._(
          SendRecipientKind.openAlias,
          normalizeOpenAlias(destination),
        );
      } on OpenAliasException {
        // Invalid input stays editable without initiating a lookup.
      }
    }
    return SendRecipient._(SendRecipientKind.invalid, destination);
  }

  bool get isAlias => kind == SendRecipientKind.openAlias;
}
