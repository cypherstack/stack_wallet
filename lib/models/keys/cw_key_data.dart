import 'key_data_interface.dart';

class CWKeyData with KeyDataInterface {
  CWKeyData({
    required this.walletId,
    required String? privateSpendKey,
    required String? privateViewKey,
    required String? publicSpendKey,
    required String? publicViewKey,
  }) : keys = List.unmodifiable([
          (label: "Public View Key", key: publicViewKey),
          (label: "Private View Key", key: privateViewKey),
          (label: "Public Spend Key", key: publicSpendKey),
          (label: "Private Spend Key", key: privateSpendKey),
        ]);

  @override
  final String walletId;

  final List<({String label, String key})> keys;
}
