import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/providers/hardware/hardware_wallet_provider.dart';
import 'package:stackwallet/wallets/hardware/hardware_session_state.dart';
import 'package:stackwallet/wallets/hardware/hardware_wallet_device_family.dart';
import 'package:stackwallet/wallets/hardware/ledger/ledger_usb_adapter.dart';
import 'package:stackwallet/wallets/hardware/trezor/trezor_adapter_stub.dart';

void main() {
  group('Hardware provider-adapter integration', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Ledger family returns LedgerUsbAdapter', () {
      final adapter = container.read(
        hardwareAdapterProvider(HardwareWalletDeviceFamily.ledger),
      );

      expect(adapter, isNotNull);
      expect(adapter, isA<LedgerUsbAdapter>());
    });

    test('Trezor family returns TrezorAdapterStub', () {
      final adapter = container.read(
        hardwareAdapterProvider(HardwareWalletDeviceFamily.trezor),
      );

      expect(adapter, isNotNull);
      expect(adapter, isA<TrezorAdapterStub>());
    });

    test('Foundation family returns null (gated)', () {
      final adapter = container.read(
        hardwareAdapterProvider(HardwareWalletDeviceFamily.foundation),
      );

      expect(adapter, isNull);
    });

    test('initial session state is idle', () {
      expect(
        container.read(hardwareSessionStateProvider),
        HardwareSessionState.idle,
      );
    });

    test('family selection state updates correctly', () {
      expect(container.read(selectedHardwareFamilyProvider), isNull);

      container.read(selectedHardwareFamilyProvider.notifier).state =
          HardwareWalletDeviceFamily.ledger;
      expect(
        container.read(selectedHardwareFamilyProvider),
        HardwareWalletDeviceFamily.ledger,
      );

      container.read(selectedHardwareFamilyProvider.notifier).state =
          HardwareWalletDeviceFamily.trezor;
      expect(
        container.read(selectedHardwareFamilyProvider),
        HardwareWalletDeviceFamily.trezor,
      );

      container.read(selectedHardwareFamilyProvider.notifier).state =
          HardwareWalletDeviceFamily.foundation;
      expect(
        container.read(selectedHardwareFamilyProvider),
        HardwareWalletDeviceFamily.foundation,
      );
    });

    test('TrezorAdapterStub methods throw UnimplementedError', () {
      final stub = container.read(
        hardwareAdapterProvider(HardwareWalletDeviceFamily.trezor),
      ) as TrezorAdapterStub;

      expect(
        () => stub.isConnected,
        throwsA(isA<UnimplementedError>()),
      );
      expect(
        () => stub.scanForDevices(),
        throwsA(isA<UnimplementedError>()),
      );
      expect(
        () => stub.disconnect(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('all families are covered by adapter provider', () {
      for (final family in HardwareWalletDeviceFamily.values) {
        final adapter = container.read(hardwareAdapterProvider(family));
        switch (family) {
          case HardwareWalletDeviceFamily.ledger:
            expect(adapter, isA<LedgerUsbAdapter>());
          case HardwareWalletDeviceFamily.trezor:
            expect(adapter, isA<TrezorAdapterStub>());
          case HardwareWalletDeviceFamily.foundation:
            expect(adapter, isNull);
        }
      }
    });
  });
}
