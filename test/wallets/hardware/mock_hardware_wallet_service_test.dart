import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/hardware/hardware.dart';
import 'package:stackwallet/wallets/hardware/mock_hardware_wallet_service.dart';

void main() {
  late StateController<HardwareSessionState> stateController;
  late TrezorHardwareWalletDevice testDevice;

  setUp(() {
    final container = ProviderContainer();
    final provider =
        StateProvider<HardwareSessionState>((ref) => HardwareSessionState.idle);
    stateController = container.read(provider.notifier);

    testDevice = TrezorHardwareWalletDevice(
      name: 'Test Trezor',
      connectionType: HardwareWalletConnectionType.usb,
      model: 'Model T',
    );
  });

  group('MockHardwareWalletService', () {
    group('auto-approve path', () {
      test('transitions approvalPending -> connected and returns approved', () async {
        final service = MockHardwareWalletService(
          signingStateController: stateController,
          autoApprove: true,
        );

        final future = service.signTransaction(
          device: testDevice,
          payload: {'tx': 'test'},
        );

        expect(stateController.state, HardwareSessionState.approvalPending);

        final result = await future;

        expect(stateController.state, HardwareSessionState.connected);
        expect(result, {'approved': true});
      });
    });

    group('manual path', () {
      test('sets approvalPending and waits for external resolution', () async {
        final service = MockHardwareWalletService(
          signingStateController: stateController,
          autoApprove: false,
        );

        final future = service.signTransaction(
          device: testDevice,
          payload: {'tx': 'test'},
        );

        await Future.delayed(Duration.zero);
        expect(stateController.state, HardwareSessionState.approvalPending);

        service.simulateApproval();

        final result = await future;
        expect(stateController.state, HardwareSessionState.connected);
        expect(result, {'approved': true});
      });
    });

    group('simulateRejection', () {
      test('sets state to error and completes with rejection', () async {
        final service = MockHardwareWalletService(
          signingStateController: stateController,
          autoApprove: false,
        );

        final future = service.signTransaction(
          device: testDevice,
          payload: {'tx': 'test'},
        );

        await Future.delayed(Duration.zero);
        service.simulateRejection();

        final result = await future;
        expect(stateController.state, HardwareSessionState.error);
        expect(result['approved'], false);
        expect(result['error'], 'rejected');
      });
    });

    group('simulateDisconnect', () {
      test('sets state to disconnected and completes with disconnect error', () async {
        final service = MockHardwareWalletService(
          signingStateController: stateController,
          autoApprove: false,
        );

        final future = service.signTransaction(
          device: testDevice,
          payload: {'tx': 'test'},
        );

        await Future.delayed(Duration.zero);
        service.simulateDisconnect();

        final result = await future;
        expect(stateController.state, HardwareSessionState.disconnected);
        expect(result['approved'], false);
        expect(result['error'], 'disconnected');
      });
    });

    group('getAvailableAccounts', () {
      test('returns a mock account with the requested derivation path',
          () async {
        final service = MockHardwareWalletService(
          signingStateController: stateController,
          autoApprove: true,
        );

        final accounts = await service.getAvailableAccounts(
          device: testDevice,
          derivationPath: "m/84'/0'/0'",
        );

        expect(accounts, hasLength(1));
        expect(accounts.first.derivationPath, "m/84'/0'/0'");
        expect(accounts.first.masterFingerprint, isNotEmpty);
        expect(accounts.first.xpub, isNotEmpty);
      });
    });
  });
}
