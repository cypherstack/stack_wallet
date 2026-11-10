import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/native_library_check.dart';
import 'package:stackwallet/widgets/onetime_popups/native_library_warning_dialog.dart';

const _monero = (
  displayName: "Monero wallets",
  result: (
    problem: NativeLibraryProblem.missing,
    path: r"C:\Program Files\Stack Wallet\monero_libwallet2_api_c.dll",
    error: "The specified module could not be found.\n (error code: 126)",
  ),
);

const _secp = (
  displayName: "Most wallets",
  result: (
    problem: NativeLibraryProblem.blockedByAntivirus,
    path: r"C:\Program Files\Stack Wallet\secp256k1.dll",
    error:
        "the file contains a virus or potentially unwanted software.\n "
        "(error code: 225)",
  ),
);

void main() {
  test("one failure", () {
    expect(
      nativeLibraryWarningTitle([_monero]),
      "A required file could not be loaded",
    );
    final message = nativeLibraryWarningMessage([_monero]);
    expect(
      message,
      nativeLibraryErrorMessage("Monero wallets", _monero.result),
    );
    expect(
      message,
      startsWith(
        "Monero wallets can't be used because a required file is missing.",
      ),
    );
    expect(message, endsWith("(error code: 126)"));
  });

  test("several failures", () {
    expect(
      nativeLibraryWarningTitle([_monero, _secp]),
      "Some required files could not be loaded",
    );
    final message = nativeLibraryWarningMessage([_monero, _secp]);
    expect(
      message,
      "${nativeLibraryErrorMessage("Monero wallets", _monero.result)}\n\n"
      "${nativeLibraryErrorMessage("Most wallets", _secp.result)}",
    );
    expect(
      message,
      contains("Most wallets can't be used because antivirus software blocked"),
    );
    expect(
      message.indexOf("Monero"),
      lessThan(message.indexOf("Most wallets")),
    );
  });
}
