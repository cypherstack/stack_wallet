import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/transaction_note.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/exchange_view/edit_trade_note_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/edit_note_view.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/exchange/trade_note_service_provider.dart';
import 'package:stackwallet/providers/wallet/transaction_note_provider.dart';
import 'package:stackwallet/services/trade_notes_service.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';

import '../sample_data/theme_json.dart';

void main() {
  late double? originalScreenWidth;

  setUp(() {
    originalScreenWidth = Util.screenWidth;
    Util.screenWidth = 400;
  });

  tearDown(() {
    Util.screenWidth = originalScreenWidth;
  });

  ThemeData buildTheme() {
    return ThemeData(
      extensions: [
        StackColors.fromStackColorTheme(
          StackTheme.fromJson(json: lightThemeJsonMap),
        ),
      ],
    );
  }

  ThemeService buildThemeService() =>
      _TestThemeService(StackTheme.fromJson(json: lightThemeJsonMap));

  testWidgets('trade notes accept and save multiple lines', (tester) async {
    final service = _RecordingTradeNotesService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pThemeService.overrideWithValue(buildThemeService()),
          tradeNoteServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: const EditTradeNoteView(tradeId: 'trade-id', note: ''),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.minLines, 3);
    expect(field.maxLines, 6);
    expect(field.keyboardType, TextInputType.multiline);
    expect(field.textInputAction, TextInputAction.newline);

    await tester.enterText(find.byType(TextField), 'first line\nsecond line');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(service.savedTradeId, 'trade-id');
    expect(service.savedNote, 'first line\nsecond line');
  });

  testWidgets('transaction notes accept and save multiple lines', (
    tester,
  ) async {
    final db = _RecordingMainDB();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pThemeService.overrideWithValue(buildThemeService()),
          mainDBProvider.overrideWithValue(db),
          pTransactionNote.overrideWithProvider(
            (key) => Provider((ref) => null),
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: const EditNoteView(txid: 'txid', walletId: 'wallet-id'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.minLines, 3);
    expect(field.maxLines, 6);
    expect(field.keyboardType, TextInputType.multiline);
    expect(field.textInputAction, TextInputAction.newline);

    await tester.enterText(find.byType(TextField), 'first line\nsecond line');
    await tester.tap(find.text('Save'));
    await tester.pump();

    final saved = db.savedNote!;
    expect(saved.walletId, 'wallet-id');
    expect(saved.txid, 'txid');
    expect(saved.value, 'first line\nsecond line');
  });

  // Desktop opens both editors inside a fixed size DesktopDialog; every call
  // site uses 580x360.
  Future<void> pumpInDesktopDialog(
    WidgetTester tester, {
    required List<Override> overrides,
    required Widget child,
  }) async {
    Util.screenWidth = null;
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: buildTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => DesktopDialog(
                    maxWidth: 580,
                    maxHeight: 360,
                    child: child,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// A note taller than the dialog must scroll inside it: no overflow, and Save
  /// still painted within the dialog card.
  Future<void> expectNoteFitsDialog(WidgetTester tester, String note) async {
    await tester.enterText(find.byType(TextField), note);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final card = tester.getRect(
      find
          .descendant(
            of: find.byType(DesktopDialog),
            matching: find.byType(Material),
          )
          .first,
    );
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(DesktopDialog),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pumpAndSettle();

    final save = tester.getRect(find.text('Save'));
    expect(save.top, greaterThanOrEqualTo(card.top));
    expect(save.bottom, lessThanOrEqualTo(card.bottom));
  }

  for (final lines in [1, 3, 4, 6]) {
    testWidgets('desktop transaction note editor fits $lines line(s)', (
      tester,
    ) async {
      await pumpInDesktopDialog(
        tester,
        overrides: [
          pThemeService.overrideWithValue(buildThemeService()),
          mainDBProvider.overrideWithValue(_RecordingMainDB()),
          pTransactionNote.overrideWithProvider(
            (key) => Provider((ref) => null),
          ),
        ],
        child: const EditNoteView(txid: 'txid', walletId: 'wallet-id'),
      );

      await expectNoteFitsDialog(
        tester,
        List.generate(lines, (i) => 'line $i').join('\n'),
      );
    });
  }

  testWidgets('desktop transaction note editor fits a wrapped paragraph', (
    tester,
  ) async {
    await pumpInDesktopDialog(
      tester,
      overrides: [
        pThemeService.overrideWithValue(buildThemeService()),
        mainDBProvider.overrideWithValue(_RecordingMainDB()),
        pTransactionNote.overrideWithProvider((key) => Provider((ref) => null)),
      ],
      child: const EditNoteView(txid: 'txid', walletId: 'wallet-id'),
    );

    // No newline at all: soft wrapping alone grows the field to maxLines.
    await expectNoteFitsDialog(tester, List.filled(80, 'word').join(' '));
  });

  testWidgets('desktop transaction note editor fits a very long note', (
    tester,
  ) async {
    await pumpInDesktopDialog(
      tester,
      overrides: [
        pThemeService.overrideWithValue(buildThemeService()),
        mainDBProvider.overrideWithValue(_RecordingMainDB()),
        pTransactionNote.overrideWithProvider((key) => Provider((ref) => null)),
      ],
      child: const EditNoteView(txid: 'txid', walletId: 'wallet-id'),
    );

    await expectNoteFitsDialog(
      tester,
      List.generate(400, (i) => 'line $i ${'x' * 40}').join('\n'),
    );
  });

  testWidgets('desktop trade note editor fits six lines', (tester) async {
    await pumpInDesktopDialog(
      tester,
      overrides: [
        pThemeService.overrideWithValue(buildThemeService()),
        tradeNoteServiceProvider.overrideWithValue(
          _RecordingTradeNotesService(),
        ),
      ],
      child: const EditTradeNoteView(tradeId: 'trade-id', note: ''),
    );

    await expectNoteFitsDialog(
      tester,
      List.generate(6, (i) => 'line $i').join('\n'),
    );
  });
}

class _TestThemeService extends Fake implements ThemeService {
  _TestThemeService(this.theme);

  final StackTheme theme;

  @override
  StackTheme? getTheme({required String themeId}) => theme;
}

class _RecordingMainDB extends Fake implements MainDB {
  TransactionNote? savedNote;

  @override
  Future<void> putTransactionNote(TransactionNote transactionNote) async {
    savedNote = transactionNote;
  }
}

class _RecordingTradeNotesService extends TradeNotesService {
  String? savedTradeId;
  String? savedNote;

  @override
  Future<void> set({required String tradeId, required String note}) async {
    savedTradeId = tradeId;
    savedNote = note;
  }
}
