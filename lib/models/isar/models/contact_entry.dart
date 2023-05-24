import 'package:isar/isar.dart';

part 'contact_entry.g.dart';

@collection
class ContactEntry {
  ContactEntry({
    this.emojiChar,
    required this.name,
    required this.addresses,
    required this.isFavorite,
    required this.customId,
  });

  Id id = Isar.autoIncrement;

  late final String? emojiChar;
  late final String name;
  late final List<String> addresses;
  late final bool isFavorite;

  @Index(unique: true, replace: true)
  late final String customId;
}