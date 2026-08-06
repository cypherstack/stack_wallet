import 'package:isar_community/isar.dart';

part 'log.g.dart';

enum LogLevel { Info, Warning, Error, Fatal, Debug }

@Collection()
class Log {
  Id id = Isar.autoIncrement;

  late String message;

  @Index()
  late int timestampInMillisUTC;

  @Enumerated(EnumType.name)
  late LogLevel logLevel;
}
