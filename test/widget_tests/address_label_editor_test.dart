import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/address_label.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/providers/wallet/address_label_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/address_label_editor.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_edit_button.dart';

import '../sample_data/theme_json.dart';

void main() {
  late _FakeAddressLabelStore store;
  late _FakeAddressLabelWriter writer;

  setUp(() {
    store = _FakeAddressLabelStore();
    writer = _FakeAddressLabelWriter();
  });
  tearDown(() {
    Util.screenWidth = null;
    store.dispose();
  });

  for (final isDesktop in [false, true]) {
    testWidgets(
      '${isDesktop ? 'desktop' : 'mobile'} editor follows external updates',
      (tester) async {
        Util.screenWidth = isDesktop ? null : 400;
        store.values[_key] = _label('Original');
        await _pumpEditor(tester, store, writer, isDesktop: isDesktop);
        expect(find.text('Original'), findsOneWidget);

        store.emit(_key, _label('External update'));
        await tester.pump();
        await tester.pump();

        expect(find.text('External update'), findsOneWidget);
        expect(find.text('Original'), findsNothing);
      },
    );
  }

  testWidgets('serializes rapid create, update, and clear writes', (
    tester,
  ) async {
    final firstWrite = Completer<void>();
    writer.onWrite = (key, value) async {
      if (value == 'First') {
        await firstWrite.future;
      }
      store.emit(key, _label(value));
    };
    await _pumpEditor(tester, store, writer, isDesktop: true);

    final editButton = tester.widget<SimpleEditButton>(
      find.byType(SimpleEditButton),
    );
    editButton.onValueChanged!('First');
    editButton.onValueChanged!('Second');
    await tester.pump();
    expect(writer.values, ['First']);

    firstWrite.complete();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(writer.values, ['First', 'Second']);
    expect(find.text('Second'), findsOneWidget);

    tester
        .widget<SimpleEditButton>(find.byType(SimpleEditButton))
        .onValueChanged!('');
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('No label'), findsOneWidget);
  });

  testWidgets('reports a write failure and accepts the next edit', (
    tester,
  ) async {
    var shouldFail = true;
    writer.onWrite = (key, value) async {
      if (shouldFail) {
        shouldFail = false;
        throw StateError('write failed');
      }
      store.emit(key, _label(value));
    };
    await _pumpEditor(tester, store, writer, isDesktop: true);

    var editButton = tester.widget<SimpleEditButton>(
      find.byType(SimpleEditButton),
    );
    editButton.onValueChanged!('Fails');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Failed to update address label'), findsOneWidget);

    editButton = tester.widget<SimpleEditButton>(find.byType(SimpleEditButton));
    editButton.onValueChanged!('Recovered');
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('Recovered'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  });

  testWidgets('writes to the address the edit was started on', (tester) async {
    await _pumpEditor(tester, store, writer, isDesktop: true, address: 'A');
    final onValueChanged = tester
        .widget<SimpleEditButton>(find.byType(SimpleEditButton))
        .onValueChanged!;

    // A wallet refresh rotates the receiving address while the edit view is
    // open, rebuilding this editor in place.
    await _pumpEditor(tester, store, writer, isDesktop: true, address: 'B');
    onValueChanged('Invoice #1');
    await tester.pump();
    await tester.pump();

    expect(writer.keys.single.address, 'A');
    expect(writer.values, ['Invoice #1']);
  });

  testWidgets('persists an edit returned after the editor is disposed', (
    tester,
  ) async {
    await _pumpEditor(tester, store, writer, isDesktop: true);
    final onValueChanged = tester
        .widget<SimpleEditButton>(find.byType(SimpleEditButton))
        .onValueChanged!;

    await tester.pumpWidget(const SizedBox());
    onValueChanged('Late');
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(writer.values, ['Late']);
  });
}

const _address = 'address';
const _key = (walletId: 'wallet', address: _address);

AddressLabel _label(String value) => AddressLabel(
  walletId: _key.walletId,
  addressString: _key.address,
  value: value,
  tags: null,
);

Future<void> _pumpEditor(
  WidgetTester tester,
  _FakeAddressLabelStore store,
  _FakeAddressLabelWriter writer, {
  required bool isDesktop,
  String address = _address,
}) => tester.pumpWidget(
  ProviderScope(
    overrides: [
      addressLabelStoreProvider.overrideWithValue(store),
      addressLabelWriterProvider.overrideWithValue(writer),
    ],
    child: MaterialApp(
      theme: ThemeData(
        extensions: [
          StackColors.fromStackColorTheme(
            StackTheme.fromJson(json: lightThemeJsonMap),
          ),
        ],
      ),
      home: Scaffold(
        body: AddressLabelEditor(
          walletId: _key.walletId,
          address: address,
          isDesktop: isDesktop,
        ),
      ),
    ),
  ),
);

class _FakeAddressLabelStore implements AddressLabelStore {
  final values = <AddressLabelKey, AddressLabel?>{};
  final _controllers =
      <AddressLabelKey, StreamController<List<AddressLabel>>>{};

  @override
  AddressLabel? find(AddressLabelKey key) => values[key];

  @override
  Stream<List<AddressLabel>> watch(AddressLabelKey key) => _controllers
      .putIfAbsent(key, StreamController<List<AddressLabel>>.broadcast)
      .stream;

  void emit(AddressLabelKey key, AddressLabel? label) {
    values[key] = label;
    _controllers[key]?.add(label == null ? [] : [label]);
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
  }
}

class _FakeAddressLabelWriter implements AddressLabelWriter {
  Future<void> Function(AddressLabelKey key, String value)? onWrite;
  final values = <String>[];
  final keys = <AddressLabelKey>[];

  @override
  Future<void> write(AddressLabelKey key, String value) async {
    values.add(value);
    keys.add(key);
    await onWrite?.call(key, value);
  }
}
