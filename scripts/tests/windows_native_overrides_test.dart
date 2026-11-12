// Run with: dart scripts/tests/windows_native_overrides_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../tool/check_native_overrides.dart';

String decodePowerShell(String encoded) {
  final bytes = base64Decode(encoded);
  return String.fromCharCodes([
    for (var i = 0; i < bytes.length; i += 2) bytes[i] | (bytes[i + 1] << 8),
  ]);
}

void main() {
  test('WSL guard targets native Dart with literal Windows paths', () async {
    final calls = <({String executable, List<String> arguments})>[];
    const script = "/mnt/c/Users/O'Brien & %HOME%/工具/check.dart";
    const translated = "C:\\Users\\O'Brien & %HOME%\\工具\\check.dart";
    final result = await checkWindowsOverridesFromWsl(
      script: script,
      app: 'stack_wallet',
      run: (executable, arguments) async {
        calls.add((executable: executable, arguments: arguments));
        if (executable == 'wslpath') {
          return ProcessResult(1, 0, '$translated\n', '');
        }
        return ProcessResult(2, 23, 'native output', 'native failure');
      },
    );
    expect(calls.first.executable, 'wslpath');
    expect(calls.first.arguments, ['-w', script]);
    expect(calls.last.executable, 'powershell.exe');
    expect(calls.last.arguments.take(3), [
      '-NoProfile',
      '-NonInteractive',
      '-EncodedCommand',
    ]);
    final command = decodePowerShell(calls.last.arguments.last);
    expect(command, windowsOverrideCommand(translated, 'stack_wallet'));
    expect(
      command,
      contains(
        "& \$dart 'C:\\Users\\O''Brien & %HOME%\\工具\\check.dart' 'stack_wallet' windows;",
      ),
    );
    expect(command, contains('Get-Command dart -CommandType Application'));
    expect(command, isNot(contains('Get-Command dart.exe')));
    expect(command, contains(r"'cache\dart-sdk\bin\dart.exe'"));
    expect(command, endsWith(r'exit $LASTEXITCODE'));
    expect(result.exitCode, 23);
    expect(result.stdout, 'native output');
    expect(result.stderr, 'native failure');
  });

  test('path conversion failure never invokes native guard', () async {
    final calls = <String>[];
    await expectLater(
      checkWindowsOverridesFromWsl(
        script: '/checkout/tool/check_native_overrides.dart',
        app: 'campfire',
        run: (executable, arguments) async {
          calls.add(executable);
          return ProcessResult(1, 1, '', 'invalid path');
        },
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('wslpath could not translate'),
        ),
      ),
    );
    expect(calls, ['wslpath']);
  });

  test(
    'missing interoperability explains native Windows alternative',
    () async {
      await expectLater(
        checkWindowsOverridesFromWsl(
          script: '/checkout/tool/check_native_overrides.dart',
          app: 'stack_duo',
          run: (executable, arguments) async {
            if (executable == 'wslpath') {
              return ProcessResult(1, 0, r'C:\checkout\check.dart', '');
            }
            throw ProcessException(executable, arguments, 'not found');
          },
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Enable WSL interoperability'),
          ),
        ),
      );
    },
  );
}
