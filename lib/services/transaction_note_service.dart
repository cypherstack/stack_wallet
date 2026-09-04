/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 */

import '../models/isar/models/transaction_note.dart';
import '../utilities/logger.dart';

Future<bool> saveTransactionNotesAfterSend({
  required List<TransactionNote> notes,
  required Future<void> Function(List<TransactionNote>) persist,
}) async {
  try {
    await persist(notes);
    return true;
  } catch (e, s) {
    Logging.instance.w(
      "Transaction sent, but its note could not be saved",
      error: e,
      stackTrace: s,
    );
    return false;
  }
}
