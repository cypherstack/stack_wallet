import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/address_label.dart';
import 'package:stackwallet/providers/wallet/address_label_provider.dart';

void main() {
  late _FakeAddressLabelStore store;

  setUp(() => store = _FakeAddressLabelStore());
  tearDown(() => store.dispose());

  testWidgets('updates a visible label without another data event', (
    tester,
  ) async {
    store.value = _label('Original label');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [addressLabelStoreProvider.overrideWithValue(store)],
        child: const MaterialApp(home: _LabelText()),
      ),
    );
    expect(find.text('Original label'), findsOneWidget);

    store.emit(_label('Updated label'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Updated label'), findsOneWidget);
    expect(find.text('Original label'), findsNothing);
  });

  testWidgets('reacts when a label is created and deleted', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [addressLabelStoreProvider.overrideWithValue(store)],
        child: const MaterialApp(home: _LabelText()),
      ),
    );
    expect(find.text('No label'), findsOneWidget);

    store.emit(_label('New label'));
    await tester.pump();
    await tester.pump();
    expect(find.text('New label'), findsOneWidget);

    store.emit(null);
    await tester.pump();
    await tester.pump();
    expect(find.text('No label'), findsOneWidget);
  });

  test(
    'a failing watch stream does not escape and does not stop the watcher',
    () async {
      store.value = _label('Original label');

      Object? escaped;
      AddressLabel? afterError;
      late final ProviderContainer container;

      await runZonedGuarded(() async {
        container = ProviderContainer(
          overrides: [addressLabelStoreProvider.overrideWithValue(store)],
        );
        addTearDown(container.dispose);
        final sub = container.listen<AddressLabel?>(
          pAddressLabel(_key),
          (_, __) {},
        );
        addTearDown(sub.close);

        store.emitError(StateError('db closed'));
        await Future<void>.delayed(Duration.zero);
        afterError = container.read(pAddressLabel(_key));

        store.emit(_label('Updated label'));
        await Future<void>.delayed(Duration.zero);
      }, (error, _) => escaped = error);

      expect(escaped, isNull);
      expect(afterError?.value, 'Original label');
      expect(container.read(pAddressLabel(_key))?.value, 'Updated label');
    },
  );
}

const _key = (walletId: 'wallet', address: 'address');

AddressLabel _label(String value) => AddressLabel(
  walletId: 'wallet',
  addressString: 'address',
  value: value,
  tags: null,
);

class _FakeAddressLabelStore implements AddressLabelStore {
  final _controller = StreamController<List<AddressLabel>>.broadcast();
  AddressLabel? value;

  @override
  AddressLabel? find(AddressLabelKey key) => value;

  @override
  Stream<List<AddressLabel>> watch(AddressLabelKey key) => _controller.stream;

  void emit(AddressLabel? label) {
    value = label;
    _controller.add(label == null ? [] : [label]);
  }

  void emitError(Object error) => _controller.addError(error);

  void dispose() => _controller.close();
}

class _LabelText extends ConsumerWidget {
  const _LabelText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = ref.watch(
      pAddressLabel((walletId: 'wallet', address: 'address')),
    );
    return Text(label?.value ?? 'No label');
  }
}
