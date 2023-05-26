// Used in Isar db and stored there as int indexes so adding/removing values
// in this definition should be done extremely carefully in production
enum LogLevel {
  Info,
  Warning,
  Error,
  Fatal;
}
