/// Helpers for Firo ProReg collateral signatures that use Bitcoin-style
/// signed-message framing.
///
/// The Firo network message prefix includes the Core magic byte `0x16`
/// before `"Zcoin Signed Message:\\n"`. The signer applies its own length
/// framing, so that byte must be supplied explicitly rather than inferred
/// from accidental equality with `length - 1`.
library firo_pro_reg_signed_message_prefix;

/// Prefix string passed to the message signer for Firo/Zcoin networks.
String firoMessagePrefixForCoinlibSign(String networkMessagePrefix) {
  const magic = 0x16;
  final bytes = networkMessagePrefix.codeUnits;
  if (bytes.isNotEmpty && bytes.first == magic) {
    return String.fromCharCodes(bytes.sublist(1));
  }
  return networkMessagePrefix;
}
