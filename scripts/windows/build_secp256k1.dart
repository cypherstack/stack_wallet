// Plain Dart: usable before pub get without the app's native-assets hooks.
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
    required this.environment,
    this.run = _run,
    this.cleanup = _removeWork,
  });

  final Directory root;
  final Map<String, String> environment;
  final CommandRunner run;
  final void Function(Directory) cleanup;
  late String cmake;
  late String visualStudio;
  late ({String root, String version}) windowsSdk;

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

  // No checkout, output creation, or compilation: safe before app config.
  Future<void> check() async {
    await checked('git', ['--version']);
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
    if (visualStudio.isEmpty || !toolsVersion.existsSync()) {
      throw SecpBuildException(
        'Install the Visual Studio 2022 C++ build tools and Windows SDK.',
      );
    }
    windowsSdk = await findWindowsSdk();
    final bundledCmake =
        '$visualStudio/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe';
    cmake = File(bundledCmake).existsSync() ? bundledCmake : 'cmake';
    final cmakeVersion = await checked(cmake, ['--version']);
    final version = RegExp(r'^cmake version (\d+\.\d+(?:\.\d+)?)')
        .firstMatch(cmakeVersion.stdout.toString())
        ?.group(1);
    const minimum = '3.21';
    if (version == null || compareVersions(version, minimum) < 0) {
      throw SecpBuildException(
        'CMake $minimum or newer is required for Windows secp256k1 '
        '(found ${version ?? 'an unrecognized version'} at $cmake).',
      );
    }
  }

  Future<void> build() async {
    // --check runs before configuration in a separate process. Revalidate here
    // to discover the tools and SDK actually used by this build.
    await check();
    final output = File('${root.path}/build/secp256k1.dll');
    output.parent.createSync(recursive: true);
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
        '-G',
        'Visual Studio 17 2022',
        '-A',
        'x64',
        '-DCMAKE_GENERATOR_INSTANCE=$visualStudio',
        '-DCMAKE_SYSTEM_VERSION=${windowsSdk.version}',
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
      final library = File('$buildDir/src/RelWithDebInfo/libsecp256k1-2.dll');
      if (!library.existsSync() || library.lengthSync() == 0) {
        throw SecpBuildException(
          'CMake did not produce the expected DLL: ${library.path}',
        );
      }
      // The temporary DLL is on the destination filesystem. Publish it only
      // after a successful build, preserving any previous DLL on build failure.
      library.renameSync(output.path);
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
  if (!Platform.isWindows) {
    stderr.writeln('Windows secp256k1 requires native Windows.');
    exitCode = 1;
    return;
  }
  final builder = WindowsSecpBuilder(
    root: File.fromUri(Platform.script).parent.parent.parent,
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
