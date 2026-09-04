import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/address_utils.dart';

void main() {
  const seed =
      "abandon ability able about above absent absorb abstract absurd abuse "
      "access accident account accuse achieve acid acoustic acquire across act "
      "action actor actress actual";
  const viewKey =
      "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
  const spendKey =
      "fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210";
  const address =
      "4AeRgkWZsMJhAWKMeCZ3h4ZSPnAcW5VBtRFyLd6gBEf6GgJU2FHXDA6i1DnQTd6h8R3VU5"
      "AkbGcWSNhtSwNNPgaD48gp4nn";

  String logsWhileParsing(String uri) {
    final lines = <String>[];
    runZoned(
      () {
        try {
          WalletUriData.fromUriString(uri);
        } catch (_) {
          // The parse is expected to fail; the log it writes is what matters.
        }
      },
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, line) => lines.add(line),
      ),
    );
    return lines.join("\n");
  }

  group("a malformed wallet URI must not reach the log", () {
    // Each of these makes Uri.parse itself throw, which is the only path that
    // ever logged the caller's text.
    final malformed = <String, String>{
      "label pasted in front": "Wallet URI: monero_wallet:?seed=$seed",
      "invalid port": "monero_wallet://$address:1x?seed=$seed",
      "unterminated bracket": "monero_wallet://[$address?seed=$seed",
      "leading space": " monero_wallet:?seed=$seed",
    };

    malformed.forEach((name, uri) {
      test(name, () {
        final log = logsWhileParsing(uri);
        expect(log, contains("<redacted>"), reason: "redaction not applied");
        expect(log, isNot(contains("abandon")));
        expect(log, isNot(contains("ability")));
        expect(log, isNot(contains(uri)));
      });
    });

    test("private keys", () {
      final log = logsWhileParsing(
        "monero_wallet://$address:1x?view_key=$viewKey&spend_key=$spendKey",
      );
      expect(log, contains("<redacted>"));
      expect(log, isNot(contains(viewKey)));
      expect(log, isNot(contains(spendKey)));
    });
  });

  group("WalletUriData diagnostics", () {
    test("does not print a seed", () {
      final data = WalletUriData.fromUriString("monero_wallet:?seed=$seed");
      expect(data.seed, seed);
      expect(data.toString(), isNot(contains("abandon")));
    });

    test("does not print private keys", () {
      final data = WalletUriData.fromUriString(
        "monero_wallet:$address?view_key=$viewKey&spend_key=$spendKey",
      );
      expect(data.viewKey, viewKey);
      expect(data.spendKey, spendKey);
      expect(data.toString(), isNot(contains(viewKey)));
      expect(data.toString(), isNot(contains(spendKey)));
    });
  });
}
