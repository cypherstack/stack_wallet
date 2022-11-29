import 'package:isar/isar.dart';
// import 'package:epicmobile/models/isar/type_converters/log_level_converter.dart';
import 'package:epicmobile/utilities/enums/log_level_enum.dart';

part 'log.g.dart';

@Collection()
class Log {
  Id id = Isar.autoIncrement;

  late String message;

  @Index()
  late int timestampInMillisUTC;

  late LogLevel logLevel;

  @override
  String toString() {
    return "[${logLevel.name}][${DateTime.fromMillisecondsSinceEpoch(timestampInMillisUTC, isUtc: true)}]: $message";
  }
}
