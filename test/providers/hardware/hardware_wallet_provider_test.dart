import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/providers/hardware/hardware_wallet_provider.dart';
import 'package:stackwallet/wallets/hardware/hardware_session_state.dart';
import 'package:stackwallet/wallets/hardware/hardware_wallet_adapter.dart';
import 'package:stackwallet/wallets/hardware/hardware_wallet_connection_type.dart';
import 'package:stackwallet/wallets/hardware/hardware_wallet_device.dart';
import 'package:stackwallet/wallets/hardware/hardware_wallet_device_family.dart';

class _TestDevice extends HardwareWalletDevice {
  _TestDevice({
    required super.name,
    required super.family,
    required super.connectionType,
    required super.model,
  });
}

class _FakeAdapter implements HardwareWalletAdapter {
  bool connectCalled = false;
  bool disconnectCalled = false;
  bool scanCalled = false;
  List<HardwareWalletDevice> devicesToReturn = [];
  bool shouldThrow = false;

  @override
  bool get isConnected => connectCalled && !disconnectCalled;

  @override
  Future<List<HardwareWalletDevice>> scanForDevices() async {
    scanCalled = true;
    if (shouldThrow) throw Exception('scan failed');
    return devicesToReturn;
  }

  @override
  Future<void> connectDevice(HardwareWalletDevice device) async {
    if (shouldThrow) throw Exception('connect failed');
    connectCalled = true;
  }

  @override
  Future<void> disconnect() async {
    if (shouldThrow) throw Exception('disconnect failed');
    disconnectCalled = true;
  }
}

void main() {
  group('hardwareSessionStateProvider', () {
    test('initial state is idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(hardwareSessionStateProvider),
        HardwareSessionState.idle,
      );
    });

    test('can transition through scan lifecycle states', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(hardwareSessionStateProvider),
        HardwareSessionState.idle,
      );

      container.read(hardwareSessionStateProvider.notifier).state =
          HardwareSessionState.scanning;
      expect(
        container.read(hardwareSessionStateProvider),
        HardwareSessionState.scanning,
      );

      container.read(hardwareSessionStateProvider.notifier).state =
          HardwareSessionState.deviceFound;
      expect(
        container.read(hardwareSessionStateProvider),
        HardwareSessionState.deviceFound,
      );

      container.read(hardwareSessionStateProvider.notifier).state =
          HardwareSessionState.connecting;
      expect(
        container.read(hardwareSessionStateProvider),
        HardwareSessionState.connecting,
      );

      container.read(hardwareSessionStateProvider.notifier).state =
          HardwareSessionState.connected;
      expect(
        container.read(hardwareSessionStateProvider),
        HardwareSessionState.connected,
      );
    });

    test('can set timeout state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(hardwareSessionStateProvider.notifier).state =
          HardwareSessionState.scanning;
      container.read(hardwareSessionStateProvider.notifier).state =
          HardwareSessionState.timeout;

      expect(
        container.read(hardwareSessionStateProvider),
        HardwareSessionState.timeout,
      );
    });

    test('can set error state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(hardwareSessionStateProvider.notifier).state =
          HardwareSessionState.error;

      expect(
        container.read(hardwareSessionStateProvider),
        HardwareSessionState.error,
      );
    });
  });

  group('hardwareDevicesProvider', () {
    test('initial state is empty list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(hardwareDevicesProvider), isEmpty);
    });

    test('can update device list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final device = _TestDevice(
        name: 'Nano S',
        family: HardwareWalletDeviceFamily.ledger,
        connectionType: HardwareWalletConnectionType.usb,
        model: 'Nano S',
      );

      container.read(hardwareDevicesProvider.notifier).state = [device];

      final devices = container.read(hardwareDevicesProvider);
      expect(devices.length, 1);
      expect(devices.first.name, 'Nano S');
    });
  });

  group('selectedHardwareFamilyProvider', () {
    test('initial state is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedHardwareFamilyProvider), isNull);
    });

    test('can select family', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedHardwareFamilyProvider.notifier).state =
          HardwareWalletDeviceFamily.ledger;

      expect(
        container.read(selectedHardwareFamilyProvider),
        HardwareWalletDeviceFamily.ledger,
      );
    });
  });

  group('selectedHardwareDeviceProvider', () {
    test('initial state is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedHardwareDeviceProvider), isNull);
    });

    test('can select device', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final device = _TestDevice(
        name: 'Nano X',
        family: HardwareWalletDeviceFamily.ledger,
        connectionType: HardwareWalletConnectionType.usb,
        model: 'Nano X',
      );

      container.read(selectedHardwareDeviceProvider.notifier).state = device;

      expect(
        container.read(selectedHardwareDeviceProvider)?.name,
        'Nano X',
      );
    });
  });

  group('hardwareAdapterProvider', () {
    test('returns non-null adapter for ledger', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final adapter = container.read(
        hardwareAdapterProvider(HardwareWalletDeviceFamily.ledger),
      );

      expect(adapter, isNotNull);
    });

    test('returns TrezorAdapterStub for trezor', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final adapter = container.read(
        hardwareAdapterProvider(HardwareWalletDeviceFamily.trezor),
      );

      expect(adapter, isNotNull);
    });

    test('returns null for foundation (not yet implemented)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final adapter = container.read(
        hardwareAdapterProvider(HardwareWalletDeviceFamily.foundation),
      );

      expect(adapter, isNull);
    });

    test('can be overridden with fake adapter', () {
      final fakeAdapter = _FakeAdapter();

      final container = ProviderContainer(
        overrides: [
          hardwareAdapterProvider(HardwareWalletDeviceFamily.ledger)
              .overrideWithValue(fakeAdapter),
        ],
      );
      addTearDown(container.dispose);

      final adapter = container.read(
        hardwareAdapterProvider(HardwareWalletDeviceFamily.ledger),
      );

      expect(adapter, same(fakeAdapter));
    });
  });
}
