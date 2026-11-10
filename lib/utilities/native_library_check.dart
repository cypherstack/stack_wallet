import 'dart:ffi';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../app_config.dart';
import '../wallets/crypto_currency/crypto_currency.dart';
import 'logger.dart';

enum NativeLibraryProblem { missing, blockedByAntivirus, loadFailed }

typedef NativeLibraryCheckResult = ({
  NativeLibraryProblem problem,
  String path,
  String error,
});

/// One library that failed the startup check.
typedef NativeLibraryFailure = ({
  String displayName,
  NativeLibraryCheckResult result,
});

/// A native library the desktop builds bundle and open through dart:ffi.
class NativeLibrary {
  const NativeLibrary({
    required this.displayName,
    required this.windows,
    required this.linux,
    required this.macos,
    this.isBundled = _always,
  });

  /// What stops working without it, worded to start a sentence: "Monero
  /// wallets".
  final String displayName;

  /// The name each loader passes to DynamicLibrary.open on that platform.
  final String windows;
  final String linux;
  final String macos;

  /// Whether this build ships the library. Whitelabel builds leave coins out,
  /// and their libraries with them.
  final bool Function() isBundled;

  String? fileName(String os) => switch (os) {
    "windows" => windows,
    "linux" => linux,
    "macos" => macos,
    _ => null,
  };
}

bool _always() => true;
bool _hasMonero() => AppConfig.coins.whereType<Monero>().isNotEmpty;
bool _hasWownero() => AppConfig.coins.whereType<Wownero>().isNotEmpty;
bool _hasSalvium() => AppConfig.coins.whereType<Salvium>().isNotEmpty;

/// coinlib's secp256k1, named as in its secp256k1_io.dart. Every non
/// cryptonote wallet needs it.
const secp256k1NativeLibrary = NativeLibrary(
  displayName: "Most wallets",
  windows: "secp256k1.dll",
  linux: "libsecp256k1.so",
  macos: "secp256k1.framework/secp256k1",
);

/// Checked at startup in this order. The cryptonote names are the ones
/// cs_monero, cs_wownero and cs_salvium pass to DynamicLibrary.open; their
/// getters are private, so a rename there has to be mirrored here.
const nativeLibraries = [
  NativeLibrary(
    displayName: "Monero wallets",
    windows: "monero_libwallet2_api_c.dll",
    linux: "monero_libwallet2_api_c.so",
    macos: "MoneroWallet.framework/MoneroWallet",
    isBundled: _hasMonero,
  ),
  NativeLibrary(
    displayName: "Wownero wallets",
    windows: "wownero_libwallet2_api_c.dll",
    linux: "wownero_libwallet2_api_c.so",
    macos: "WowneroWallet.framework/WowneroWallet",
    isBundled: _hasWownero,
  ),
  NativeLibrary(
    displayName: "Salvium wallets",
    windows: "salvium_libwallet2_api_c.dll",
    linux: "salvium_libwallet2_api_c.so",
    macos: "SalviumWallet.framework/SalviumWallet",
    isBundled: _hasSalvium,
  ),
  secp256k1NativeLibrary,
];

/// Where the app bundles [fileName] on [os], given the running executable.
String nativeLibraryPath(String fileName, String os, String executable) {
  final path = os == "windows" ? p.windows : p.posix;
  final dir = path.dirname(executable);
  return switch (os) {
    "linux" => path.join(dir, "lib", fileName),
    "macos" => path.normalize(path.join(dir, "..", "Frameworks", fileName)),
    _ => path.join(dir, fileName),
  };
}

/// Loads [fileName] and returns null, or why it failed to load.
NativeLibraryCheckResult? checkNativeLibrary(
  String fileName, {
  required String os,
  required String executable,
  void Function(String) open = _open,
  bool Function(String) exists = _exists,
}) {
  try {
    open(fileName);
    return null;
  } catch (e) {
    final error = e is ArgumentError ? "${e.message}" : "$e";
    final path = nativeLibraryPath(fileName, os, executable);
    final NativeLibraryProblem problem;
    if (!exists(path)) {
      problem = NativeLibraryProblem.missing;
    } else if (RegExp(r"error code: 22[56]\b").hasMatch(error)) {
      // ERROR_VIRUS_INFECTED or ERROR_VIRUS_DELETED
      problem = NativeLibraryProblem.blockedByAntivirus;
    } else {
      problem = NativeLibraryProblem.loadFailed;
    }
    return (problem: problem, path: path, error: error);
  }
}

void _open(String name) => DynamicLibrary.open(name);
bool _exists(String path) => File(path).existsSync();

String nativeLibraryErrorMessage(
  String displayName,
  NativeLibraryCheckResult result,
) {
  const app = AppConfig.appName;
  final reason = switch (result.problem) {
    NativeLibraryProblem.missing =>
      "a required file is missing. Antivirus software may have quarantined "
          "it. Restore it from quarantine or reinstall $app, then try again.",
    NativeLibraryProblem.blockedByAntivirus =>
      "antivirus software blocked a required file. Allow it in your "
          "antivirus settings or restore it from quarantine, then try again.",
    NativeLibraryProblem.loadFailed =>
      "a required library failed to load. Reinstalling $app may fix this.",
  };
  return "$displayName can't be used because $reason\n\n"
      "File: ${result.path}\nError: ${result.error}";
}

bool _isDesktop(String os) => os == "windows" || os == "linux" || os == "macos";

final _failures = <NativeLibraryFailure>[];
String? _coinlibError;

/// Starts coinlib's secp256k1 load for main().
///
/// coinlib throws synchronously when the file won't open, which would end
/// main() long before the home screen could say which file is broken. On
/// desktop the error is kept for [checkNativeLibrariesOnStartup] to report
/// and the app carries on; wallets that need coinlib fail their own init.
/// On mobile the library can't go missing on its own, so the error
/// propagates as it always has. Logging isn't initialised yet, so the check
/// is what logs it.
Future<void> loadCoinlibOrRecordFailure(Future<void> Function() load) async {
  try {
    await load();
  } catch (e) {
    if (!_isDesktop(Platform.operatingSystem)) rethrow;
    _coinlibError = "$e";
  }
}

/// Tries to open every bundled library in [nativeLibraries], in order, and
/// remembers the ones that fail for the home screen to report once.
///
/// Desktop only; elsewhere it does nothing. It runs on the main isolate
/// before any wallet loads, so it competes with nothing a user is waiting
/// on, and a wallet's later open of the same file is a cache hit. Never
/// throws: a broken check is logged and counts as a pass, because the check
/// must not be the thing that keeps the app from starting.
void checkNativeLibrariesOnStartup({
  List<NativeLibrary> libraries = nativeLibraries,
  String? os,
  String? executable,
  void Function(String) open = _open,
  bool Function(String) exists = _exists,
}) {
  final coinlibError = _coinlibError;
  _coinlibError = null;
  try {
    os ??= Platform.operatingSystem;
    if (!_isDesktop(os)) return;
    executable ??= Platform.resolvedExecutable;
  } catch (e, s) {
    Logging.instance.w(
      "Native library check did not run",
      error: e,
      stackTrace: s,
    );
    return;
  }

  for (final library in libraries) {
    final fileName = library.fileName(os);
    if (fileName == null) continue;
    final isSecp256k1 = identical(library, secp256k1NativeLibrary);
    NativeLibraryCheckResult? result;
    try {
      if (!library.isBundled()) continue;
      result = checkNativeLibrary(
        fileName,
        os: os,
        executable: executable,
        open: open,
        exists: exists,
      );
      if (result == null && isSecp256k1 && coinlibError != null) {
        // The file opens but coinlib still failed, so report what it said.
        result = (
          problem: NativeLibraryProblem.loadFailed,
          path: nativeLibraryPath(fileName, os, executable),
          error: coinlibError,
        );
      }
    } catch (e, s) {
      // One entry's trouble must not hide the others. coinlib's own error
      // is still worth reporting even if the check of its file blew up.
      Logging.instance.w(
        "Native library check for ${library.displayName} did not run",
        error: e,
        stackTrace: s,
      );
      if (isSecp256k1 && coinlibError != null) {
        result = (
          problem: NativeLibraryProblem.loadFailed,
          path: fileName,
          error: coinlibError,
        );
      }
    }
    if (result != null) {
      _failures.add((displayName: library.displayName, result: result));
      Logging.instance.e(
        nativeLibraryErrorMessage(library.displayName, result),
      );
    }
  }
}

/// The failures the startup check found, cleared so the warning shows once
/// per launch.
List<NativeLibraryFailure> takeNativeLibraryFailures() {
  final failures = List<NativeLibraryFailure>.unmodifiable(_failures);
  _failures.clear();
  return failures;
}
