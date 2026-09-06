import 'package:whitelabel/whitelabel.dart';
import 'manifest.dart';

String literal(Object? value) => encodeTemplateValue('dart', value);

String renderAppConfig(
  StackWalletManifest m,
  String commitHash,
  String mwebdExeSha256,
) {
  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln()
    ..writeln("part of 'app_config.dart';")
    ..writeln()
    ..writeln('const _prefix = ${literal(m.prefix)};')
    ..writeln('const _separator = ${literal(m.separator)};')
    ..writeln('const _suffix = ${literal(m.suffix)};')
    ..writeln('const _emptyWalletsMessage =')
    ..writeln('    ${literal(m.emptyWalletsMessage)};')
    ..writeln('const _appDataDirName = ${literal(m.appDataDirName)};')
    ..writeln('const _shortDescriptionText = ${literal(m.shortDescription)};')
    ..writeln('const _commitHash = ${literal(commitHash)};')
    ..writeln()
    ..writeln('const _mwebdExeHash = ${literal(mwebdExeSha256)};')
    ..writeln()
    ..writeln('const Set<AppFeature> _features = {');
  for (var i = 0; i < m.features.length; i++) {
    final trailing = i == m.features.length - 1 ? '' : ',';
    buffer.writeln('  AppFeature.${m.features[i]}$trailing');
  }
  buffer
    ..writeln('};')
    ..writeln();
  final icon = m.appIconAsset;
  if (icon == null) {
    buffer.writeln(
      'const ({String light, String dark})? _appIconAsset = null;',
    );
  } else {
    buffer
      ..writeln('const ({String light, String dark})? _appIconAsset = (')
      ..writeln('  light: ${literal(icon.light)},')
      ..writeln('  dark: ${literal(icon.dark)},')
      ..writeln(');');
  }
  buffer
    ..writeln()
    ..writeln(
      'final List<CryptoCurrency> _supportedCoins = List.unmodifiable([',
    );
  for (final coinLine in m.supportedCoins) {
    buffer.writeln('  $coinLine');
  }
  buffer
    ..writeln(']);')
    ..writeln();
  if (m.defaultEthTokens.isEmpty) {
    buffer.writeln('const List<EthContract> _defaultEthTokens = [];');
  } else {
    buffer.writeln('final List<EthContract> _defaultEthTokens = [');
    for (final token in m.defaultEthTokens) {
      buffer.writeln('  DefaultTokens.$token,');
    }
    buffer.writeln('];');
  }
  buffer
    ..writeln()
    ..writeln(
      'final ({String from, String fromFuzzyNet, String to, String toFuzzyNet})',
    )
    ..writeln('_swapDefaults = (')
    ..writeln('  from: ${literal(m.swapDefaults.from)},')
    ..writeln('  fromFuzzyNet: ${literal(m.swapDefaults.fromFuzzyNet)},')
    ..writeln('  to: ${literal(m.swapDefaults.to)},')
    ..writeln('  toFuzzyNet: ${literal(m.swapDefaults.toFuzzyNet)},')
    ..writeln(');')
    ..writeln();

  return buffer.toString();
}
