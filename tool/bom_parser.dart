// Pure helpers shared by `dart tool/verify_bom.dart` and its unit tests.
//
// These read the minimal TOML the BOM uses (`[section]` headers and
// `key = "value"` lines), compare version strings, and resolve the plugin
// pins from pubspec.lock / pubspec.yaml. They have no side effects and take
// their input as arguments, so they can be tested without a real toolchain.
import 'dart:io';

/// Pinned plugin package names. Campfire and Stack Duo declare only a subset,
/// so a missing lock entry is only an error for a plugin the app uses.
const List<String> bomPluginNames = [
  'flutter_libepiccash',
  'flutter_libmwc',
  'flutter_libsparkmobile',
  'frostdart',
  'tor_ffi_plugin',
  'xelis_wallet_flutter',
];

const String bomFileName = 'stack-bom.toml';

final RegExp _sectionHeader = RegExp(r'^\[([^\]]+)\][ \t]*(#.*)?$');
final RegExp _pluginsHeader = RegExp(
  r'^\[plugins\][ \t]*(#.*)?$',
  multiLine: true,
);

/// Minimal TOML reader: `[section]` headers and `key = "value"` lines.
/// Accepts tabs or spaces, single or double quotes, and a trailing ` #comment`
/// on a bare value. A value that is not a quoted string keeps everything up to
/// the first ` #`; a quoted value keeps its whole content.
Map<String, Map<String, String>> readBom(String text) {
  final result = <String, Map<String, String>>{};
  var section = '';
  for (final raw in text.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final header = _sectionHeader.firstMatch(line);
    if (header != null) {
      section = header.group(1)!;
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
        throw FormatException('Unterminated string in $bomFileName: $line');
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

/// Resolves a bare command name to an absolute path via PATH, or returns the
/// name unchanged if it is not found (so the caller can report "not found").
///
/// The PATH *list* separator is ';' on Windows and ':' elsewhere.
/// [Platform.pathSeparator] is the path *component* separator ('/' / '\\'),
/// which is the wrong value for splitting PATH, so it is not used here.
String resolveOnPath(String name, {Map<String, String>? environment}) {
  final env = environment ?? Platform.environment;
  if (name.contains('/') || name.contains('\\')) return name;
  final listSep = Platform.isWindows ? ';' : ':';
  final sep = Platform.pathSeparator;
  for (final dir in (env['PATH'] ?? '').split(listSep)) {
    if (dir.isEmpty) continue;
    final candidate = File(dir.endsWith(sep) ? dir : '$dir/$name').path;
    if (File(candidate).existsSync()) return candidate;
  }
  return name;
}

/// The numeric components of a version string, in order.
List<int> versionNumbers(String v) =>
    RegExp(r'\d+').allMatches(v).map((m) => int.parse(m.group(0)!)).toList();

/// Compares two version strings component by component, missing components
/// treated as 0. Returns negative, 0, or positive like [int.compareTo].
int compareVersions(String a, String b) {
  final x = versionNumbers(a), y = versionNumbers(b);
  for (var i = 0; i < 3; i++) {
    final p = i < x.length ? x[i] : 0, q = i < y.length ? y[i] : 0;
    if (p != q) return p.compareTo(q);
  }
  return 0;
}

/// Shortens a git ref or version for one-line reports.
String shortVersion(String v) => v.length <= 7 ? v : v.substring(0, 7);

/// A duplicate `[plugins]` table makes [readBom] silently last-wins and makes
/// `--update` append a second block, so refuse both modes early.
void requireSinglePluginsSection(String text) {
  final count = _pluginsHeader.allMatches(text).length;
  if (count > 1) {
    throw const FormatException(
      'Duplicate [plugins] sections in $bomFileName; keep exactly one.',
    );
  }
}

/// Plugin names declared by the app currently configured in pubspec.yaml.
///
/// Accepts any consistent indentation and both direct dependencies and
/// dependency_overrides; the hooks: user_defines: block is not a declaration.
Set<String> declaredPlugins({String? pubspecText}) {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) return {};
  final lines = (pubspecText ?? pubspec.readAsStringSync()).split('\n');
  final declared = <String>{};
  for (final sectionName in ['dependencies:', 'dependency_overrides:']) {
    final header = RegExp('^${RegExp.escape(sectionName)}\\s*(#.*)?\$');
    final start = lines.indexWhere((l) => header.hasMatch(l.trimRight()));
    if (start < 0) continue;
    String? indent;
    for (var i = start + 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
      final m = RegExp(r'^[ \t]+').firstMatch(line);
      if (m == null) break;
      indent = m.group(0);
      break;
    }
    if (indent == null) continue;
    for (var i = start + 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
      final currentIndent = RegExp(r'^[ \t]*').firstMatch(line)!.group(0)!;
      if (currentIndent.length < indent.length) break;
      if (currentIndent != indent) continue;
      final m = RegExp(r'''^[ \t]*["']?(\w+)["']?\s*:''').firstMatch(line);
      if (m != null && bomPluginNames.contains(m.group(1))) {
        declared.add(m.group(1)!);
      }
    }
  }
  return declared;
}

/// Reads the git refs of the pinned plugins from pubspec.lock.
Map<String, String> lockRefs({String? lockText}) {
  final lock = File('pubspec.lock');
  if (!lock.existsSync()) return {};
  final lines = (lockText ?? lock.readAsStringSync()).split('\n');
  final refs = <String, String>{};
  for (var i = 0; i < lines.length; i++) {
    // Strip a trailing CR so a CRLF lockfile still matches the anchored
    // `^  (\w+):$` header; otherwise the ref is silently dropped.
    final line = lines[i].replaceFirst(RegExp(r'\r$'), '');
    final m = RegExp(r'^  (\w+):$').firstMatch(line);
    if (m == null || !bomPluginNames.contains(m.group(1))) continue;
    for (var j = i + 1; j < lines.length && lines[j].startsWith('    '); j++) {
      final r = RegExp(r'resolved-ref: "?([0-9a-f]{40})"?')
          .firstMatch(lines[j]);
      if (r != null) refs[m.group(1)!] = r.group(1)!;
    }
  }
  return refs;
}
