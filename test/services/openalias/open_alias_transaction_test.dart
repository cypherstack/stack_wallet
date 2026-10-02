import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/openalias/open_alias.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/amount/amount.dart';

void main() {
  test('fee updates preserve the alias; recipient changes invalidate it', () {
    const alias = OpenAliasRecipient(
      domain: 'alice.example',
      address: 'accepted',
    );
    final recipient = TxRecipient(
      address: 'accepted',
      amount: Amount(rawValue: BigInt.one, fractionDigits: 12),
      isChange: false,
      addressType: AddressType.cryptonote,
    );
    final prepared = TxData(
      recipients: [recipient],
      openAliasRecipient: alias,
    ).copyWith(fee: Amount(rawValue: BigInt.two, fractionDigits: 12));
    expect(prepared.recipients!.single.address, 'accepted');
    expect(prepared.openAliasRecipient, same(alias));
    expect(
      prepared
          .copyWith(recipients: [recipient.copyWith(address: 'different')])
          .openAliasRecipient,
      isNull,
    );
    expect(
      prepared.copyWith(recipients: [recipient, recipient]).openAliasRecipient,
      isNull,
    );
  });
}
