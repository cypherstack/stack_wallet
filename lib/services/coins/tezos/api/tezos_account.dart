class TezosAccount {
  final int id;
  final String type;
  final String address;
  final String? publicKey;
  final bool revealed;
  final int balance;
  final int counter;

  TezosAccount({
    required this.id,
    required this.type,
    required this.address,
    required this.publicKey,
    required this.revealed,
    required this.balance,
    required this.counter,
  });

  TezosAccount copyWith({
    int? id,
    String? type,
    String? address,
    String? publicKey,
    bool? revealed,
    int? balance,
    int? counter,
  }) {
    return TezosAccount(
      id: id ?? this.id,
      type: type ?? this.type,
      address: address ?? this.address,
      publicKey: publicKey ?? this.publicKey,
      revealed: revealed ?? this.revealed,
      balance: balance ?? this.balance,
      counter: counter ?? this.counter,
    );
  }

  factory TezosAccount.fromMap(Map<String, dynamic> map) {
    return TezosAccount(
      id: map['id'] as int,
      type: map['type'] as String,
      address: map['address'] as String,
      publicKey: map['publicKey'] as String?,
      revealed: map['revealed'] as bool,
      balance: map['balance'] as int,
      counter: map['counter'] as int,
    );
  }

  @override
  String toString() {
    return 'UserData{id: $id, type: $type, address: $address, '
        'publicKey: $publicKey, revealed: $revealed,'
        ' balance: $balance, counter: $counter}';
  }
}
