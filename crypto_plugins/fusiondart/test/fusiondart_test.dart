import 'package:fusiondart/fusiondart.dart';
import 'package:test/test.dart';

void main() {
  test('create Fusion instance just to test compile time warnings/errors', () {
    // create instance just to test compile time warnings/errors
    final f = Fusion(FusionParams(
      serverHost: "",
      serverPort: 2,
      serverSsl: false,
      genesisHashHex: "AA",
      mode: FusionMode.normal,
      torForOvert: false,
    ));

    expect(f, isA<Fusion>());
  });
}
