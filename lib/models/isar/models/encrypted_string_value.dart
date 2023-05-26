import 'package:isar/isar.dart';

part 'encrypted_string_value.g.dart';

@Collection()
class EncryptedStringValue {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String key;

  late String value;

  @override
  String toString() {
    return "EncryptedStringValue {\n    key=$key\n    value=$value\n}";
  }
}
