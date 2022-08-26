import 'package:isar/isar.dart';

// Used in Isar db and stored there as int indexes so adding/removing values
// in this definition should be done extremely carefully in production
enum LogLevel with IsarEnum<String> {
  Info,
  Warning,
  Error,
  Fatal;

  @override
  String get value => name;
}
