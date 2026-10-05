import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/contact_entry.dart';
import 'package:stackwallet/pages/send_view/save_recipient.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';

void main() {
  group('savableRecipientAddress', () {
    test('returns one unique non-change recipient', () {
      final txData = TxData(
        recipients: [
          _recipient(' change ', isChange: true),
          _recipient(' recipient '),
        ],
        sparkRecipients: [
          (
            address: 'recipient',
            amount: Amount.zero,
            memo: '',
            isChange: false,
          ),
        ],
      );

      expect(_address(txData), 'recipient');
    });

    test('collapses several outputs paying the same address', () {
      expect(
        _address(
          TxData(
            recipients: [
              _recipient('recipient'),
              _recipient('recipient'),
              _recipient('change', isChange: true),
            ],
          ),
        ),
        'recipient',
      );
    });

    test('rejects empty and multiple-recipient transactions', () {
      expect(_address(TxData()), isNull);
      expect(_address(TxData(recipients: [])), isNull);
      expect(
        _address(TxData(recipients: [_recipient('one'), _recipient('two')])),
        isNull,
      );
      expect(
        _address(
          TxData(
            recipients: [_recipient('transparent')],
            sparkRecipients: [
              (
                address: 'spark',
                amount: Amount.zero,
                memo: '',
                isChange: false,
              ),
            ],
          ),
        ),
        isNull,
      );
    });

    test('rejects change-only and blank recipients', () {
      expect(
        _address(TxData(recipients: [_recipient('change', isChange: true)])),
        isNull,
      );
      expect(_address(TxData(recipients: [_recipient('   ')])), isNull);
    });

    test('rejects trade and PayNym flows', () {
      final txData = TxData(recipients: [_recipient('recipient')]);

      expect(_address(txData, isTrade: true), isNull);
      expect(_address(txData, isPaynym: true), isNull);
      expect(_address(txData, isPaynymNotification: true), isNull);
    });

    test('rejects fee bumps of an already sent transaction', () {
      expect(
        _address(TxData(recipients: [_recipient('recipient')]), isRbf: true),
        isNull,
      );
    });

    test('rejects a Salvium stake, whose recipient is the sending wallet', () {
      expect(
        _address(
          TxData(recipients: [_recipient('own address')], salviumStakeTx: true),
        ),
        isNull,
      );
    });
  });

  group('SaveRecipientOption', () {
    test('is off until the user opts in', () {
      final option = SaveRecipientOption(address: 'recipient');

      expect(option.isOffered, isTrue);
      expect(option.enabled, isFalse);
      expect(option.addressToSave, isNull);

      option.enabled = true;

      expect(option.addressToSave, 'recipient');
    });

    test('has nothing to offer or save for an ineligible transaction', () {
      final option = SaveRecipientOption(address: null);

      expect(option.isOffered, isFalse);
      expect(option.addressToSave, isNull);

      option.enabled = true;

      expect(option.addressToSave, isNull);
    });
  });

  group('saveRecipient', () {
    test('does not duplicate an address for the same coin', () async {
      var addCalls = 0;
      final outcome = await saveRecipient(
        address: 'address',
        coinIdentifier: 'bitcoin',
        name: 'Name',
        existingContacts: [_contact('bitcoin', 'address')],
        addContact: (_) async {
          addCalls++;
          return true;
        },
      );

      expect(outcome.result, SaveRecipientResult.alreadySaved);
      expect(addCalls, 0);
    });

    test('saves the same address again under a different coin', () async {
      ContactEntry? saved;
      final outcome = await saveRecipient(
        address: 'address',
        coinIdentifier: 'litecoin',
        name: 'Name',
        existingContacts: [_contact('bitcoin', 'address')],
        addContact: (contact) async {
          saved = contact;
          return true;
        },
      );

      expect(outcome.result, SaveRecipientResult.saved);
      expect(saved!.addresses.single.coinName, 'litecoin');
    });

    test('normalizes the fallback name and contact fields', () async {
      ContactEntry? saved;
      final outcome = await saveRecipient(
        address: 'address',
        coinIdentifier: 'bitcoin',
        name: '   ',
        existingContacts: const [],
        addContact: (contact) async {
          saved = contact;
          return true;
        },
      );

      expect(outcome.result, SaveRecipientResult.saved);
      expect(saved!.name, 'Saved recipient');
      expect(saved!.addresses.single.address, 'address');
      expect(saved!.addresses.single.coinName, 'bitcoin');
      expect(saved!.addresses.single.label, 'Sent to');
    });

    test('reports a rejected write as failed', () async {
      final outcome = await saveRecipient(
        address: 'address',
        coinIdentifier: 'bitcoin',
        name: 'Name',
        existingContacts: const [],
        addContact: (_) async => false,
      );

      expect(outcome.result, SaveRecipientResult.failed);
    });

    test('contains persistence failures after broadcast', () async {
      final async = await saveRecipient(
        address: 'address',
        coinIdentifier: 'bitcoin',
        name: 'Name',
        existingContacts: const [],
        addContact: (_) => Future<bool>.error(StateError('write failed')),
      );

      expect(async.result, SaveRecipientResult.failed);
      expect(async.error, isA<StateError>());

      final sync = await saveRecipient(
        address: 'address',
        coinIdentifier: 'bitcoin',
        name: 'Name',
        existingContacts: const [],
        addContact: (_) => throw StateError('write failed'),
      );

      expect(sync.result, SaveRecipientResult.failed);
      expect(sync.error, isA<StateError>());
    });
  });
}

String? _address(
  TxData txData, {
  bool isTrade = false,
  bool isPaynym = false,
  bool isPaynymNotification = false,
  bool isRbf = false,
}) => savableRecipientAddress(
  txData: txData,
  isTradeTransaction: isTrade,
  isPaynymTransaction: isPaynym,
  isPaynymNotificationTransaction: isPaynymNotification,
  isRbfTransaction: isRbf,
);

TxRecipient _recipient(String address, {bool isChange = false}) => TxRecipient(
  address: address,
  amount: Amount.zero,
  isChange: isChange,
  addressType: AddressType.unknown,
);

ContactEntry _contact(String coin, String address) {
  final entry = ContactAddressEntry()
    ..coinName = coin
    ..address = address
    ..label = 'label'
    ..other = null;
  return ContactEntry(
    name: 'name',
    addresses: [entry],
    isFavorite: false,
    customId: 'id',
  );
}
