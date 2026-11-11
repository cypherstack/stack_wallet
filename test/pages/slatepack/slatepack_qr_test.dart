import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/slatepack/slatepack_qr.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/widgets/qr.dart';

import '../../sample_data/theme_json.dart';

Widget _app(Widget child) => MaterialApp(
  theme: ThemeData(
    extensions: [
      StackColors.fromStackColorTheme(
        StackTheme.fromJson(json: lightThemeJsonMap),
      ),
    ],
  ),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  test("length guard", () {
    expect(slatepackFitsQr("a" * kSlatepackQrMaxBytes), isTrue);
    expect(slatepackFitsQr("a" * (kSlatepackQrMaxBytes + 1)), isFalse);
    // Bytes count, not characters.
    expect(slatepackFitsQr("é" * (kSlatepackQrMaxBytes ~/ 2)), isTrue);
    expect(slatepackFitsQr("é" * (kSlatepackQrMaxBytes ~/ 2 + 1)), isFalse);
  });

  testWidgets("the longest slatepack that fits is drawn", (tester) async {
    await tester.pumpWidget(
      _app(SlatepackQr(data: "a" * kSlatepackQrMaxBytes, noun: "slate")),
    );
    await tester.pump();
    expect(find.byKey(const Key("slatepackQrCode")), findsOneWidget);
    expect(find.byKey(const Key("slatepackQrTooLong")), findsNothing);
    expect(find.text("Too much data to show as a QR code"), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("a slate of a few thousand characters is drawn", (tester) async {
    await tester.pumpWidget(
      _app(SlatepackQr(data: '{"slate": "${"a" * 2400}"}', noun: "slate")),
    );
    await tester.pump();
    expect(find.byKey(const Key("slatepackQrCode")), findsOneWidget);
    expect(find.text("Too much data to show as a QR code"), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("short slatepack shows a QR code", (tester) async {
    await tester.pumpWidget(
      _app(
        const SlatepackQr(
          data: "BEGINSLATEPACK. abc. ENDSLATEPACK.",
          noun: "slatepack",
        ),
      ),
    );
    expect(find.byKey(const Key("slatepackQrCode")), findsOneWidget);
    expect(find.byType(QR), findsOneWidget);
    expect(find.byKey(const Key("slatepackQrTooLong")), findsNothing);
  });

  testWidgets("tap enlarges the QR code", (tester) async {
    await tester.pumpWidget(
      _app(const SlatepackQr(data: "short", noun: "slatepack")),
    );
    await tester.tap(find.byKey(const Key("slatepackQrCode")));
    await tester.pumpAndSettle();
    expect(find.byType(QR), findsNWidgets(2));
  });

  testWidgets("long slatepack falls back to a note", (tester) async {
    await tester.pumpWidget(
      _app(SlatepackQr(data: "a" * (kSlatepackQrMaxBytes + 1), noun: "slate")),
    );
    expect(find.byType(QR), findsNothing);
    expect(find.byKey(const Key("slatepackQrTooLong")), findsOneWidget);
    expect(find.textContaining("too long for a QR code"), findsOneWidget);
  });

  testWidgets("QR shows a message when data does not fit", (tester) async {
    await tester.pumpWidget(_app(QR(data: "x" * 5000, size: 200)));
    await tester.pump();
    expect(find.text("Too much data to show as a QR code"), findsOneWidget);
  });
}
