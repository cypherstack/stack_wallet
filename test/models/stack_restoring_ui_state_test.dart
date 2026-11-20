import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/stack_restoring_ui_state.dart';
import 'package:stackwallet/models/wallet_restore_state.dart';
import 'package:stackwallet/utilities/enums/stack_restoring_status.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  test('backup restore exposes and clears per-wallet Zcash data progress', () {
    final state = StackRestoringUIState()
      ..walletStates = {
        'zcash-wallet': WalletRestoreState(
          walletId: 'zcash-wallet',
          walletName: 'Zcash',
          coin: Zcash(CryptoCurrencyNetwork.main),
          restoringStatus: StackRestoringStatus.restoring,
        ),
      };

    state.updateActivity(
      walletId: 'zcash-wallet',
      label: 'Downloading Zcash data',
      progress: 0.25,
    );

    final wallet = state.getWalletRestoreState('zcash-wallet');
    expect(wallet.activityLabel, 'Downloading Zcash data');
    expect(wallet.activityProgress, 0.25);

    state.clearActivity(walletId: 'zcash-wallet');
    expect(wallet.activityLabel, isNull);
    expect(wallet.activityProgress, isNull);
  });
}
