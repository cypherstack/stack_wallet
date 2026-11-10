// Plain Dart: usable before pub get without the app's native-assets hooks.
import 'dart:convert';
import 'dart:io';

const secpRevision = 'e3a885d42a7800c1ccebad94ad1e2b82c4df5c65'; // v0.5.0

typedef CommandRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
});

Future<ProcessResult> _run(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) => Process.run(executable, arguments, workingDirectory: workingDirectory);

void _removeWork(Directory directory) => directory.deleteSync(recursive: true);

class SecpBuildException implements Exception {
  SecpBuildException(this.message);
  final String message;
  @override
  String toString() => message;
}

class WindowsSecpBuilder {
  WindowsSecpBuilder({
    required this.root,
    required this.nativeWindows,
    required this.environment,
    this.run = _run,
    this.cleanup = _removeWork,
  });

  final Directory root;
  final bool nativeWindows;
  final Map<String, String> environment;
  final CommandRunner run;
  final void Function(Directory) cleanup;
  late String cmake;
  String? visualStudio;
  ({String root, String version})? windowsSdk;
  late Map<String, String> identity;

  static int compareVersions(String a, String b) {
    final left = a.split('.').map(int.parse).toList();
    final right = b.split('.').map(int.parse).toList();
    for (var i = 0; i < left.length || i < right.length; i++) {
      final difference =
          (i < left.length ? left[i] : 0) - (i < right.length ? right[i] : 0);
      if (difference != 0) return difference;
    }
    return 0;
  }

  Future<({String root, String version})> findWindowsSdk() async {
    final roots = <String>{};
    for (final view in ['64', '32']) {
      try {
        final result = await checked('reg.exe', [
          'query',
          r'HKLM\SOFTWARE\Microsoft\Windows Kits\Installed Roots',
          '/v',
          'KitsRoot10',
          '/reg:$view',
        ]);
        final value = RegExp(
          r'^\s*KitsRoot10\s+REG_(?:EXPAND_)?SZ\s+(.+?)\s*$',
          multiLine: true,
          caseSensitive: false,
        ).firstMatch(result.stdout.toString())?.group(1);
        if (value != null) {
          roots.add(
            value.replaceAllMapped(RegExp(r'%([^%]+)%'), (match) {
              return environment[match.group(1)!] ?? match.group(0)!;
            }),
          );
        }
      } on SecpBuildException {
        // Standalone SDK installers may register only one registry view.
      }
    }
    final usable = <({String root, String version})>[];
    for (final sdkRoot in roots) {
      final include = Directory('$sdkRoot/Include');
      if (!include.existsSync()) continue;
      for (final candidate in include.listSync().whereType<Directory>()) {
        final version = candidate.uri.pathSegments
            .where((s) => s.isNotEmpty)
            .last;
        if (!RegExp(r'^10\.\d+\.\d+\.\d+$').hasMatch(version)) continue;
        final files = [
          'Include/$version/um/Windows.h',
          'Include/$version/shared/sdkddkver.h',
          'Include/$version/ucrt/stdlib.h',
          'Lib/$version/um/x64/kernel32.lib',
          'Lib/$version/ucrt/x64/ucrt.lib',
          'bin/$version/x64/rc.exe',
          'bin/$version/x64/mt.exe',
        ];
        if (files.every((file) => File('$sdkRoot/$file').existsSync())) {
          usable.add((root: sdkRoot, version: version));
        }
      }
    }
    if (usable.isEmpty) {
      throw SecpBuildException(
        'Install a Windows 10/11 SDK with x64 desktop headers, libraries, '
        'and tools. No complete SDK was found under KitsRoot10.',
      );
    }
    usable.sort((a, b) => compareVersions(b.version, a.version));
    return usable.first;
  }

  Future<ProcessResult> checked(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    final ProcessResult result;
    try {
      result = await run(
        executable,
        arguments,
        workingDirectory: workingDirectory,
      );
    } on ProcessException catch (error) {
      throw SecpBuildException('Cannot run $executable: ${error.message}');
    }
    if (result.exitCode != 0) {
      throw SecpBuildException(
        '$executable ${arguments.join(' ')} failed (${result.exitCode}).\n'
        '${result.stdout}\n${result.stderr}',
      );
    }
    return result;
  }

  Future<String> hash(File file) async {
    final result = await checked(
      nativeWindows ? 'certutil.exe' : 'sha256sum',
      nativeWindows ? ['-hashfile', file.path, 'SHA256'] : [file.path],
    );
    final match = RegExp(
      r'^[a-fA-F0-9]{64}(?=\s|$)',
      multiLine: true,
    ).firstMatch(result.stdout.toString());
    if (match == null) {
      throw SecpBuildException('Could not read SHA-256 for ${file.path}.');
    }
    return match.group(0)!.toLowerCase();
  }

  // No checkout, output creation, or compilation: safe before app config.
  Future<void> check() async {
    await checked('git', ['--version']);
    String compiler;
    if (nativeWindows) {
      final programFiles = environment['ProgramFiles(x86)'];
      if (programFiles == null) {
        throw SecpBuildException(
          'ProgramFiles(x86) is missing. Run native Windows Dart.',
        );
      }
      final vswhere =
          '$programFiles/Microsoft Visual Studio/Installer/vswhere.exe';
      if (!File(vswhere).existsSync()) {
        throw SecpBuildException(
          'Install Visual Studio 2022 Desktop development with C++, '
          'including CMake tools and a Windows SDK (vswhere.exe is missing).',
        );
      }
      final result = await checked(vswhere, [
        '-latest',
        '-products',
        '*',
        '-version',
        '[17.0,18.0)',
        '-requires',
        'Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
        '-property',
        'installationPath',
      ]);
      visualStudio = result.stdout.toString().trim();
      final toolsVersion = File(
        '$visualStudio/VC/Auxiliary/Build/Microsoft.VCToolsVersion.default.txt',
      );
      if (visualStudio!.isEmpty || !toolsVersion.existsSync()) {
        throw SecpBuildException(
          'Install the Visual Studio 2022 C++ build tools and Windows SDK.',
        );
      }
      compiler = '${visualStudio!}\n${toolsVersion.readAsStringSync().trim()}';
      windowsSdk = await findWindowsSdk();
    } else {
      compiler = (await checked('x86_64-w64-mingw32-gcc', [
        '--version',
      ])).stdout.toString();
      await checked('make', ['--version']);
    }
    final bundledCmake =
        '$visualStudio/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe';
    cmake = nativeWindows && File(bundledCmake).existsSync()
        ? bundledCmake
        : 'cmake';
    final cmakeVersion = await checked(cmake, ['--version']);
    final version = RegExp(r'^cmake version (\d+\.\d+(?:\.\d+)?)')
        .firstMatch(cmakeVersion.stdout.toString())
        ?.group(1);
    final minimum = nativeWindows ? '3.21' : '3.13';
    if (version == null || compareVersions(version, minimum) < 0) {
      throw SecpBuildException(
        'CMake $minimum or newer is required for Windows secp256k1 '
        '(found ${version ?? 'an unrecognized version'} at $cmake).',
      );
    }
    identity = {
      'revision': secpRevision,
      'host': nativeWindows ? 'windows-msvc-x64' : 'linux-mingw-x64',
      'recipe': await hash(
        File('${root.path}/scripts/windows/build_secp256k1.dart'),
      ),
      'cmake': '${cmakeVersion.stdout}'.trim(),
      'compiler': compiler.trim(),
      if (windowsSdk != null)
        'sdk': '${windowsSdk!.root}\n${windowsSdk!.version}',
      // Only explicit compile/link flags, not unrelated process environment.
      for (final flag in [
        'CFLAGS',
        'CXXFLAGS',
        'CPPFLAGS',
        'LDFLAGS',
        'CL',
        '_CL_',
        'LINK',
        '_LINK_',
      ])
        flag: environment[flag] ?? '',
    };
  }

  Future<void> build() async {
    // --check runs before configuration in a separate process. Revalidate here
    // to identify the tools and inputs actually used by this build/cache lookup.
    await check();
    final output = File('${root.path}/build/secp256k1.dll');
    final receipt = File('${output.path}.json');
    if (output.existsSync() && receipt.existsSync()) {
      try {
        final recorded =
            jsonDecode(receipt.readAsStringSync()) as Map<String, dynamic>;
        if (identity.entries.every((e) => recorded[e.key] == e.value) &&
            recorded['sha256'] == await hash(output)) {
          stdout.writeln(
            'Reusing ${output.path} (verified local build cache).',
          );
          return;
        }
      } on FormatException {
        // An incomplete/invalid receipt is a cache miss.
      } on TypeError {
        // An unrelated JSON value is also a cache miss.
      }
    }
    output.parent.createSync(recursive: true);
    // An interrupted rebuild must not leave a receipt claiming an old DLL
    // is current.
    if (receipt.existsSync()) receipt.deleteSync();
    final work = output.parent.createTempSync('secp256k1-windows-');
    try {
      final source = '${work.path}/source';
      final buildDir = '$source/build';
      await checked('git', ['init', source]);
      await checked('git', [
        'fetch',
        '--depth',
        '1',
        '--no-tags',
        'https://github.com/bitcoin-core/secp256k1.git',
        secpRevision,
      ], workingDirectory: source);
      await checked('git', [
        'checkout',
        '--detach',
        secpRevision,
      ], workingDirectory: source);
      await checked(cmake, [
        '-S',
        source,
        '-B',
        buildDir,
        if (nativeWindows) ...[
          '-G',
          'Visual Studio 17 2022',
          '-A',
          'x64',
          '-DCMAKE_GENERATOR_INSTANCE=$visualStudio',
          '-DCMAKE_SYSTEM_VERSION=${windowsSdk!.version}',
        ] else ...[
          '-G',
          'Unix Makefiles',
          '-DCMAKE_TOOLCHAIN_FILE=$source/cmake/x86_64-w64-mingw32.toolchain.cmake',
        ],
        '-DCMAKE_BUILD_TYPE=RelWithDebInfo',
        '-DBUILD_SHARED_LIBS=ON',
        '-DSECP256K1_ENABLE_MODULE_RECOVERY=ON',
        '-DSECP256K1_BUILD_TESTS=OFF',
        '-DSECP256K1_BUILD_EXHAUSTIVE_TESTS=OFF',
        '-DSECP256K1_BUILD_CTIME_TESTS=OFF',
        '-DSECP256K1_BUILD_BENCHMARK=OFF',
        '-DSECP256K1_BUILD_EXAMPLES=OFF',
      ]);
      await checked(cmake, [
        '--build',
        buildDir,
        '--config',
        'RelWithDebInfo',
        '--parallel',
      ]);
      final library = File(
        '$buildDir/src/${nativeWindows ? 'RelWithDebInfo/' : ''}libsecp256k1-2.dll',
      );
      if (!library.existsSync() || library.lengthSync() == 0) {
        throw SecpBuildException(
          'CMake did not produce the expected DLL: ${library.path}',
        );
      }
      final newReceipt = File('${work.path}/receipt.json');
      newReceipt.writeAsStringSync(
        '${jsonEncode({...identity, 'sha256': await hash(library)})}\n',
      );
      // Both temporary files are under build/ on the destination filesystem.
      // Publish complete files; a failed/interrupted publish has no valid receipt.
      library.renameSync(output.path);
      newReceipt.renameSync(receipt.path);
      stdout.writeln(
        'Built ${output.path} from secp256k1 v0.5.0 ($secpRevision).',
      );
    } finally {
      try {
        cleanup(work);
      } on FileSystemException catch (error) {
        // Windows scanners can keep generated files open after the compiler
        // exits. Preserve either the successful publication or the build error.
        stderr.writeln(
          'Could not remove ${work.path}: ${error.message}. '
          'You can remove this temporary directory later.',
        );
      }
    }
  }
}

Future<void> main(List<String> args) async {
  if (args.isNotEmpty && !(args.length == 1 && args.single == '--check')) {
    stderr.writeln(
      'Usage: dart scripts/windows/build_secp256k1.dart [--check]',
    );
    exitCode = 64;
    return;
  }
  if (!Platform.isWindows && !Platform.isLinux) {
    stderr.writeln('Windows secp256k1 requires native Windows or Linux/WSL.');
    exitCode = 1;
    return;
  }
  final builder = WindowsSecpBuilder(
    root: File.fromUri(Platform.script).parent.parent.parent,
    nativeWindows: Platform.isWindows,
    environment: Platform.environment,
  );
  try {
    if (args.isEmpty) {
      await builder.build();
    } else {
      await builder.check();
    }
  } on SecpBuildException catch (error) {
    stderr.writeln('Windows secp256k1: $error');
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Windows secp256k1: ${error.message} (${error.path})');
    exitCode = 1;
  }
}
