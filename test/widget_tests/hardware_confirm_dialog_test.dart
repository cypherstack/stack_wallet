import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/hardware_confirm_dialog.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/wallets/hardware/hardware.dart';
import 'package:stackwallet/wallets/hardware/hardware_wallet_service.dart';

import '../sample_data/theme_json.dart';

class DelayedSigner implements HardwareWalletService {
  final completion = Completer<Map<String, dynamic>>();

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({
    required HardwareWalletDevice device,
    required String derivationPath,
  }) async => [];

  @override
  Future<Map<String, dynamic>> signTransaction({
    required HardwareWalletDevice device,
    required Map<String, dynamic> payload,
  }) => completion.future;
}

void main() {
  for (final fails in [false, true]) {
    testWidgets(
      'closing dialog while signing finishes safely (error: $fails)',
      (tester) async {
        final service = DelayedSigner();
        final theme = StackTheme.fromJson(json: lightThemeJsonMap);
        final device = TrezorHardwareWalletDevice(
          name: 'Test device',
          connectionType: HardwareWalletConnectionType.usb,
          model: 'Test',
        );
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData(
                extensions: [StackColors.fromStackColorTheme(theme)],
              ),
              home: HardwareConfirmDialog(
                walletId: 'test',
                service: service,
                device: device,
                payload: const {},
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpWidget(const SizedBox());
        if (fails) {
          service.completion.completeError(StateError('device rejected'));
        } else {
          service.completion.complete({'signedTransaction': '00'});
        }
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
