import 'key_data_interface.dart';

class CWKeyData with KeyDataInterface {
  CWKeyData({
    required this.walletId,
    required String? privateSpendKey,
    required String? privateViewKey,
    required String? publicSpendKey,
    required String? publicViewKey,
  }) : keys = List.unmodifiable([
          (label: "Public View Key", key: publicViewKey, isPrivate: false),
          (label: "Private View Key", key: privateViewKey, isPrivate: true),
          (label: "Public Spend Key", key: publicSpendKey, isPrivate: false),
          (label: "Private Spend Key", key: privateSpendKey, isPrivate: true),
        ]);

  @override
  final String walletId;

  final List<({String label, String key, bool isPrivate})> keys;
}
