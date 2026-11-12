import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';

/// The default themes are binary archives, so a coin missing from them only
/// shows as a placeholder icon at runtime.
void main() {
  for (final app in ["stack_wallet", "stack_duo"]) {
    for (final name in ["light", "dark"]) {
      test("the $app $name theme has Grin's colour and icons", () {
        final archive = ZipDecoder().decodeBytes(
          File("asset_sources/default_themes/$app/$name.zip").readAsBytesSync(),
        );
        final files = {
          for (final f in archive.files)
            if (f.isFile) f.name,
        };
        final json = jsonDecode(
          utf8.decode(
            archive.files.singleWhere((f) => f.name == "theme.json").content
                as List<int>,
          ),
        ) as Map<String, dynamic>;

        // Installed themes older than the app's default version are replaced
        // on startup; the archive has to carry the version that added Grin.
        expect(json["version"], greaterThanOrEqualTo(19));

        final colors = (json["colors"] as Map)["coin"] as Map;
        expect(colors["grin"], matches(RegExp(r"^0x[0-9A-Fa-f]{8}$")));

        final coins = (json["assets"] as Map)["coins"] as Map;
        expect(coins, isNotEmpty);
        for (final entry in coins.entries) {
          final path = (entry.value as Map)["grin"] as String?;
          expect(path, isNotNull, reason: "${entry.key} has no grin entry");
          expect(
            files,
            contains("assets/$path"),
            reason: "${entry.key} points at a file the archive lacks",
          );
        }
      });
    }
  }
}
