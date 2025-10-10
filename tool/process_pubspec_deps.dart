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
      if (line.trim() == "# %%ENABLE_$marker%%") {
        activeMarker = marker;
        markerSet = true;
        updatedLines.add(line);
        break;
      }
    }

    if (markerSet) continue;

    // Check if line ends the active marker block
    if (activeMarker != null &&
        line.trim() == "# %%END_ENABLE_$activeMarker%%") {
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
