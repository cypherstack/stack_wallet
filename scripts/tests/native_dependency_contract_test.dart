// Contract tests for resolved dependencies; run after flutter pub get.
// dnix is deliberately a transitive dependency of the four native packages.
// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dnix/src/wsl_build.dart' as dnix;
import 'package:test/test.dart';

import '../../tool/check_build_environment.dart' show wslNixProbe;
import '../../tool/native_build_options.dart';
import '../../tool/native_dependency_contract.dart';

void main() {
  final repository = File.fromUri(Platform.script).parent.parent.parent;
  late Directory project;
  late Directory cache;

  setUp(() {
    project = Directory.systemTemp.createTempSync('native contract % ');
    cache = Directory.fromUri(project.uri.resolve('pub cache/'))..createSync();
    for (final relative in [
      'scripts/app_config/templates/pubspec.template.yaml',
      'tool/native_dependency_compatibility.json',
    ]) {
      final destination = File.fromUri(project.uri.resolve(relative));
      destination.parent.createSync(recursive: true);
      File.fromUri(repository.uri.resolve(relative)).copySync(destination.path);
    }
  });
  tearDown(() => project.deleteSync(recursive: true));

  Future<XcodeRequirement> requirement({
    String version = '27.0',
    String? build,
  }) => loadXcodeRequirement(
    project,
    readMetadata: (_) async => {
      'toolchains': {'xcode': version, if (build != null) 'xcodeBuild': build},
    },
  );

  test(
    'pins are read from the template, including the tor repository name',
    () {
      final pins = readNativeDependencies(project);
      expect(pins.map((pin) => pin.name).toSet(), dnixPackageNames);
      expect(
        pins.singleWhere((pin) => pin.name == 'tor_ffi_plugin').repository,
        'tor',
      );
      expect(pins.every((pin) => pin.revision.length == 40), isTrue);
    },
  );

  test('known version-only pins use explicit reviewed compatibility', () async {
    final actual = await requirement();
    expect(actual.version, '27.0');
    expect(actual.build, '27A266a');
    expect(actual.upstreamBuildPinned, isFalse);
  });

  test('upstream version and build supersede compatibility', () async {
    final actual = await requirement(version: '28.1', build: '28B123');
    expect(actual.version, '28.1');
    expect(actual.build, '28B123');
    expect(actual.upstreamBuildPinned, isTrue);
  });

  test('Xcode metadata is loaded only for the selected app', () async {
    for (final entry in const {
      'stack_wallet': dnixPackageNames,
      'stack_duo': {'frostdart', 'tor_ffi_plugin'},
      'campfire': {'tor_ffi_plugin'},
    }.entries) {
      final loaded = <String>[];
      await loadXcodeRequirement(
        project,
        app: entry.key,
        readMetadata: (dependency) async {
          expect(entry.value, contains(dependency.name));
          loaded.add(dependency.name);
          return {
            'toolchains': {'xcode': '28.1', 'xcodeBuild': '28B123'},
          };
        },
      );
      expect(loaded, unorderedEquals(entry.value), reason: entry.key);
    }
  });

  test('new version-only revision cannot inherit the previous build', () async {
    final template = File.fromUri(
      project.uri.resolve('scripts/app_config/templates/pubspec.template.yaml'),
    );
    final previous = readNativeDependencies(project).first.revision;
    template.writeAsStringSync(
      template.readAsStringSync().replaceAll(
        previous,
        List.filled(40, '0').join(),
      ),
    );
    await expectLater(requirement(), throwsFormatException);
    await expectLater(requirement(version: '28.1', build: '28B123'), completes);
  });

  test('inconsistent package requirements fail', () async {
    await expectLater(
      loadXcodeRequirement(
        project,
        readMetadata: (dependency) async => {
          'toolchains': {
            'xcode': '28.1',
            'xcodeBuild': dependency.name == 'frostdart' ? '28B123' : '28B124',
          },
        },
      ),
      throwsFormatException,
    );
  });

  test('override guard checks exact pins and only enabled packages', () {
    final frost = readNativeDependencies(project)
        .singleWhere((dependency) => dependency.name == 'frostdart');
    final override = File.fromUri(
      frost.cachedDirectory(cache).uri.resolve('.dnix-build'),
    );
    override.parent.createSync(recursive: true);
    override.writeAsStringSync('dev');
    final environment = {'PUB_CACHE': cache.path};
    expect(
      nativeBuildOverrides(project, 'campfire', environment: environment),
      isEmpty,
    );
    expect(
      nativeBuildOverrides(project, 'stack_duo', environment: environment),
      [override.path],
    );
    override.writeAsStringSync('source');
    expect(
      nativeBuildOverrides(project, 'stack_wallet', environment: environment),
      [override.path],
      reason: 'Even matching overrides can hide later mode changes',
    );
  });

  test('resolved override paths decode spaces and percent characters', () {
    final package = Directory.fromUri(project.uri.resolve('local%20tor%20%25/'))
      ..createSync();
    final override = File.fromUri(package.uri.resolve('.dnix-build'))
      ..writeAsStringSync('prebuilt');
    final config = File.fromUri(
      project.uri.resolve('.dart_tool/package_config.json'),
    );
    config.parent.createSync();
    config.writeAsStringSync(
      jsonEncode({
        'configVersion': 2,
        'packages': [
          {'name': 'tor_ffi_plugin', 'rootUri': '../local%20tor%20%25/'},
        ],
      }),
    );
    expect(
      nativeBuildOverrides(
        project,
        'campfire',
        environment: {'PUB_CACHE': cache.path},
      ),
      [override.path],
    );
  });

  test('Windows default cache and PUB_CACHE override use the right root', () {
    expect(
      pubCacheDirectory({'LOCALAPPDATA': '/users/test/local'}, 'windows')!.path,
      Directory('/users/test/local/Pub/Cache').path,
    );
    expect(
      pubCacheDirectory({'PUB_CACHE': '/explicit'}, 'windows')!.path,
      Directory('/explicit').path,
    );
  });

  test(
    'resolved package metadata agrees with current Xcode compatibility',
    () async {
      final actual = await loadXcodeRequirement(
        repository,
        readMetadata: (dependency) async {
          final uri = await Isolate.resolvePackageUri(
            Uri.parse('package:${dependency.name}/'),
          );
          expect(
            uri,
            isNotNull,
            reason: 'Run flutter pub get for Stack Wallet first',
          );
          final root = Directory.fromUri(uri!).parent;
          expect(
            root.path,
            endsWith('${dependency.repository}-${dependency.revision}'),
          );
          return jsonDecode(
            File.fromUri(root.uri.resolve('dnix.json')).readAsStringSync(),
          ) as Map<String, dynamic>;
        },
      );
      expect(actual.version, isNotEmpty);
      expect(actual.build, isNotEmpty);
    },
  );

  test(
    'WSL validator agrees with dnix on accepted names and common errors',
    () {
      for (final value in [
        null,
        'Ubuntu-24.04',
        '  Custom distro  ',
        'Distro & name',
      ]) {
        expect(validatedDistribution(value), dnix.parseWslDistribution(value));
      }
      for (final value in ['', '   ', 'Ubuntu\u0000']) {
        expect(() => validatedDistribution(value), throwsArgumentError);
        expect(
          () => dnix.parseWslDistribution(value),
          throwsA(isA<Exception>()),
        );
      }
    },
  );

  test(
    'WSL probe tracks the resolved dnix launcher and Nix profile search',
    () async {
      final destination = File.fromUri(
        project.uri.resolve('output/library.dll'),
      );
      late List<String> arguments;
      await dnix.buildWithWsl(
        packagePath: r'C:\source with spaces',
        target: 'x86_64-pc-windows-msvc',
        fileName: 'library.dll',
        destination: destination,
        distribution: ' Ubuntu-24.04 ',
        runCommand: (executable, args) async {
          expect(executable, 'wsl.exe');
          arguments = args;
          destination.writeAsStringSync('fixture');
          return 0;
        },
      );
      expect(arguments.take(7), [
        '--distribution',
        'Ubuntu-24.04',
        '--cd',
        '/',
        '--exec',
        '/bin/sh',
        '-c',
      ]);
      final upstreamScript = arguments[7];
      final search = RegExp(r'if ! command -v nix[\s\S]+?\nfi')
          .firstMatch(wslNixProbe)!
          .group(0)!;
      expect(
        upstreamScript,
        contains(search),
        reason: 'Review the preflight when dnix changes its Nix search',
      );
      expect(upstreamScript, contains('command -v wslpath'));
    },
  );
}
