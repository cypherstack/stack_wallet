import 'dart:io';

void main(List<String> args) {
  if (args.length < 2) {
    print(
      'Usage: dart process_pubspec_deps.dart <templatesDir> <generatedDir> <marker1> [marker2 ...]',
    );
    exit(1);
  }

  final generatedDir = Directory(args[1]);
  if (!generatedDir.existsSync()) generatedDir.createSync();

  final templatesDir = args[0];

  final List<String> onFilePrefixes = args.length > 2 ? args.sublist(2) : [];

  final templates = Directory(templatesDir).listSync().whereType<File>();

  print(templates.map((e) => e.uri.pathSegments.last));

  for (final template in templates) {
    final templateName = template.uri.pathSegments.last;

    final prefix = templateName.split("_").first;

    final outfileUri = generatedDir.uri.resolve(
      templateName
          .replaceFirst("${prefix}_", "")
          .replaceFirst(".template.", "."),
    );

    _genFile(
      outfileUri.toFilePath(),
      template,
      onFilePrefixes.contains(prefix),
    );
  }
}

void _genFile(String outputFilePath, File template, bool on) {
  final lines = template.readAsLinesSync();

  // add empty line and gen warning

  final List<String> updatedLines = [
    "// GENERATED CODE - DO NOT MODIFY BY HAND",
    "",
  ];

  final keepMarker = on ? "ON" : "OFF";
  final dropMarker = on ? "OFF" : "ON";

  bool? keepLine;

  for (final line in lines) {
    if (line.trim() == "//$keepMarker") {
      keepLine = true;
      continue;
    }

    if (line.trim() == "//$dropMarker") {
      keepLine = false;
      continue;
    }

    if (line.trim().startsWith("//END_")) {
      keepLine = null;
      continue;
    }

    if (keepLine != false) {
      updatedLines.add(line);
    }
  }

  // add empty line
  if (updatedLines.last.isNotEmpty) updatedLines.add("");

  File(outputFilePath).writeAsStringSync(updatedLines.join('\n'));

  print("Done gen of $template => $outputFilePath");
}
