import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/models/contact.dart';
import 'package:stackwallet/models/contact_address_entry.dart';
import 'package:stackwallet/services/address_book_service.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

void main() {
  group("Empty DB tests", () {
    setUp(() async {
      await setUpTestHive();
      await Hive.openBox<dynamic>(DB.boxNameAddressBook);
    });

    test("get empty contacts", () {
      final service = AddressBookService();
      expect(service.contacts, <Contact>[]);
    });

    test("get empty addressBookEntries", () async {
      final service = AddressBookService();
      expect(await service.addressBookEntries, <Contact>[]);
    });

    test("getContactById from empty db", () {
      final service = AddressBookService();
      expect(() => service.getContactById("some id"), throwsException);
    });

    tearDown(() async {
      await tearDownTestHive();
    });
  });

  group("Preloaded DB tests", () {
    final contactA = Contact(name: "john", addresses: [], isFavorite: true);
    final contactB = Contact(
        name: "JANE",
        addresses: [
          const ContactAddressEntry(
            coin: Coin.bitcoin,
            address: "some btc address",
            label: "rent",
          ),
        ],
        isFavorite: false);
    final contactC = Contact(
        name: "Bill",
        addresses: [
          const ContactAddressEntry(
            coin: Coin.monero,
            address: "some xmr address",
            label: "market",
          ),
          const ContactAddressEntry(
            coin: Coin.epicCash,
            address: "some epic address",
            label: "gas",
          ),
        ],
        isFavorite: true);

    setUp(() async {
      await setUpTestHive();
      await Hive.openBox<dynamic>(DB.boxNameAddressBook);

      await DB.instance.put<dynamic>(
          boxName: DB.boxNameAddressBook,
          key: contactA.id,
          value: contactA.toMap());
      await DB.instance.put<dynamic>(
          boxName: DB.boxNameAddressBook,
          key: contactB.id,
          value: contactB.toMap());
      await DB.instance.put<dynamic>(
          boxName: DB.boxNameAddressBook,
          key: contactC.id,
          value: contactC.toMap());
    });

    test("getContactById with non existing ID", () {
      final service = AddressBookService();
      expect(() => service.getContactById("some id"), throwsException);
    });

    test("getContactById with existing ID", () {
      final service = AddressBookService();
      expect(
          service.getContactById(contactA.id).toString(), contactA.toString());
    });

    test("get contacts", () {
      final service = AddressBookService();
      expect(service.contacts.toString(),
          [contactA, contactB, contactC].toString());
    });

    test("get addressBookEntries", () async {
      final service = AddressBookService();
      expect((await service.addressBookEntries).toString(),
          [contactA, contactB, contactC].toString());
    });

    test("search contacts", () async {
      final service = AddressBookService();
      final results = await service.search("j");
      expect(results.toString(), [contactA, contactB].toString());

      final results2 = await service.search("ja");
      expect(results2.toString(), [contactB].toString());

      final results3 = await service.search("john");
      expect(results3.toString(), [contactA].toString());

      final results4 = await service.search("po");
      expect(results4.toString(), <Contact>[].toString());

      final results5 = await service.search("");
      expect(results5.toString(), [contactA, contactB, contactC].toString());

      final results6 = await service.search("epic address");
      expect(results6.toString(), [contactC].toString());
    });

    test("add new contact", () async {
      final service = AddressBookService();
      final contactD = Contact(name: "tim", addresses: [], isFavorite: true);
      final result = await service.addContact(contactD);
      expect(result, true);
      expect(service.contacts.length, 4);
      expect(
          service.getContactById(contactD.id).toString(), contactD.toString());
    });

    test("add duplicate contact", () async {
      final service = AddressBookService();
      final result = await service.addContact(contactA);
      expect(result, false);
      expect(service.contacts.length, 3);
      expect(service.contacts.toString(),
          [contactA, contactB, contactC].toString());
    });

    test("edit contact", () async {
      final service = AddressBookService();
      final editedContact = contactB.copyWith(name: "Mike");
      expect(await service.editContact(editedContact), true);
      expect(service.contacts.length, 3);
      expect(service.contacts.toString(),
          [contactA, editedContact, contactC].toString());
    });

    test("remove existing contact", () async {
      final service = AddressBookService();
      await service.removeContact(contactB.id);
      expect(service.contacts.length, 2);
      expect(service.contacts.toString(), [contactA, contactC].toString());
    });

    test("remove non existing contact", () async {
      final service = AddressBookService();
      await service.removeContact("some id");
      expect(service.contacts.length, 3);
      expect(service.contacts.toString(),
          [contactA, contactB, contactC].toString());
    });

    tearDown(() async {
      await tearDownTestHive();
    });
  });
}
