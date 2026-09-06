import 'dart:io';

import 'package:yaml/yaml.dart';

/// Placeholder strings used in the app repo's template files.
class Placeholders {
  static const appName = 'PlaceHolderName';
  static const appId = 'com.place.holder';
  static const appIdCamel = 'com.place.holderCamel';
  static const appIdSnake = 'com.place.holder_snake';
  static const basicName = 'place_holder';
  static const pubspecName = 'name: PLACEHOLDER';
  static const pubspecDescription = 'description: PLACEHOLDER';
  static const version = 'PLACEHOLDER_V';
  static const buildNumber = 'PLACEHOLDER_B';
}

/// Per-brand configuration, loaded from a YAML manifest file.
class StackWalletManifest {
  StackWalletManifest({
    required this.brand,
    required this.appName,
    required this.appId,
    required this.appIdCamel,
    required this.appIdSnake,
    required this.basicName,
    required this.pubspecName,
    required this.enableCoins,
    required this.prefix,
    required this.separator,
    required this.suffix,
    required this.emptyWalletsMessage,
    required this.appDataDirName,
    required this.shortDescription,
    required this.features,
    required this.appIconAsset,
    required this.supportedCoins,
    required this.defaultEthTokens,
    required this.swapDefaults,
    String? appIdIos,
    List<String>? assetLinkDirs,
    this.templatesDir = 'scripts/app_config/templates',
    this.wlTemplatesDir = 'tool/wl_templates',
    this.wlGeneratedDir = 'lib/wl_gen/generated',
  }) : appIdIos = appIdIos ?? appId,
       assetLinkDirs =
           assetLinkDirs ??
           const [
             'default_themes',
             'icon',
             'lottie',
             'in_app_logo_icons',
             'svg',
           ];

  final String brand;
  final String appName;
  final String appId;
  final String appIdCamel;
  final String appIdSnake;
  final String appIdIos;
  final String basicName;
  final String pubspecName;
  final List<String> enableCoins;

  // app_config.g.dart content.
  final String prefix;
  final String separator;
  final String suffix;
  final String emptyWalletsMessage;
  final String appDataDirName;
  final String shortDescription;
  final List<String> features;
  final ({String light, String dark})? appIconAsset;
  final List<String> supportedCoins;
  final List<String> defaultEthTokens;
  final ({String from, String fromFuzzyNet, String to, String toFuzzyNet})
  swapDefaults;

  final List<String> assetLinkDirs;
  final String templatesDir;
  final String wlTemplatesDir;
  final String wlGeneratedDir;

  static StackWalletManifest load(String path) =>
      parse(File(path).readAsStringSync(), source: path);

  static StackWalletManifest parse(String yamlText, {String? source}) {
    final doc = loadYaml(
      yamlText,
      sourceUrl: source != null ? Uri.file(source) : null,
    );
    if (doc is! YamlMap) {
      throw FormatException('Manifest must be a YAML map', source);
    }

    const allowedKeys = {
      'brand',
      'app_name',
      'app_id',
      'app_id_camel',
      'app_id_snake',
      'app_id_ios',
      'basic_name',
      'pubspec_name',
      'enable_coins',
      'prefix',
      'separator',
      'suffix',
      'empty_wallets_message',
      'app_data_dir_name',
      'short_description',
      'features',
      'app_icon_asset',
      'supported_coins',
      'default_eth_tokens',
      'swap_defaults',
      'asset_link_dirs',
      'templates_dir',
      'wl_templates_dir',
      'wl_generated_dir',
    };
    if (doc.keys.any((key) => !allowedKeys.contains(key))) {
      throw FormatException('Unknown consumer manifest keys', source);
    }
    if (doc.containsKey('asset_link_dirs') &&
        doc['asset_link_dirs'] is! YamlList) {
      throw FormatException('asset_link_dirs must be a list', source);
    }

    String reqString(String key) {
      final v = doc[key];
      if (v is! String) {
        throw FormatException('Missing or invalid required key "$key"', source);
      }
      return v;
    }

    List<String> reqStringList(String key) {
      final v = doc[key];
      if (v is! YamlList || v.any((e) => e is! String)) {
        throw FormatException(
          'Missing or invalid required key "$key" (expected list of strings)',
          source,
        );
      }
      return v.cast<String>().toList();
    }

    ({String light, String dark})? iconAsset;
    final icon = doc['app_icon_asset'];
    if (icon != null) {
      if (icon is! YamlMap ||
          icon['light'] is! String ||
          icon['dark'] is! String) {
        throw FormatException(
          'app_icon_asset must be a map with "light" and "dark"',
          source,
        );
      }
      iconAsset = (
        light: icon['light'] as String,
        dark: icon['dark'] as String,
      );
    }

    final swap = doc['swap_defaults'];
    if (swap is! YamlMap) {
      throw FormatException('Missing required key "swap_defaults"', source);
    }
    for (final k in const ['from', 'from_fuzzy_net', 'to', 'to_fuzzy_net']) {
      if (swap[k] is! String) {
        throw FormatException('swap_defaults.$k must be a string', source);
      }
    }

    return StackWalletManifest(
      brand: reqString('brand'),
      appName: reqString('app_name'),
      appId: reqString('app_id'),
      appIdCamel: reqString('app_id_camel'),
      appIdSnake: reqString('app_id_snake'),
      appIdIos: doc['app_id_ios'] as String?,
      basicName: reqString('basic_name'),
      pubspecName: reqString('pubspec_name'),
      enableCoins: reqStringList('enable_coins'),
      prefix: reqString('prefix'),
      separator: reqString('separator'),
      suffix: reqString('suffix'),
      emptyWalletsMessage: reqString('empty_wallets_message'),
      appDataDirName: reqString('app_data_dir_name'),
      shortDescription: reqString('short_description'),
      features: reqStringList('features'),
      appIconAsset: iconAsset,
      supportedCoins: reqStringList('supported_coins'),
      defaultEthTokens: reqStringList('default_eth_tokens'),
      swapDefaults: (
        from: swap['from'] as String,
        fromFuzzyNet: swap['from_fuzzy_net'] as String,
        to: swap['to'] as String,
        toFuzzyNet: swap['to_fuzzy_net'] as String,
      ),
      assetLinkDirs: doc['asset_link_dirs'] is YamlList
          ? (doc['asset_link_dirs'] as YamlList).cast<String>().toList()
          : null,
      templatesDir:
          doc['templates_dir'] as String? ?? 'scripts/app_config/templates',
      wlTemplatesDir: doc['wl_templates_dir'] as String? ?? 'tool/wl_templates',
      wlGeneratedDir:
          doc['wl_generated_dir'] as String? ?? 'lib/wl_gen/generated',
    );
  }
}
