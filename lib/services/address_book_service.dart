import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:epicmobile/hive/db.dart';
import 'package:epicmobile/models/contact.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/logger.dart';

class AddressBookService extends ChangeNotifier {
  Contact getContactById(String id) {
    final json = DB.instance
        .get<dynamic>(boxName: DB.boxNameAddressBook, key: id) as Map?;
    if (json == null) {
      Logging.instance
          .log("Attempted to get non existing contact", level: LogLevel.Fatal);
      throw Exception('Contact ID "$id" not found!');
    }
    return Contact.fromJson(Map<String, dynamic>.from(json));
  }

  List<Contact> get contacts {
    final keys = List<String>.from(
        DB.instance.keys<dynamic>(boxName: DB.boxNameAddressBook));
    final _contacts = keys
        .map((id) => Contact.fromJson(Map<String, dynamic>.from(DB.instance
            .get<dynamic>(boxName: DB.boxNameAddressBook, key: id) as Map)))
        .toList(growable: false);
    _contacts
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return _contacts;
  }

  Future<List<Contact>>? _addressBookEntries;
  Future<List<Contact>> get addressBookEntries =>
      _addressBookEntries ??= _fetchAddressBookEntries();

  // Load address book contact entries
  Future<List<Contact>> _fetchAddressBookEntries() async {
    return contacts;
  }

  /// search address book entries
  //TODO optimize address book search?
  Future<List<Contact>> search(String text) async {
    if (text.isEmpty) return addressBookEntries;
    var results = (await addressBookEntries).toList();

    results.retainWhere((contact) => matches(text, contact));

    return results;
  }

  bool matches(String term, Contact contact) {
    final text = term.toLowerCase();
    if (contact.name.toLowerCase().contains(text)) {
      return true;
    }
    for (int i = 0; i < contact.addresses.length; i++) {
      if (contact.addresses[i].label.toLowerCase().contains(text) ||
          contact.addresses[i].coin.name.toLowerCase().contains(text) ||
          contact.addresses[i].coin.prettyName.toLowerCase().contains(text) ||
          contact.addresses[i].coin.ticker.toLowerCase().contains(text) ||
          contact.addresses[i].address.toLowerCase().contains(text)) {
        return true;
      }
    }
    return false;
  }

  /// add contact
  ///
  /// returns false if it provided [contact]'s id already exists in the database
  /// other true if the [contact] was saved
  Future<bool> addContact(Contact contact) async {
    if (DB.instance.containsKey<dynamic>(
        boxName: DB.boxNameAddressBook, key: contact.id)) {
      return false;
    }

    await DB.instance.put<dynamic>(
        boxName: DB.boxNameAddressBook,
        key: contact.id,
        value: contact.toMap());

    Logging.instance.log("add address book entry saved", level: LogLevel.Info);
    await _refreshAddressBookEntries();
    return true;
  }

  /// Edit contact
  Future<bool> editContact(Contact editedContact) async {
    // over write the contact with edited version
    await DB.instance.put<dynamic>(
        boxName: DB.boxNameAddressBook,
        key: editedContact.id,
        value: editedContact.toMap());

    Logging.instance.log("edit address book entry saved", level: LogLevel.Info);
    await _refreshAddressBookEntries();
    return true;
  }

  /// Remove address book contact entry from db if it exists
  Future<void> removeContact(String id) async {
    await DB.instance.delete<dynamic>(key: id, boxName: DB.boxNameAddressBook);
    await _refreshAddressBookEntries();
  }

  Future<void> _refreshAddressBookEntries() async {
    final newAddressBookEntries = await _fetchAddressBookEntries();
    _addressBookEntries = Future(() => newAddressBookEntries);
    notifyListeners();
  }
}
