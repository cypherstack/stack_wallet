import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/wallet/supporting/restore_progress.dart';

void main() {
  test('restore progress waits for a chain height', () {
    expect(calculateRestoreProgress(scannedHeight: 25, chainHeight: 0), 0);
    expect(calculateRestoreProgress(scannedHeight: 25, chainHeight: 100), 0.25);
  });
}
