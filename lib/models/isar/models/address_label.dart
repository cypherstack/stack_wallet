import 'package:isar/isar.dart';

part 'address_label.g.dart';

@Collection()
class AddressLabel {
  AddressLabel({
    required this.walletId,
    required this.addressString,
    required this.value,
    required this.tags,
  });

  Id id = Isar.autoIncrement;

  @Index()
  late final String walletId;

  @Index(unique: true, composite: [CompositeIndex("walletId")])
  late final String addressString;

  late final String value;

  late final List<String>? tags;

  AddressLabel copyWith({String? label, Id? id, List<String>? tags}) {
    final addressLabel = AddressLabel(
      walletId: walletId,
      addressString: addressString,
      value: label ?? value,
      tags: tags ?? this.tags,
    );
    addressLabel.id = id ?? this.id;
    return addressLabel;
  }
}
