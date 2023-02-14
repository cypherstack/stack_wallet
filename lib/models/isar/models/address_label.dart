import 'package:isar/isar.dart';

part 'address_label.g.dart';

@Collection()
class AddressLabel {
  AddressLabel({
    required this.walletId,
    required this.addressString,
    required this.value,
  });

  Id id = Isar.autoIncrement;

  @Index()
  late final String walletId;

  @Index(unique: true, composite: [CompositeIndex("walletId")])
  late final String addressString;

  late final String value;

  AddressLabel copyWith({String? label, Id? id}) {
    final addressLabel = AddressLabel(
      walletId: walletId,
      addressString: addressString,
      value: label ?? value,
    );
    addressLabel.id = id ?? this.id;
    return addressLabel;
  }
}
