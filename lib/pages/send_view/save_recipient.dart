import 'package:uuid/uuid.dart';

import '../../models/isar/models/contact_entry.dart';
import '../../wallets/models/tx_data.dart';

enum SaveRecipientResult { saved, alreadySaved, failed }

typedef SaveRecipientOutcome = ({
  SaveRecipientResult result,
  Object? error,
  StackTrace? stackTrace,
});

/// Confirm screen state behind the optional "save recipient to contacts" step.
///
/// The address book records who was paid, so saving is opt-in: [enabled] starts
/// off and [addressToSave] stays null until the user turns it on.
class SaveRecipientOption {
  SaveRecipientOption({required this.address});

  /// The address this send may offer to save, or null if it may not offer one.
  final String? address;

  bool enabled = false;

  bool get isOffered => address != null;

  /// The address to persist once the send succeeds, or null if none should be.
  String? get addressToSave => enabled ? address : null;
}

/// The address a send may offer to save, or null when it may not offer one.
///
/// A savable send has exactly one distinct non change recipient: anything else
/// has no single address to name, or is not a payment to someone else at all.
/// The excluded flows all pay a single use address — a PayNym payment or
/// notification address, an exchange deposit address, the destination of a
/// transaction being fee bumped (already offered when it was first sent), or a
/// Salvium stake, whose "recipient" is the sending wallet itself. Saving those
/// invites address reuse later.
String? savableRecipientAddress({
  required TxData txData,
  required bool isTradeTransaction,
  required bool isPaynymTransaction,
  required bool isPaynymNotificationTransaction,
  required bool isRbfTransaction,
}) {
  if (isTradeTransaction ||
      isPaynymTransaction ||
      isPaynymNotificationTransaction ||
      isRbfTransaction ||
      txData.salviumStakeTx) {
    return null;
  }

  final addresses = <String>{
    ...?txData.recipients
        ?.where((recipient) => !recipient.isChange)
        .map((recipient) => recipient.address.trim())
        .where((address) => address.isNotEmpty),
    ...?txData.sparkRecipients
        ?.where((recipient) => !recipient.isChange)
        .map((recipient) => recipient.address.trim())
        .where((address) => address.isNotEmpty),
  };

  return addresses.length == 1 ? addresses.single : null;
}

/// Adds [address] to the address book unless it is already there.
///
/// Runs after the transaction is on its way, so it reports failures instead of
/// throwing them at a caller that can no longer undo the send.
Future<SaveRecipientOutcome> saveRecipient({
  required String address,
  required String coinIdentifier,
  required String name,
  required List<ContactEntry> existingContacts,
  required Future<bool> Function(ContactEntry contact) addContact,
}) async {
  try {
    final alreadySaved = existingContacts.any(
      (contact) => contact.addresses.any(
        (entry) => entry.address == address && entry.coinName == coinIdentifier,
      ),
    );
    if (alreadySaved) {
      return (
        result: SaveRecipientResult.alreadySaved,
        error: null,
        stackTrace: null,
      );
    }

    final entry = ContactAddressEntry()
      ..coinName = coinIdentifier
      ..address = address
      ..label = 'Sent to'
      ..other = null;
    final contact = ContactEntry(
      name: name.trim().isEmpty ? 'Saved recipient' : name.trim(),
      addresses: [entry],
      isFavorite: false,
      customId: const Uuid().v1(),
    );

    final saved = await addContact(contact);
    return (
      result: saved ? SaveRecipientResult.saved : SaveRecipientResult.failed,
      error: null,
      stackTrace: null,
    );
  } catch (error, stackTrace) {
    return (
      result: SaveRecipientResult.failed,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
