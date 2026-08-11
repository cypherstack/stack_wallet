import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wl_gen/interfaces/cs_salvium_interface.dart';

import 'salvium_test.mocks.dart';

@GenerateNiceMocks([MockSpec<CsSalviumInterface>()])
void main() {
  const address = "valid Salvium address";

  late MockCsSalviumInterface salviumInterface;
  late Salvium currency;

  setUp(() {
    salviumInterface = MockCsSalviumInterface();
    currency = Salvium(
      CryptoCurrencyNetwork.main,
      salviumInterface: salviumInterface,
    );
  });

  test("accepts a valid address without a payment ID", () {
    when(salviumInterface.validateAddress(address, 0)).thenReturn(true);
    when(salviumInterface.paymentIdFromAddress(address, 0)).thenReturn("");

    expect(currency.validateAddress(address), isTrue);
  });

  test("rejects an integrated address", () {
    when(salviumInterface.validateAddress(address, 0)).thenReturn(true);
    when(
      salviumInterface.paymentIdFromAddress(address, 0),
    ).thenReturn("0123456789abcdef");

    expect(currency.validateAddress(address), isFalse);
    expect(currency.isIntegratedAddress(address), isTrue);
  });

  test("does not parse a payment ID from an invalid address", () {
    when(salviumInterface.validateAddress(address, 0)).thenReturn(false);

    expect(currency.validateAddress(address), isFalse);
    verifyNever(salviumInterface.paymentIdFromAddress(address, 0));
  });
}
