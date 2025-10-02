import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print(
      'Usage: dart process_pubspec_deps.dart <file> <marker1> [marker2 ...]',
    );
    exit(1);
  }

  if (args.length == 1) {
    print('No markers specified. Nothing to do.');
    exit(0);
  }

  _process(args[0], args.sublist(1));
}

void _process(final String filePath, final List<String> enableCoinMarkers) {
  final lines = File(filePath).readAsLinesSync();

  String? activeMarker;
  final List<String> updatedLines = [];

  for (final line in lines) {
    bool markerSet = false;

    // Check if line starts any marker block
    for (final marker in enableCoinMarkers) {
      if (line.contains('# %%ENABLE_$marker%%')) {
        activeMarker = marker;
        markerSet = true;
        updatedLines.add(line);
        break;
      }
    }

    if (markerSet) continue;

    // Check if line ends the active marker block
    if (activeMarker != null &&
        line.contains('# %%END_ENABLE_$activeMarker%%')) {
      activeMarker = null;
      updatedLines.add(line);
      continue;
    }

    // If inside an active marker block, uncomment line
    if (activeMarker != null) {
      updatedLines.add(line.replaceFirst("#", ""));
    } else {
      updatedLines.add(line);
    }
  }

  File(filePath).writeAsStringSync(updatedLines.join('\n'));
  print(
    'Updated pubspec.yaml with enabled blocks: ${enableCoinMarkers.join(", ")}',
  );
}

void _genFile(String outputFilePath, String template, bool on) {
  final lines = File(template).readAsLinesSync();

  // add empty line and gen warning

  final List<String> updatedLines = [
    "// GENERATED CODE - DO NOT MODIFY BY HAND",
    "",
  ];

  final keepMarker = on ? "ON" : "OFF";

  bool? keepLine;

  for (final line in lines) {
    if (line.trim() == "//$keepMarker") {
      keepLine = true;
      continue;
    }

    if (line.trim() == "//END_$keepMarker") {
      keepLine = false;
      continue;
    }

    if (keepLine != false) {
      updatedLines.add(line);
    }
  }

  // add empty line
  if (updatedLines.last.isNotEmpty) updatedLines.add("");

  File(outputFilePath).writeAsStringSync(updatedLines.join('\n'));
}
