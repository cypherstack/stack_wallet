import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/native_library_check.dart';

const _exe = r"C:\Program Files\Stack Wallet\stack_wallet.exe";
const _dll = "monero_libwallet2_api_c.dll";
const _path = r"C:\Program Files\Stack Wallet\monero_libwallet2_api_c.dll";

// Messages from a tester's Windows log.
const _blocked =
    "Failed to load dynamic library '$_dll': Operation did not complete "
    "successfully because the file contains a virus or potentially unwanted "
    "software.\n (error code: 225)";
const _notFound =
    "Failed to load dynamic library '$_dll': The specified module could not "
    "be found.\n (error code: 126)";

final _monero = nativeLibraries[0];
final _salvium = nativeLibraries[2];

NativeLibraryCheckResult? _check(String? error, {required bool exists}) =>
    checkNativeLibrary(
      _dll,
      os: "windows",
      executable: _exe,
      open: (_) {
        if (error != null) throw ArgumentError(error);
      },
      exists: (path) {
        expect(path, _path);
        return exists;
      },
    );

/// Runs the startup check over the whole table on Windows with [failing]
/// files refusing to open, and returns what it recorded.
List<NativeLibraryFailure> _startup(
  Set<String> failing, {
  List<NativeLibrary> libraries = nativeLibraries,
}) {
  checkNativeLibrariesOnStartup(
    libraries: libraries,
    os: "windows",
    executable: _exe,
    open: (name) {
      if (failing.contains(name)) throw ArgumentError(_notFound);
    },
    exists: (path) => !failing.contains(path.split(r"\").last),
  );
  return takeNativeLibraryFailures();
}

void main() {
  late Directory logDir;

  setUpAll(() async {
    logDir = await Directory.systemTemp.createTemp("native_lib_check_test");
    await Logging.instance.initialize(logDir.path, level: Level.off);
  });

  tearDownAll(() => logDir.delete(recursive: true));

  tearDown(takeNativeLibraryFailures);

  test("file names", () {
    expect(_monero.fileName("windows"), _dll);
    expect(_salvium.fileName("linux"), "salvium_libwallet2_api_c.so");
    expect(
      nativeLibraries[1].fileName("macos"),
      "WowneroWallet.framework/WowneroWallet",
    );
    expect(_monero.fileName("android"), isNull);
    expect(secp256k1NativeLibrary.fileName("windows"), "secp256k1.dll");
    expect(secp256k1NativeLibrary.fileName("linux"), "libsecp256k1.so");
    expect(
      secp256k1NativeLibrary.fileName("macos"),
      "secp256k1.framework/secp256k1",
    );
    expect(nativeLibraries.last, same(secp256k1NativeLibrary));
  });

  test("bundle paths", () {
    expect(nativeLibraryPath(_dll, "windows", _exe), _path);
    expect(
      nativeLibraryPath("a.so", "linux", "/opt/sw/stack_wallet"),
      "/opt/sw/lib/a.so",
    );
    expect(
      nativeLibraryPath("M.framework/M", "macos", "/A/S.app/Contents/MacOS/S"),
      "/A/S.app/Contents/Frameworks/M.framework/M",
    );
    expect(
      nativeLibraryPath("libsecp256k1.so", "linux", "/opt/sw/stack_wallet"),
      "/opt/sw/lib/libsecp256k1.so",
    );
  });

  test("loads", () {
    expect(_check(null, exists: true), isNull);
  });

  test("quarantined away", () {
    expect(
      _check(_notFound, exists: false)!.problem,
      NativeLibraryProblem.missing,
    );
  });

  test("blocked by antivirus", () {
    expect(
      _check(_blocked, exists: true)!.problem,
      NativeLibraryProblem.blockedByAntivirus,
    );
  });

  test("other failure", () {
    final result = _check(_notFound, exists: true)!;
    expect(result.problem, NativeLibraryProblem.loadFailed);
    final message = nativeLibraryErrorMessage("Monero wallets", result);
    expect(message, startsWith("Monero wallets can't be used"));
    expect(message, contains(_path));
    expect(message, contains("error code: 126"));
  });

  group("startup check", () {
    test("records nothing when everything loads", () {
      expect(_startup({}), isEmpty);
    });

    test("records failures in table order", () {
      final failures = _startup({"secp256k1.dll", _dll});
      expect(failures.map((f) => f.displayName), [
        "Monero wallets",
        "Most wallets",
      ]);
      expect(failures.first.result.problem, NativeLibraryProblem.missing);
      expect(failures.first.result.path, _path);
    });

    test("failures are handed over once", () {
      _startup({_dll});
      expect(takeNativeLibraryFailures(), isEmpty);
    });

    test("skips libraries this build does not ship", () {
      final failures = _startup(
        {_dll},
        libraries: [
          NativeLibrary(
            displayName: "Monero wallets",
            windows: _dll,
            linux: "x.so",
            macos: "X.framework/X",
            isBundled: () => false,
          ),
        ],
      );
      expect(failures, isEmpty);
    });

    test("does nothing on mobile", () {
      checkNativeLibrariesOnStartup(
        os: "android",
        executable: "/data/app/stack_wallet",
        open: (_) => throw ArgumentError(_notFound),
        exists: (_) => false,
      );
      expect(takeNativeLibraryFailures(), isEmpty);
    });

    test("a check that blows up counts as a pass", () {
      checkNativeLibrariesOnStartup(
        os: "windows",
        executable: _exe,
        open: (_) => throw ArgumentError(_notFound),
        exists: (_) => throw StateError("no file system"),
      );
      expect(takeNativeLibraryFailures(), isEmpty);
    });

    test("one entry blowing up does not hide the others", () async {
      await loadCoinlibOrRecordFailure(() async => throw ArgumentError("x"));
      checkNativeLibrariesOnStartup(
        os: "windows",
        executable: _exe,
        open: (name) {
          if (name != "salvium_libwallet2_api_c.dll") {
            throw ArgumentError(_notFound);
          }
        },
        // The Monero entry's file system check dies; Wownero's file is
        // present but won't load; secp256k1's check dies too.
        exists: (path) {
          if (path.contains("monero") || path.contains("secp")) {
            throw StateError("no file system");
          }
          return true;
        },
      );
      final failures = takeNativeLibraryFailures();
      expect(failures.map((f) => f.displayName), [
        "Wownero wallets",
        "Most wallets",
      ]);
      expect(failures.first.result.problem, NativeLibraryProblem.loadFailed);
      expect(failures.last.result.error, contains("x"));
    });

    test("a coinlib error is reported against secp256k1", () async {
      await loadCoinlibOrRecordFailure(
        () async => throw StateError("secp256k1_context_create not found"),
      );
      final failures = _startup({});
      expect(failures.map((f) => f.displayName), ["Most wallets"]);
      expect(failures.single.result.problem, NativeLibraryProblem.loadFailed);
      expect(failures.single.result.error, contains("secp256k1_context"));
      expect(
        failures.single.result.path,
        r"C:\Program Files\Stack Wallet\secp256k1.dll",
      );
    });

    test("a missing secp256k1 is reported once", () async {
      await loadCoinlibOrRecordFailure(() async => throw ArgumentError(""));
      final failures = _startup({"secp256k1.dll"});
      expect(failures.map((f) => f.displayName), ["Most wallets"]);
      expect(failures.single.result.problem, NativeLibraryProblem.missing);
    });

    test("a coinlib error is forgotten after one check", () async {
      await loadCoinlibOrRecordFailure(() async => throw ArgumentError(""));
      _startup({});
      expect(_startup({}), isEmpty);
    });
  });
}
