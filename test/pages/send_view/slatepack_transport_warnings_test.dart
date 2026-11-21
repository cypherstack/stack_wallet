import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/slatepack_models.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/slatepack_transport_warnings.dart';
import 'package:stackwallet/themes/stack_colors.dart';

import '../../sample_data/theme_json.dart';

void main() {
  group('allows', () {
    test('no policy: not a direct send', () {
      expect(
        SlatepackTransportWarnings.allows(
          null,
          clearnetAck: false,
          plaintextAck: false,
        ),
        isTrue,
      );
    });

    test('blocked never allows', () {
      const policy = SlatepackHttpPolicy(blockedReason: 'Tor is down.');
      expect(
        SlatepackTransportWarnings.allows(
          policy,
          clearnetAck: true,
          plaintextAck: true,
        ),
        isFalse,
      );
    });

    test('each warning needs its own tick', () {
      const policy = SlatepackHttpPolicy(
        needsClearnetAck: true,
        needsPlaintextAck: true,
      );
      bool allows(bool c, bool p) => SlatepackTransportWarnings.allows(
        policy,
        clearnetAck: c,
        plaintextAck: p,
      );
      expect(allows(false, false), isFalse);
      expect(allows(true, false), isFalse);
      expect(allows(false, true), isFalse);
      expect(allows(true, true), isTrue);
    });
  });

  group('widget', () {
    Future<({List<bool> clearnet, List<bool> plaintext})> pump(
      WidgetTester tester,
      SlatepackHttpPolicy policy,
    ) async {
      final clearnet = <bool>[];
      final plaintext = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                StackTheme.fromJson(json: lightThemeJsonMap),
              ),
            ],
          ),
          home: Scaffold(
            body: SlatepackTransportWarnings(
              policy: policy,
              onClearnetAck: clearnet.add,
              onPlaintextAck: plaintext.add,
            ),
          ),
        ),
      );
      return (clearnet: clearnet, plaintext: plaintext);
    }

    testWidgets('blocked shows the reason and no ticks', (tester) async {
      await pump(
        tester,
        const SlatepackHttpPolicy(blockedReason: 'Tor is not connected.'),
      );
      expect(find.textContaining('Tor is not connected.'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('clearnet warning reports its tick', (tester) async {
      final ticks = await pump(
        tester,
        const SlatepackHttpPolicy(needsClearnetAck: true),
      );
      expect(find.textContaining('IP address'), findsWidgets);
      expect(find.byKey(const Key('slatepackPlaintextAck')), findsNothing);
      await tester.tap(find.byKey(const Key('slatepackClearnetAck')));
      await tester.pump();
      expect(ticks.clearnet, [true]);
      expect(ticks.plaintext, isEmpty);
    });

    testWidgets('plain http warning shows even over Tor', (tester) async {
      final ticks = await pump(
        tester,
        const SlatepackHttpPolicy(needsPlaintextAck: true),
      );
      expect(find.byKey(const Key('slatepackClearnetAck')), findsNothing);
      await tester.tap(find.byKey(const Key('slatepackPlaintextAck')));
      await tester.pump();
      expect(ticks.plaintext, [true]);
    });
  });
}
