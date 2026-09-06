import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:stack_wallet_branding/adapter.dart';
import 'package:whitelabel/whitelabel.dart';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption('brand', help: 'stack_wallet, stack_duo, or campfire')
    ..addOption('manifest', abbr: 'm')
    ..addOption('project', abbr: 'p')
    ..addOption('version', abbr: 'v')
    ..addOption('build-number', abbr: 'b')
    ..addOption('revision')
    ..addOption('flavor')
    ..addOption('mwebd-sha256')
    ..addMultiOption(
      'platforms',
      help: 'Explicit comma-separated native platforms',
    )
    ..addFlag('diff', negatable: false)
    ..addFlag('json', negatable: false)
    ..addFlag('recover', negatable: false)
    ..addFlag(
      'prebuilts',
      negatable: false,
      help: 'Use CI prebuilt native assets through hooks user_defines',
    )
    ..addFlag('overwrite', negatable: false)
    ..addFlag('apply', negatable: false)
    ..addFlag('help', abbr: 'h', negatable: false);
  try {
    final args = parser.parse(arguments);
    if (args['help'] as bool) {
      stdout.writeln(
        'Preview by default. Supply --brand, --platforms, --version, and --build-number.',
      );
      stdout.writeln(parser.usage);
      return;
    }
    if (args.rest.isNotEmpty) {
      throw ArgumentError('Unexpected positional arguments');
    }
    if (args['diff'] as bool && args['json'] as bool) {
      throw ArgumentError('Select either --diff or --json');
    }
    final project =
        args['project'] as String? ??
        Directory.fromUri(Platform.script.resolve('../../../')).path;
    if (args['recover'] as bool) {
      if (args.options.any(
        (option) =>
            args.wasParsed(option) &&
            option != 'recover' &&
            option != 'project',
      )) {
        throw ArgumentError('--recover accepts only --project');
      }
      recoverConfiguration(project);
      stdout.writeln('Recovery complete.');
      return;
    }
    String requiredValue(String key) {
      final value = args[key] as String?;
      if (value == null || value.isEmpty) throw ArgumentError('Missing --$key');
      return value;
    }

    final name = args['brand'] as String?;
    final suppliedManifest = args['manifest'] as String?;
    if ((name == null) == (suppliedManifest == null)) {
      throw ArgumentError('Supply exactly one of --brand or --manifest');
    }
    if (name != null &&
        !['stack_wallet', 'stack_duo', 'campfire'].contains(name)) {
      throw ArgumentError('Unknown brand: $name');
    }
    final brand = StackWalletManifest.load(
      suppliedManifest ??
          File.fromUri(Platform.script.resolve('../brands/$name.yaml')).path,
    );
    final plan = planStackWallet(
      projectRoot: project,
      brand: brand,
      version: requiredValue('version'),
      buildNumber: requiredValue('build-number'),
      platforms: (args['platforms'] as List<String>).toSet(),
      revision: args['revision'] as String?,
      buildFlavor: args['flavor'] as String? ?? brand.brand,
      windowsMwebdSha256: args['mwebd-sha256'] as String?,
      nativePrebuilts: args['prebuilts'] as bool,
      overwrite: args['overwrite'] as bool,
    );
    if (args['json'] as bool) {
      stdout.writeln(jsonEncode(plan.toJson()));
    } else {
      for (final change in plan.changes.where(
        (change) => change.action != 'unchanged',
      )) {
        stdout.writeln(
          args['diff'] as bool
              ? change.diff
              : '${change.action.toUpperCase()} ${change.path}',
        );
      }
    }
    if (args['apply'] as bool) {
      plan.apply();
      if (!(args['json'] as bool)) {
        stdout.writeln(
          'Configured ${brand.brand}; build with --flavor ${brand.brand}.',
        );
      }
    } else if (!(args['json'] as bool)) {
      stdout.writeln('Plan ready; use --apply to write it.');
    }
  } catch (error) {
    stderr.writeln('error: $error');
    exitCode = 1;
  }
}
