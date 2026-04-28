import 'package:fusiondart/src/extensions/on_list_int.dart';

class UtxoDTO {
  final String txid;
  final int vout;
  final int value;
  final List<int> pubKey;
  final String address;

  UtxoDTO({
    required this.txid,
    required this.vout,
    required this.value,
    required this.pubKey,
    required this.address,
  }) : assert(pubKey.isNotEmpty);

  @override
  bool operator ==(other) {
    if (other is UtxoDTO) {
      return txid == other.txid &&
          vout == other.vout &&
          value == other.value &&
          address == other.address &&
          pubKey.equals(other.pubKey);
    }

    return false;
  }

  @override
  int get hashCode => Object.hash(txid, vout, value, pubKey, address);
}
