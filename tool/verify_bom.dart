// Checks the local toolchain and the pinned native plugins against
// stack-bom.toml.
//
//   dart tool/verify_bom.dart            check, exit 1 on a mismatch
//   dart tool/verify_bom.dart --update   rewrite the [plugins] section from pubspec.lock
//
// No packages needed, so it runs before `flutter pub get`.
import 'dart:convert';
import 'dart:io';

const _bomFile = 'stack-bom.toml';
const _pluginNames = [
  'flutter_libepiccash',
  'flutter_libmwc',
  'flutter_libsparkmobile',
  'frostdart',
  'tor_ffi_plugin',
  'xelis_wallet_flutter',
];

int _failures = 0;
int _warnings = 0;

void _ok(String m) => stdout.writeln('[OK]   $m');
void _warn(String m) {
  _warnings++;
  stdout.writeln('[WARN] $m');
}

void _fail(String m) {
  _failures++;
  stdout.writeln('[FAIL] $m');
}

/// Minimal TOML reader: `[section]` headers and `key = "value"` lines.
Map<String, Map<String, String>> _readBom(String text) {
  final result = <String, Map<String, String>>{};
  var section = '';
  for (final raw in text.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    if (line.startsWith('[') && line.endsWith(']')) {
      section = line.substring(1, line.length - 1);
      result.putIfAbsent(section, () => {});
      continue;
    }
    final eq = line.indexOf('=');
    if (eq < 0) continue;
    final key = line.substring(0, eq).trim();
    var value = line.substring(eq + 1).trim();
    final hash = value.lastIndexOf(' #');
    if (hash >= 0 && value.startsWith('"') == false) {
      value = value.substring(0, hash).trim();
    }
    if (value.startsWith('"')) {
      final end = value.indexOf('"', 1);
      if (end < 0) {
        stderr.writeln('Unterminated string in $_bomFile: $line');
        exit(2);
      }
      value = value.substring(1, end);
    } else if (value.length >= 2 &&
        value.startsWith("'") &&
        value.endsWith("'")) {
      value = value.substring(1, value.length - 1);
    }
    result.putIfAbsent(section, () => {})[key] = value;
  }
  return result;
}

Future<String?> _run(String exe, List<String> args) async {
  try {
    // runInShell lets Windows start flutter.bat. Only stdout is parsed: Flutter
    // writes startup-lock warnings to stderr, and appending those to the JSON
    // breaks --machine output.
    final r = await Process.run(exe, args, runInShell: Platform.isWindows);
    if (r.exitCode != 0) return null;
    return '${r.stdout}'.trim();
  } on ProcessException {
    return null;
  }
}

List<int> _ver(String v) =>
    RegExp(r'\d+').allMatches(v).map((m) => int.parse(m.group(0)!)).toList();

int _cmp(String a, String b) {
  final x = _ver(a), y = _ver(b);
  for (var i = 0; i < 3; i++) {
    final p = i < x.length ? x[i] : 0, q = i < y.length ? y[i] : 0;
    if (p != q) return p.compareTo(q);
  }
  return 0;
}

String _short(String v) => v.length <= 7 ? v : v.substring(0, 7);

/// Plugins declared by the app currently configured in pubspec.yaml.
///
/// Campfire and Stack Duo include only a subset of the pinned plugins, so a
/// missing lock entry is only an error for a plugin the app actually uses.
/// Accepts any consistent indentation and both direct dependencies and
/// dependency_overrides; the hooks: user_defines: block is not a declaration.
Set<String> _declaredPlugins() {
  final file = File('pubspec.yaml');
  if (!file.existsSync()) return {};
  final lines = file.readAsLinesSync();
  final declared = <String>{};
  for (final sectionName in ['dependencies:', 'dependency_overrides:']) {
    final start = lines.indexWhere((l) => l.trimRight() == sectionName);
    if (start < 0) continue;
    int? indent;
    for (var i = start + 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
      if (!line.startsWith(' ')) break;
      indent = line.length - line.trimLeft().length;
      break;
    }
    if (indent == null) continue;
    for (var i = start + 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
      if (!line.startsWith(' ')) break;
      final currentIndent = line.length - line.trimLeft().length;
      if (currentIndent < indent) break;
      if (currentIndent != indent) continue;
      final m = RegExp(r'^[ ]*(\w+):').firstMatch(line);
      if (m != null && _pluginNames.contains(m.group(1))) {
        declared.add(m.group(1)!);
      }
    }
  }
  return declared;
}

/// Reads the git refs of the pinned plugins from pubspec.lock.
Map<String, String> _lockRefs() {
  final lock = File('pubspec.lock');
  if (!lock.existsSync()) return {};
  final lines = lock.readAsLinesSync();
  final refs = <String, String>{};
  for (var i = 0; i < lines.length; i++) {
    final m = RegExp(r'^  (\w+):$').firstMatch(lines[i]);
    if (m == null || !_pluginNames.contains(m.group(1))) continue;
    for (var j = i + 1; j < lines.length && lines[j].startsWith('    '); j++) {
      final r = RegExp(r'resolved-ref: "?([0-9a-f]{40})"?')
          .firstMatch(lines[j]);
      if (r != null) refs[m.group(1)!] = r.group(1)!;
    }
  }
  return refs;
}

Future<void> _update() async {
  final refs = _lockRefs();
  if (refs.isEmpty) {
    stderr.writeln('pubspec.lock not found or has none of the plugins.');
    exit(2);
  }
  final text = File(_bomFile).readAsStringSync();
  final existing = _readBom(text)['plugins'] ?? {};
  final declared = _declaredPlugins();
  // Without a pubspec.yaml we cannot tell which app is configured; keep the
  // old behaviour and update every plugin the lock knows about.
  final updateable = declared.isEmpty ? _pluginNames.toSet() : declared;
  final header = RegExp(
    r'^\[plugins\][ \t]*$',
    multiLine: true,
  ).firstMatch(text);
  final start = header?.start ?? -1;
  if (start < 0 && text.contains('[plugins]')) {
    stderr.writeln(
      'Found [plugins] outside a table header; refusing to update',
    );
    exit(2);
  }
  final tailStart = start < 0
      ? text.length
      : text.indexOf(RegExp(r'\n\[', multiLine: true), start + 1);
  final tail = tailStart < 0 ? '' : text.substring(tailStart);
  final head = start < 0
      ? text.trimRight()
      : text.substring(0, start).trimRight();
  for (final n in updateable) {
    if (!refs.containsKey(n)) {
      stderr.writeln(
        'Warning: $n is declared but missing from pubspec.lock; '
        'pin not updated',
      );
    }
  }
  final buf = StringBuffer(head)
    ..writeln('\n')
    ..writeln('[plugins]')
    ..writeln(
      '# Generated by `dart tool/verify_bom.dart --update` from pubspec.lock. Do not edit by hand.',
    );
  var refreshed = 0;
  var preserved = 0;
  for (final n in _pluginNames) {
    if (updateable.contains(n) && refs.containsKey(n)) {
      buf.writeln('$n = "${refs[n]}"');
      refreshed++;
    } else if (existing.containsKey(n)) {
      // Keep pins for apps this checkout is not configured for.
      buf.writeln('$n = "${existing[n]}"');
      preserved++;
    }
  }
  for (final entry in existing.entries) {
    if (_pluginNames.contains(entry.key)) continue;
    buf.writeln('${entry.key} = "${entry.value}"');
    preserved++;
  }
  buf.write(tail);
  File(_bomFile).writeAsStringSync(buf.toString());
  stdout.writeln(
    'Updated [plugins] in $_bomFile '
    '($refreshed refreshed, $preserved preserved).',
  );
}

Future<void> main(List<String> args) async {
  if (!File(_bomFile).existsSync()) {
    stderr.writeln('Run from the repository root ($_bomFile not found).');
    exit(2);
  }
  if (args.contains('--update')) return _update();

  final bom = _readBom(File(_bomFile).readAsStringSync());
  final root = bom[''] ?? {};
  if (root['schema_version'] != '1') {
    _fail('schema_version must be 1 in $_bomFile');
  }
  final tc = bom['toolchain'] ?? {};

  // Flutter / Dart
  final configuredFlutter = Platform.environment['FLUTTER']?.trim() ?? '';
  final flutterExe =
      configuredFlutter.isNotEmpty && File(configuredFlutter).existsSync()
      ? configuredFlutter
      : 'flutter';
  final fl = await _run(flutterExe, ['--version', '--machine']);
  if (fl == null) {
    _fail('flutter not found in PATH');
  } else {
    final start = fl.indexOf('{');
    final end = fl.lastIndexOf('}');
    if (start < 0 || end <= start) {
      _fail('unexpected output from flutter --version --machine');
    } else {
      try {
        final info =
            jsonDecode(fl.substring(start, end + 1)) as Map<String, dynamic>;
        final v = info['frameworkVersion'] as String;
        final d = info['dartSdkVersion'] as String;
        if (_cmp(v, tc['flutter_min'] ?? '0') < 0) {
          _fail('Flutter $v is older than the minimum ${tc['flutter_min']}');
        } else if (v != tc['flutter']) {
          _warn(
            'Flutter $v (recommended ${tc['flutter']}, '
            'minimum ${tc['flutter_min']})',
          );
        } else {
          _ok('Flutter $v');
        }
        if (d.startsWith(tc['dart_prefix'] ?? '')) {
          _ok('Dart $d');
        } else {
          _fail('Dart $d does not match ${tc['dart_prefix']}.x');
        }
      } on FormatException {
        _fail('could not parse flutter --version --machine output');
      }
    }
  }

  // Rust
  final list = await _run('rustup', ['toolchain', 'list']);
  final rust = tc['rust'] ?? '';
  if (list == null) {
    _fail('rustup not found in PATH');
  } else if (list.split('\n').any((l) => l.startsWith('$rust-'))) {
    _ok('Rust $rust installed via rustup');
  } else {
    _fail('Rust $rust is not installed (rustup toolchain install $rust)');
  }

  // Go
  final go = await _run('go', ['version']);
  final gm = go == null ? null : RegExp(r'go(\d+\.\d+(\.\d+)?)').firstMatch(go);
  if (gm == null) {
    _fail('go not found in PATH');
  } else if (_cmp(gm.group(1)!, tc['go_min'] ?? '0') < 0) {
    _fail('Go ${gm.group(1)} is older than the minimum ${tc['go_min']}');
  } else {
    _ok('Go ${gm.group(1)}');
  }

  // Xcode (macOS only)
  if (Platform.isMacOS) {
    final mac = bom['macos'] ?? {};
    final xc = await _run('xcodebuild', ['-version']);
    final xm = xc == null ? null : RegExp(r'Xcode (\S+)').firstMatch(xc);
    if (xm == null) {
      _fail('Xcode not found (xcode-select -p)');
    } else if (xm.group(1) == mac['xcode']) {
      _ok('Xcode ${xm.group(1)}');
    } else if (xm.group(1) == mac['xcode_dnix']) {
      _warn(
        'Xcode ${xm.group(1)} is the version dnix pins; '
        '${mac['xcode']} is recommended for app builds',
      );
    } else {
      _warn('Xcode ${xm.group(1)} (recommended ${mac['xcode']})');
    }
  }

  // Pinned plugins against pubspec.lock
  final refs = _lockRefs();
  final pinned = bom['plugins'] ?? {};
  final declared = _declaredPlugins();
  final pubspecExists = File('pubspec.yaml').existsSync();
  // A fresh checkout has no pubspec.yaml: build_app.sh generates it later.
  // In that case check every plugin the lock contains, as before.
  final required = pubspecExists ? declared : _pluginNames.toSet();
  if (refs.isEmpty) {
    _warn('pubspec.lock not found, plugin pins not checked');
  } else if (required.isEmpty) {
    _fail(
      'could not read plugin declarations from pubspec.yaml '
      '(expected them under dependencies: or dependency_overrides:)',
    );
  } else {
    for (final n in _pluginNames) {
      if (!required.contains(n)) continue;
      final ref = refs[n];
      final pin = pinned[n];
      if (ref == null) {
        _fail(
          '$n is missing from pubspec.lock (path dependency or not resolved)',
        );
      } else if (pin == null) {
        _fail('$n is missing from [plugins] in $_bomFile (run --update)');
      } else if (pin == ref) {
        _ok('$n ${_short(ref)}');
      } else {
        _fail(
          '$n is ${_short(ref)} in pubspec.lock but '
          '${_short(pin)} in $_bomFile (run --update)',
        );
      }
    }
  }

  stdout.writeln('\n$_failures failure(s), $_warnings warning(s).');
  exit(_failures == 0 ? 0 : 1);
}
