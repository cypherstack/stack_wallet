import 'package:grin_native/grin_native.dart';

import '../../../../exceptions/sw_exception.dart';
import '../../../../exceptions/wallet/insufficient_balance_exception.dart';

/// A Grin failure that is safe to show and log.
///
/// It carries the library's error type, code and slate id, never the
/// library's message: that text can come from a node or a counterparty.
class GrinWalletException extends SWException {
  GrinWalletException(super.message, {this.type, this.code, this.slateId});

  /// The library exception's class name, if a library error caused this.
  final String? type;

  /// The library's error code, if a library error caused this.
  final int? code;

  /// The slate the failed call was working on, if the library said.
  final String? slateId;

  /// A finalized transaction whose broadcast failed. Offer repost.
  bool get finalizedNotBroadcast => code == 9 && slateId != null;
}

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

  final message = switch (error) {
    GrinInvalidArgumentException() => "The Grin library refused an argument.",
    GrinInvalidUtf8Exception() => "The Grin library refused an argument.",
    GrinJsonException() => "The Grin library refused an argument.",
    GrinWalletNotFoundException() => "The Grin wallet files were not found.",
    GrinInvalidPasswordException() =>
      "The Grin wallet files did not open with the stored password.",
    GrinWalletExistsException() => "A Grin wallet already exists here.",
    GrinInvalidHandleException() => "The Grin wallet is closed.",
    GrinLifecycleException() => "The Grin wallet could not be opened.",
    GrinNodeException() =>
      error.slateId != null
          ? "The transaction was finalized but the node did not accept it. "
                "You can try to repost it."
          : "Could not reach the Grin node.",
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

  if (error is GrinInsufficientFundsException) {
    return InsufficientBalanceException(message);
  }

  return GrinWalletException(
    message,
    type: "${error.runtimeType}",
    code: error.code,
    slateId: error.slateId,
  );
}
