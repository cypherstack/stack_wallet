import 'dart:typed_data';

import '../../models/isar/models/blockchain_data/address.dart';
import '../../utilities/amount/amount.dart';

class TxRecipient {
  final String address;
  final Amount amount;
  final bool isChange;
  final AddressType addressType;
  final Uint8List? _memoBytes;
  final String? message;
  final Map<String, String> additionalParams;

  Uint8List? get memoBytes =>
      _memoBytes == null ? null : Uint8List.fromList(_memoBytes);

  TxRecipient({
    required this.address,
    required this.amount,
    required this.isChange,
    required this.addressType,
    Uint8List? memoBytes,
    this.message,
    Map<String, String> additionalParams = const {},
  }) : _memoBytes = memoBytes == null ? null : Uint8List.fromList(memoBytes),
       additionalParams = Map.unmodifiable(Map.of(additionalParams));

  TxRecipient copyWith({
    String? address,
    Amount? amount,
    bool? isChange,
    AddressType? addressType,
    Uint8List? memoBytes,
    String? message,
    Map<String, String>? additionalParams,
  }) {
    return TxRecipient(
      address: address ?? this.address,
      amount: amount ?? this.amount,
      isChange: isChange ?? this.isChange,
      addressType: addressType ?? this.addressType,
      memoBytes: memoBytes ?? this.memoBytes,
      message: message ?? this.message,
      additionalParams: additionalParams ?? this.additionalParams,
    );
  }

  @override
  String toString() {
    return "TxRecipient{"
        "address: $address, "
        "amount: $amount, "
        "isChange: $isChange, "
        "addressType: $addressType"
        ", memoBytes: ${memoBytes?.length} bytes"
        ", messageLength: ${message?.length}"
        ", additionalParamKeys: ${additionalParams.keys.toList()}"
        "}";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TxRecipient &&
          address == other.address &&
          amount == other.amount &&
          isChange == other.isChange &&
          addressType == other.addressType &&
          _bytesEqual(memoBytes, other.memoBytes) &&
          message == other.message &&
          _mapsEqual(additionalParams, other.additionalParams);

  @override
  int get hashCode => Object.hash(
    address,
    amount,
    isChange,
    addressType,
    Object.hashAll(memoBytes ?? const []),
    message,
    Object.hashAllUnordered(
      additionalParams.entries.map(
        (entry) => Object.hash(entry.key, entry.value),
      ),
    ),
  );
}

bool _bytesEqual(Uint8List? left, Uint8List? right) {
  if (identical(left, right)) return true;
  if (left == null || right == null || left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}

bool _mapsEqual(Map<String, String> left, Map<String, String> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) return false;
  }
  return true;
}
