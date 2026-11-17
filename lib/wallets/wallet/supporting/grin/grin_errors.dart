import 'package:grin_native/grin_native.dart';

import '../../../../exceptions/sw_exception.dart';
import '../../../../exceptions/wallet/insufficient_balance_exception.dart';

/// A Grin failure that is safe to show and log.
///
/// It carries the library's error type, code and slate id, never the
/// library's message: that text can come from a node or a counterparty.
class GrinWalletException extends SWException {
  GrinWalletException(
    super.message, {
    this.type,
    this.code,
    this.slateId,
    this.finalized = false,
    this.released = false,
  });

  /// The library exception's class name, if a library error caused this.
  final String? type;

  /// The library's error code, if a library error caused this.
  final int? code;

  /// The slate the failed call was working on, if the library said.
  final String? slateId;

  /// The library finalized and stored the transaction before the call
  /// failed.
  final bool finalized;

  /// The library cancelled the transaction again before the call returned:
  /// nothing is locked and nothing was sent.
  final bool released;

  /// A finalized transaction whose broadcast failed. Offer repost.
  bool get finalizedNotBroadcast => finalized && slateId != null;

  /// The call failed and left a transaction in the wallet that is neither
  /// finalized nor cancelled. Its inputs may be locked.
  bool get leftPendingTransaction => slateId != null && !finalized && !released;
}

/// Shown for a call that failed after the transaction was finalized.
const grinFinalizedNotBroadcastMessage =
    "The transaction was finalized but the node did not accept it. "
    "You can try to repost it.";

/// Shown for a send the library cancelled again after it failed.
const grinReleasedMessage =
    "The transaction could not be completed. Nothing was sent and no funds "
    "are locked.";

/// Added to the message of a call that failed and left a transaction behind.
const grinLeftPendingNote =
    "The transaction is still in this wallet and may hold funds locked. "
    "Open it in the transaction history to cancel it.";

/// The library class and code of [error] for logs, and nothing else.
String describeGrinError(Object error) => switch (error) {
  GrinException() => "${error.runtimeType}(${error.code})",
  GrinWalletException() =>
    "GrinWalletException(${error.type ?? "local"}, ${error.code})",
  _ => "${error.runtimeType}",
};

/// [error] as an exception that can be shown and logged.
///
/// Library errors become [GrinWalletException] or
/// [InsufficientBalanceException] with fixed text. Other errors keep only
/// their type.
Exception sanitizeGrinError(Object error) {
  if (error is GrinWalletException || error is InsufficientBalanceException) {
    return error as Exception;
  }
  if (error is SWException) return error;
  if (error is! GrinException) {
    return GrinWalletException("Grin wallet error (${error.runtimeType})");
  }

  final base = switch (error) {
    GrinInvalidArgumentException() => "The Grin library refused an argument.",
    GrinInvalidUtf8Exception() => "The Grin library refused an argument.",
    GrinJsonException() => "The Grin library refused an argument.",
    GrinWalletNotFoundException() => "The Grin wallet files were not found.",
    GrinInvalidPasswordException() =>
      "The Grin wallet files did not open with the stored password.",
    GrinWalletExistsException() => "A Grin wallet already exists here.",
    GrinInvalidHandleException() => "The Grin wallet is closed.",
    GrinLifecycleException() => "The Grin wallet could not be opened.",
    GrinNodeException() => "Could not reach the Grin node.",
    GrinInsufficientFundsException() => "Insufficient balance.",
    GrinSlateException() =>
      "The Slatepack could not be read, or is not the one expected.",
    GrinTransactionException() => "The transaction failed checks.",
    GrinNotFoundException() => "No matching transaction in this wallet.",
    GrinCancelledException() => "The scan was cancelled.",
    GrinIoException() => "The Grin wallet files could not be read or written.",
    GrinInternalPanicException() => "The Grin library failed internally.",
    GrinInternalException() => "The Grin library failed internally.",
    GrinWalletBusyException() => "The Grin wallet is busy. Try again later.",
    GrinHttpException() =>
      "Could not complete the exchange with the recipient's wallet. "
          "Nothing was sent or locked.",
    GrinNotSupportedException() => "Not supported by this Grin library.",
    GrinInvalidAddressException() => "Invalid Grin address.",
    GrinInvalidMnemonicException() => "Invalid recovery phrase.",
    GrinUnknownException() => "Grin wallet error.",
  };
  final slateId = error.slateId;
  final String message;
  if (slateId == null) {
    message = base;
  } else if (error.finalized) {
    message = grinFinalizedNotBroadcastMessage;
  } else if (error.released) {
    message = grinReleasedMessage;
  } else {
    message = "$base $grinLeftPendingNote";
  }

  if (error is GrinInsufficientFundsException) {
    return InsufficientBalanceException(message);
  }

  return GrinWalletException(
    message,
    type: "${error.runtimeType}",
    code: error.code,
    slateId: slateId,
    finalized: slateId != null && error.finalized,
    released: slateId != null && error.released,
  );
}
