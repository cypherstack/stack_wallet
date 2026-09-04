import 'key_data_interface.dart';

class CWKeyData with KeyDataInterface {
  CWKeyData({
    required this.walletId,
    required this.privateSpendKey,
    required this.privateViewKey,
    required this.publicSpendKey,
    required this.publicViewKey,
  }) : keys = List.unmodifiable([
         (label: "Public View Key", key: publicViewKey),
         (label: "Private View Key", key: privateViewKey),
         (label: "Public Spend Key", key: publicSpendKey),
         (label: "Private Spend Key", key: privateSpendKey),
       ]);

  @override
  final String walletId;

  final String privateSpendKey;
  final String privateViewKey;
  final String publicSpendKey;
  final String publicViewKey;

  final List<({String label, String key})> keys;
}
