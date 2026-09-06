import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:whitelabel/whitelabel.dart';

import 'app_config.dart';
import 'manifest.dart';

export 'manifest.dart';

const coinMarkers = {
  'MWC',
  'MWEBD',
  'XMR',
  'WOW',
  'SAL',
  'TOR',
  'EPIC',
  'FIRO',
  'XEL',
  'FROST',
};
const dependencyMarkers = {
  ...coinMarkers,
  'MWEBDEXE',
  'ISAR',
  'NATIVE_PREBUILTS',
};
const features = {
  'themeSelection',
  'buy',
  'tor',
  'shopinBit',
  'cakePay',
  'swap',
};
const coinTypes = {
  'Bitcoin',
  'Monero',
  'Banano',
  'Bitcoincash',
  'BitcoinFrost',
  'Cardano',
  'Dash',
  'Dogecoin',
  'Ecash',
  'Epiccash',
  'Ethereum',
  'Fact0rn',
  'Firo',
  'Litecoin',
  'Mimblewimblecoin',
  'Nano',
  'Namecoin',
  'Particl',
  'Peercoin',
  'Salvium',
  'Solana',
  'Stellar',
  'Tezos',
  'Wownero',
  'Xelis',
};
const coinRequirements = {
  'Monero': 'XMR',
  'Wownero': 'WOW',
  'Salvium': 'SAL',
  'Epiccash': 'EPIC',
  'Mimblewimblecoin': 'MWC',
  'Firo': 'FIRO',
  'Xelis': 'XEL',
  'BitcoinFrost': 'FROST',
  'Litecoin': 'MWEBD',
};
const assetDirs = [
  'default_themes',
  'icon',
  'lottie',
  'in_app_logo_icons',
  'svg',
];
const nativeFiles = {
  'android': [
    'android/app/build.gradle',
    'android/app/src/debug/AndroidManifest.xml',
    'android/app/src/profile/AndroidManifest.xml',
    'android/app/src/main/AndroidManifest.xml',
    'android/app/src/main/profile/AndroidManifest.xml',
    'android/app/src/main/kotlin/com/cypherstack/stackwallet/MainActivity.kt',
  ],
  'linux': ['linux/CMakeLists.txt', 'linux/my_application.cc'],
  'ios': ['ios/Runner/Info.plist', 'ios/Runner.xcodeproj/project.pbxproj'],
  'macos': [
    'macos/Runner.xcodeproj/project.pbxproj',
    'macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme',
    'macos/Runner/Configs/AppInfo.xcconfig',
  ],
  'windows': [
    'windows/runner/Runner.rc.in',
    'windows/runner/main.cpp',
    'windows/CMakeLists.txt',
  ],
};

void validateBrand(StackWalletManifest brand) {
  for (final value in [
    brand.brand,
    brand.basicName,
    brand.pubspecName,
    brand.appDataDirName,
  ]) {
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(value)) {
      throw FormatException('Invalid brand identifier: $value');
    }
  }
  for (final value in [
    brand.appId,
    brand.appIdIos,
    brand.appIdCamel,
    brand.appIdSnake,
  ]) {
    if (!RegExp(
      r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$',
    ).hasMatch(value)) {
      throw FormatException('Invalid app identifier: $value');
    }
  }
  if (brand.appName != '${brand.prefix}${brand.separator}${brand.suffix}') {
    throw const FormatException('App name and Dart display name disagree');
  }
  if (!coinMarkers.containsAll(brand.enableCoins) ||
      brand.enableCoins.toSet().length != brand.enableCoins.length) {
    throw const FormatException('Unknown or duplicate coin markers');
  }
  if (!features.containsAll(brand.features) ||
      brand.features.toSet().length != brand.features.length) {
    throw const FormatException('Unknown or duplicate features');
  }
  if (brand.defaultEthTokens.any(
        (token) => !RegExp(r'^[a-z][A-Za-z0-9]*$').hasMatch(token),
      ) ||
      brand.defaultEthTokens.toSet().length != brand.defaultEthTokens.length) {
    throw const FormatException('Invalid or duplicate default ETH tokens');
  }
  // Accept only the legacy constructor notation, never arbitrary Dart code.
  final pattern = RegExp(
    r'^(?:if \(!Platform\.isMacOS\) )?([A-Za-z][A-Za-z0-9]*)\(CryptoCurrencyNetwork\.(main|test|test4)\),$',
  );
  for (final coin in brand.supportedCoins) {
    final match = pattern.firstMatch(coin);
    if (match == null || !coinTypes.contains(match.group(1))) {
      throw FormatException('Unsupported coin declaration: $coin');
    }
    final requirement = coinRequirements[match.group(1)];
    if (requirement != null && !brand.enableCoins.contains(requirement)) {
      throw FormatException('Coin declaration requires $requirement: $coin');
    }
  }
  if (brand.features.contains('tor') && !brand.enableCoins.contains('TOR')) {
    throw const FormatException('The Tor feature requires its dependency');
  }
  if (brand.supportedCoins.isEmpty ||
      brand.supportedCoins.toSet().length != brand.supportedCoins.length) {
    throw const FormatException('Empty or duplicate coin declarations');
  }
  if (brand.templatesDir != 'scripts/app_config/templates' ||
      brand.wlTemplatesDir != 'tool/wl_templates' ||
      brand.wlGeneratedDir != 'lib/wl_gen/generated' ||
      jsonEncode(brand.assetLinkDirs) != jsonEncode(assetDirs)) {
    throw const FormatException(
      'This adapter requires the versioned Stack Wallet project layout',
    );
  }
}

String readProjectFile(String root, String relative) {
  var current = root;
  for (final part in relative.split('/')) {
    if (part.isEmpty || part == '.' || part == '..' || part.contains('\\')) {
      throw const FormatException('Invalid consumer input path');
    }
    current = p.join(current, part);
    if (FileSystemEntity.isLinkSync(current)) {
      throw FileSystemException(
        'Linked consumer input is not supported',
        current,
      );
    }
  }
  return File(current).readAsStringSync();
}

String resolveRevision(String root, String? supplied) {
  final result = supplied == null
      ? Process.runSync('git', ['-C', root, 'rev-parse', '--verify', 'HEAD'])
      : null;
  if (result != null && result.exitCode != 0) {
    throw StateError(
      'Cannot read revision; provide --revision for source archives',
    );
  }
  final revision = supplied ?? result!.stdout.toString().trim();
  if (!RegExp(r'^(?:[a-f0-9]{40}|[a-f0-9]{64})$').hasMatch(revision)) {
    throw const FormatException(
      'Revision must be a complete lowercase commit hash',
    );
  }
  return revision;
}

ConfigurationPlan planStackWallet({
  required String projectRoot,
  required StackWalletManifest brand,
  required String version,
  required String buildNumber,
  required Set<String> platforms,
  String? revision,
  String? windowsMwebdSha256,
  String? buildFlavor,
  bool nativePrebuilts = false,
  bool overwrite = false,
}) {
  validateBrand(brand);
  if (buildFlavor != null && buildFlavor != brand.brand) {
    throw const FormatException('Build flavor disagrees with configured brand');
  }
  if (!RegExp(
    r'^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)'
    r'(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$',
  ).hasMatch(version)) {
    throw const FormatException('Version must be x.y.z[-prerelease]');
  }
  final number = int.tryParse(buildNumber);
  if (!RegExp(r'^[1-9][0-9]*$').hasMatch(buildNumber) ||
      number == null ||
      number > 2100000000) {
    throw const FormatException('Build number must be in 1..2100000000');
  }
  if (platforms.isEmpty || !nativeFiles.keys.toSet().containsAll(platforms)) {
    throw const FormatException('Select supported native platforms');
  }
  final root = Directory(p.absolute(projectRoot)).resolveSymbolicLinksSync();
  final hash = resolveRevision(root, revision);
  final windowsMwebd =
      platforms.contains('windows') && brand.enableCoins.contains('MWEBD');
  var exeHash = '';
  if (windowsMwebd) {
    final expected = windowsMwebdSha256;
    if (expected == null || !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(expected)) {
      throw const FormatException(
        'Windows MWEB requires an independently supplied --mwebd-sha256 and a prepared executable',
      );
    }
    final executable = File(p.join(root, 'assets/windows/mwebd.exe'));
    if (FileSystemEntity.typeSync(executable.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw StateError('Missing regular assets/windows/mwebd.exe');
    }
    exeHash = sha256.convert(executable.readAsBytesSync()).toString();
    if (exeHash != expected.toLowerCase()) {
      throw StateError('mwebd.exe digest does not match the supplied digest');
    }
  }
  final generated = <GeneratedFile>[];
  void add(String path, String content, {Iterable<String> scope = const []}) =>
      generated.add(
        GeneratedFile(path, utf8.encode(content), platforms: scope),
      );
  var pubspec = readProjectFile(
    root,
    'scripts/app_config/templates/pubspec.template.yaml',
  );
  for (final token in [
    'name: PLACEHOLDER',
    'description: PLACEHOLDER',
    'PLACEHOLDER_V',
    'PLACEHOLDER_B',
  ]) {
    if (!pubspec.contains(token)) {
      throw StateError('Unsupported pubspec template: missing $token');
    }
  }
  pubspec = pubspec
      .replaceAll('name: PLACEHOLDER', 'name: ${brand.pubspecName}')
      .replaceAll(
        'description: PLACEHOLDER',
        'description: ${RegExp(r"^[A-Za-z][A-Za-z0-9 ]*$").hasMatch(brand.appName) ? brand.appName : encodeTemplateValue("yaml", brand.appName)}',
      )
      .replaceAll('PLACEHOLDER_V', version)
      .replaceAll('PLACEHOLDER_B', buildNumber);
  // Native identity validation below restricts the names to the actual flavor
  // definitions. Existing three-brand descriptions are valid plain YAML.
  add(
    'pubspec.yaml',
    processDependencyBlocks(pubspec, {
      ...brand.enableCoins,
      if (windowsMwebd) 'MWEBDEXE',
      if (nativePrebuilts) 'NATIVE_PREBUILTS',
    }),
  );
  add('lib/app_config.g.dart', renderAppConfig(brand, hash, exeHash));
  final templateDirectory = Directory(p.join(root, 'tool/wl_templates'));
  final templates = templateDirectory.listSync(followLinks: false)
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final template in templates) {
    final match = RegExp(
      r'^([A-Z]+)_(.+)\.template\.dart$',
    ).firstMatch(p.basename(template.path));
    if (template is! File ||
        match == null ||
        !coinMarkers.contains(match.group(1))) {
      throw StateError('Unexpected interface template: ${template.path}');
    }
    add(
      'lib/wl_gen/generated/${match.group(2)}.dart',
      renderInterface(
        readProjectFile(root, 'tool/wl_templates/${p.basename(template.path)}'),
        brand.enableCoins.contains(match.group(1)),
      ),
    );
  }
  if (templates.isEmpty) throw StateError('Interface templates are missing');
  for (final platform in platforms) {
    validateNativeFlavor(root, brand, platform);
    for (final path in nativeFiles[platform]!) {
      final content = readProjectFile(
        root,
        'scripts/app_config/templates/$path',
      );
      if (RegExp(
        r'PlaceHolderName|com\.place\.holder|place_holder',
      ).hasMatch(content)) {
        throw StateError(
          'Legacy identity placeholders remain in $path; migrate native flavors first',
        );
      }
      add(path, content, scope: [platform]);
    }
  }
  final files = <Map<String, Object?>>[
    for (final name in assetDirs)
      {
        'source': 'asset_sources/$name/${brand.brand}',
        'destination': 'assets/$name',
        'mode': 'copy',
      },
    if (platforms.contains('android'))
      {
        'source':
            'asset_sources/other/playstore_icon/${brand.brand}/app_icon-playstore.png',
        'destination': 'android/app/src/main/app_icon-playstore.png',
        'mode': 'copy',
        'platforms': ['android'],
      },
  ];
  final manifest = BrandManifest.parse(
    jsonEncode({
      'schema_version': 1,
      'brand': brand.brand,
      'platforms': nativeFiles.keys.toList(),
      'files': files,
    }),
    sourceDirectory: root,
  );
  return Configurator(
    projectRoot: root,
    manifest: manifest,
  ).plan(platforms: platforms, generatedFiles: generated, overwrite: overwrite);
}

String processDependencyBlocks(String text, Set<String> enabled) {
  String? active;
  final found = <String>{};
  final result = <String>[];
  for (final line in const LineSplitter().convert(text)) {
    final start = RegExp(r'^# %%ENABLE_([A-Z_]+)%%$').firstMatch(line.trim());
    final end = RegExp(r'^# %%END_ENABLE_([A-Z_]+)%%$').firstMatch(line.trim());
    if (start != null) {
      final marker = start.group(1)!;
      if (active != null ||
          !dependencyMarkers.contains(marker) ||
          !found.add(marker)) {
        throw const FormatException(
          'Nested, duplicate, or unknown dependency marker',
        );
      }
      active = marker;
    } else if (end != null) {
      if (active != end.group(1)) {
        throw const FormatException('Unbalanced dependency marker');
      }
      active = null;
    } else if (line.contains('%%ENABLE_') || line.contains('%%END_ENABLE_')) {
      throw const FormatException('Malformed dependency marker');
    } else if (active != null && enabled.contains(active)) {
      if (line.trim().isNotEmpty && !line.trimLeft().startsWith('#')) {
        throw const FormatException(
          'Dependency templates must contain commented blocks',
        );
      }
      result.add(line.replaceFirst('#', ''));
      continue;
    }
    result.add(line);
  }
  if (active != null || !found.containsAll(enabled)) {
    throw const FormatException('Missing dependency markers or closing marker');
  }
  return result.join('\n');
}

String renderInterface(String text, bool enabled) {
  String? active;
  final lines = <String>['// GENERATED CODE - DO NOT MODIFY BY HAND', ''];
  for (final line in const LineSplitter().convert(text)) {
    final trimmed = line.trim();
    if (trimmed == '//ON' || trimmed == '//OFF') {
      if (active != null) {
        throw const FormatException('Nested interface marker');
      }
      active = trimmed.substring(2);
    } else if (trimmed.startsWith('//END_')) {
      if (trimmed != '//END_$active') {
        throw const FormatException('Unbalanced interface marker');
      }
      active = null;
    } else if (active == null || (active == 'ON') == enabled) {
      lines.add(line);
    }
  }
  if (active != null) throw const FormatException('Unclosed interface marker');
  if (lines.last.isNotEmpty) lines.add('');
  return lines.join('\n');
}

void validateNativeFlavor(
  String root,
  StackWalletManifest brand,
  String platform,
) {
  void require(String content, String expected) {
    final key = expected.trim().split(' ').first;
    final assignments = const LineSplitter()
        .convert(content)
        .map((line) => line.trim())
        .where(
          (line) =>
              line.startsWith('$key ') ||
              line.startsWith('$key\t') ||
              line.startsWith('$key='),
        )
        .toList();
    if (assignments.length != 1 || assignments.single != expected.trim()) {
      throw StateError(
        '$platform flavor differs from manifest: expected $expected',
      );
    }
  }

  if (platform == 'android') {
    final gradle = readProjectFile(
      root,
      'scripts/app_config/templates/android/app/build.gradle',
    );
    final block =
        RegExp(
          '\\b${RegExp.escape(brand.brand)}\\s*\\{([^}]*)\\}',
        ).firstMatch(gradle)?.group(1) ??
        '';
    require(block, 'applicationId "${brand.appId}"');
    require(block, 'manifestPlaceholders = [appLabel: "${brand.appName}"]');
  } else if (platform == 'linux' || platform == 'windows') {
    final cmake = readProjectFile(
      root,
      'scripts/app_config/templates/$platform/CMakeLists.txt',
    );
    final block =
        RegExp(
          '(?:if|elseif)\\(FLUTTER_APP_FLAVOR STREQUAL "${RegExp.escape(brand.brand)}"\\)([\\s\\S]*?)(?:elseif\\(|else\\(|endif\\()',
        ).firstMatch(cmake)?.group(1) ??
        '';
    require(block, 'set(BINARY_NAME "${brand.basicName}")');
    require(block, 'set(APP_DISPLAY_NAME "${brand.appName}")');
    if (platform == 'linux') {
      require(block, 'set(APPLICATION_ID "${brand.appId}")');
    }
  } else if (platform == 'ios') {
    final xcconfig = readProjectFile(
      root,
      'ios/Flutter/Flavor-${brand.brand}.xcconfig',
    );
    require(xcconfig, 'PRODUCT_BUNDLE_IDENTIFIER = ${brand.appIdIos}\n');
    require(xcconfig, 'APP_DISPLAY_NAME = ${brand.appName}\n');
  } else {
    final xcconfig = readProjectFile(
      root,
      'macos/Runner/Configs/AppInfo-${brand.brand}.xcconfig',
    );
    require(xcconfig, 'PRODUCT_BUNDLE_IDENTIFIER = ${brand.appIdSnake}\n');
    require(xcconfig, 'PRODUCT_NAME = ${brand.appName}\n');
  }
}
