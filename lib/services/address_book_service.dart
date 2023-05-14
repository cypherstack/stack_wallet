import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/contact.dart';
import 'package:stackwallet/models/contact_address_entry.dart';
import 'package:stackwallet/models/isar/models/contact_entry.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';

class AddressBookService extends ChangeNotifier {

  ContactEntry turnContactToEntry({required Contact contact}) {
    String? emojiChar = contact.emojiChar;
    String name = contact.name;
    List<String> addresses = [];
    bool isFavorite = contact.isFavorite;
    String customId = contact.id;
    for (ContactAddressEntry contactAddressEntry in contact.addresses) {
      String coin = contactAddressEntry.coin.ticker;
      String address = contactAddressEntry.address;
      String label = contactAddressEntry.label;
      String? other = contactAddressEntry.other;
      addresses.add("$coin,$address,$label,$other");
    }
    return ContactEntry(
      emojiChar: emojiChar,
      name: name,
      addresses: addresses,
      isFavorite: isFavorite,
      customId: customId,
    );
  }

  Contact turnEntryToContact({required ContactEntry contactEntry}) {
    String? emojiChar = contactEntry.emojiChar;
    String name = contactEntry.name;
    List<ContactAddressEntry> addresses = [];
    bool isFavorite = contactEntry.isFavorite;
    String id = contactEntry.customId;
    for (String addressEntry in contactEntry.addresses) {
      List<String> addressEntrySplit = addressEntry.split(",");
      Coin coin = coinFromTickerCaseInsensitive(addressEntrySplit[0]);
      String address = addressEntrySplit[1];
      String label = addressEntrySplit[2];
      String? other = addressEntrySplit[3];
      addresses.add(ContactAddressEntry(
        coin: coin,
        address: address,
        label: label,
        other: other,
      ));
    }
    return Contact(
      emojiChar: emojiChar,
      name: name,
      addresses: addresses,
      isFavorite: isFavorite,
      id: id,
    );
  }

  Contact getContactById(String id) {
    ContactEntry? contactEntry = MainDB.instance.getContactEntry(id: id);
    if (contactEntry == null) {
      return Contact(
        name: "Contact not found",
        addresses: [],
        isFavorite: false,
      );
    } else {
      return turnEntryToContact(contactEntry: contactEntry);
    }
  }

  List<Contact> get contacts {
    List<ContactEntry> contactEntries = MainDB.instance.getContactEntries();
    List<Contact> contactsList = [];
    for (ContactEntry contactEntry in contactEntries) {
      contactsList.add(turnEntryToContact(contactEntry: contactEntry));
    }
    return contactsList;
  }

  List<Contact>? _addressBookEntries;
  List<Contact> get addressBookEntries =>
      _addressBookEntries ??= _fetchAddressBookEntries();

  // Load address book contact entries
  List<Contact> _fetchAddressBookEntries() {
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
    if (term.isEmpty) {
      return true;
    }
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
    if (await MainDB.instance.isContactEntryExists(id: contact.id)) {
      return false;
    } else {
      await MainDB.instance.putContactEntry(contactEntry: turnContactToEntry(contact: contact));
      _refreshAddressBookEntries();
      return true;
    }
  }

  /// Edit contact
  Future<bool> editContact(Contact editedContact) async {
    // over write the contact with edited version
    await MainDB.instance.putContactEntry(contactEntry: turnContactToEntry(contact: editedContact));
    _refreshAddressBookEntries();
    return true;
  }

  /// Remove address book contact entry from db if it exists
  Future<void> removeContact(String id) async {
    await MainDB.instance.deleteContactEntry(id: id);
    _refreshAddressBookEntries();
  }

  void _refreshAddressBookEntries() {
    final newAddressBookEntries = _fetchAddressBookEntries();
    _addressBookEntries = newAddressBookEntries;
    notifyListeners();
  }
}
