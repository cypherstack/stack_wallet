// SDK-only: setup/preflight must work before pub get, without native hooks.
import 'dart:convert';
import 'dart:io';

const dnixPackageNames = {
  'frostdart',
  'tor_ffi_plugin',
  'flutter_libepiccash',
  'flutter_libmwc',
};

Set<String> enabledDnixPackages(String app) => switch (app) {
  'stack_wallet' => dnixPackageNames,
  'stack_duo' => {'frostdart', 'tor_ffi_plugin'},
  'campfire' => {'tor_ffi_plugin'},
  _ => throw ArgumentError.value(app, 'app', 'Unknown app'),
};

class NativeDependency {
  const NativeDependency(this.name, this.repository, this.revision);
  final String name;
  final String repository;
  final String revision;

  Directory cachedDirectory(Directory cache) =>
      Directory.fromUri(cache.uri.resolve('git/$repository-$revision/'));
}

/// Read just the fixed Git dependency blocks, not arbitrary YAML. Fail closed
/// if their structure changes; this script cannot depend on package:yaml yet.
List<NativeDependency> readNativeDependencies(Directory project) {
  final template = File.fromUri(
    project.uri.resolve('scripts/app_config/templates/pubspec.template.yaml'),
  ).readAsStringSync().replaceAll(RegExp(r'^#', multiLine: true), '');
  return [for (final name in dnixPackageNames) _readDependency(template, name)];
}

NativeDependency _readDependency(String template, String name) {
  final block = RegExp(
    '^  $name:\\r?\\n    git:\\r?\\n'
    r'      url: https://github\.com/cypherstack/([\w-]+?)(?:\.git)?\r?\n'
    r'      ref: ([a-f0-9]{40})(?:\s*#[^\r\n]*)?\r?$',
    multiLine: true,
  ).firstMatch(template);
  if (block == null) {
    throw FormatException(
      'Expected a full GitHub commit pin for $name in '
      'pubspec.template.yaml. Update the native dependency reader if the '
      'template layout changes.',
    );
  }
  return NativeDependency(name, block[1]!, block[2]!);
}

Directory? pubCacheDirectory(Map<String, String> environment, String os) {
  final explicit = environment['PUB_CACHE'];
  if (explicit != null && explicit.isNotEmpty) return Directory(explicit);
  if (os == 'windows') {
    final local = environment['LOCALAPPDATA'];
    return local == null ? null : Directory('$local/Pub/Cache');
  }
  final home = environment['HOME'];
  return home == null ? null : Directory('$home/.pub-cache');
}

Map<String, Directory> resolvedNativeDirectories(Directory project) {
  final config = File.fromUri(
    project.uri.resolve('.dart_tool/package_config.json'),
  );
  if (!config.existsSync()) return {};
  final data = jsonDecode(config.readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final entry in data['packages'] as List<dynamic>)
      if (dnixPackageNames.contains((entry as Map<String, dynamic>)['name']))
        entry['name'] as String: Directory.fromUri(
          config.uri.resolve(entry['rootUri'] as String),
        ),
  };
}

/// Check both the selected Git pins and resolved/local overrides. A previous
/// app configuration can have a different dependency closure, so filter by app.
List<String> nativeBuildOverrides(
  Directory project,
  String app, {
  Map<String, String>? environment,
  String? os,
}) {
  final enabled = enabledDnixPackages(app);
  final cache = pubCacheDirectory(
    environment ?? Platform.environment,
    os ?? Platform.operatingSystem,
  );
  final directories = <String>{
    for (final entry in resolvedNativeDirectories(project).entries)
      if (enabled.contains(entry.key)) entry.value.path,
    if (cache != null)
      for (final dependency in readNativeDependencies(project))
        if (enabled.contains(dependency.name))
          dependency.cachedDirectory(cache).path,
  };
  final overrides = <String>{};
  for (final directory in directories) {
    final file = File.fromUri(Directory(directory).uri.resolve('.dnix-build'));
    if (file.existsSync()) overrides.add(file.path);
  }
  return overrides.toList();
}

class XcodeRequirement {
  const XcodeRequirement({
    required this.version,
    required this.build,
    required this.upstreamBuildPinned,
  });
  final String version;
  final String build;
  final bool upstreamBuildPinned;
}

typedef NativeMetadataLoader = Future<Map<String, dynamic>> Function(
  NativeDependency dependency,
);

Future<XcodeRequirement> loadXcodeRequirement(
  Directory project, {
  String app = 'stack_wallet',
  NativeMetadataLoader? readMetadata,
}) async {
  final enabled = enabledDnixPackages(app);
  final compatibility = jsonDecode(
    File.fromUri(
      project.uri.resolve('tool/native_dependency_compatibility.json'),
    ).readAsStringSync(),
  ) as Map<String, dynamic>;
  final legacyBuilds = compatibility['xcodeBuilds'] as Map<String, dynamic>;
  final cache = pubCacheDirectory(
    Platform.environment,
    Platform.operatingSystem,
  );
  XcodeRequirement? required;
  var allPinned = true;
  for (final dependency in readNativeDependencies(project)) {
    if (!enabled.contains(dependency.name)) continue;
    final metadata =
        await (readMetadata?.call(dependency) ??
            _readMetadata(dependency, cache));
    final toolchains = metadata['toolchains'] as Map<String, dynamic>;
    final version = toolchains['xcode'] as String?;
    final pinnedBuild = toolchains['xcodeBuild'] as String?;
    final legacy = legacyBuilds[dependency.revision] as Map<String, dynamic>?;
    final build =
        pinnedBuild ??
        (legacy?['version'] == version ? (legacy?['build'] as String?) : null);
    if (version == null ||
        !RegExp(r'^\d+\.\d+(?:\.\d+)?$').hasMatch(version) ||
        build == null ||
        !RegExp(r'^[0-9A-Za-z]+$').hasMatch(build)) {
      throw FormatException(
        '${dependency.name}@${dependency.revision} needs '
        'an Xcode version and release build. Prefer an upstream '
        'toolchains.xcodeBuild pin; otherwise review and record compatibility '
        'for this exact revision in tool/native_dependency_compatibility.json.',
      );
    }
    if (required != null &&
        (required.version != version || required.build != build)) {
      throw const FormatException(
        'The native packages require different Xcode '
        'versions/builds. Align their pins before configuring Apple builds.',
      );
    }
    allPinned = allPinned && pinnedBuild != null;
    required = XcodeRequirement(
      version: version,
      build: build,
      upstreamBuildPinned: allPinned,
    );
  }
  return required!;
}

Future<Map<String, dynamic>> _readMetadata(
  NativeDependency dependency,
  Directory? cache,
) async {
  if (cache != null) {
    final file = File.fromUri(
      dependency.cachedDirectory(cache).uri.resolve('dnix.json'),
    );
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  // A fresh checkout may not have run pub get. Read only the small metadata
  // file at its exact commit; do not resolve dependencies or launch hooks.
  final uri = Uri.https(
    'raw.githubusercontent.com',
    '/cypherstack/${dependency.repository}/${dependency.revision}/dnix.json',
  );
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  try {
    return await (() async {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Unable to read pinned dnix metadata '
          '(HTTP ${response.statusCode}).',
          uri: uri,
        );
      }
      return jsonDecode(await response.transform(utf8.decoder).join())
          as Map<String, dynamic>;
    })().timeout(const Duration(seconds: 30));
  } finally {
    client.close(force: true);
  }
}
