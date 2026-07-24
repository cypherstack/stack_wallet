import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'mwc_ffi_test_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('MWC FFI smoke', (tester) async {
    await FFITestService.initialize();
    final ok = await FFITestService.runAllTests();
    expect(
      ok,
      isTrue,
      reason: FFITestService.testResults
          .where((r) => !r.passed)
          .map((r) => '${r.name}: ${r.error}')
          .join('\n'),
    );
  });
}
