import 'dart:io';

import 'package:test/test.dart';

void main() {
  final project = Directory.current;
  late Directory fixture;

  void run(String executable, List<String> args, {Map<String, String>? env}) {
    final result = Process.runSync(
      executable,
      args,
      workingDirectory: fixture.path,
      environment: env,
      includeParentEnvironment: env == null,
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  }

  setUpAll(() {
    fixture = Directory.systemTemp.createTempSync('stack-simulator-config-');
    Directory('${fixture.path}/tool/wl_templates').createSync(recursive: true);
    Directory('${fixture.path}/lib/wl_gen/generated')
        .createSync(recursive: true);
    for (final name in ['process_pubspec_deps.dart', 'gen_interfaces.dart']) {
      File('${project.path}/tool/$name').copySync('${fixture.path}/tool/$name');
    }
    for (final template in Directory(
      '${project.path}/tool/wl_templates',
    ).listSync().whereType<File>()) {
      template.copySync(
        '${fixture.path}/tool/wl_templates/${template.uri.pathSegments.last}',
      );
    }
    // The real configure scripts record git's revision in generated app config.
    // Give the isolated fixture its own revision; never modify the checkout.
    run('git', ['-C', fixture.path, 'init', '--quiet']);
    run('git', [
      '-C',
      fixture.path,
      '-c',
      'user.name=Config Test',
      '-c',
      'user.email=config-test@example.invalid',
      '-c',
      'commit.gpgsign=false',
      '-c',
      'core.hooksPath=/dev/null',
      'commit',
      '--allow-empty',
      '--quiet',
      '-m',
      'Configuration fixture',
    ]);
  });

  tearDownAll(() => fixture.deleteSync(recursive: true));

  for (final app in ['stack_wallet', 'stack_duo']) {
    for (final scenario in <({String platform, String? flag})>[
      (platform: 'ios', flag: null),
      (platform: 'ios', flag: '0'),
      (platform: 'ios', flag: '1'),
      (platform: 'android', flag: '1'),
      (platform: 'macos', flag: '1'),
      (platform: 'linux', flag: '1'),
    ]) {
      test('$app ${scenario.platform} '
          'simulator=${scenario.flag ?? "unset"}', () {
        final pubspec = File('${fixture.path}/pubspec.yaml');
        File(
          '${project.path}/scripts/app_config/templates/pubspec.template.yaml',
        ).copySync(pubspec.path);
        final env = Map<String, String>.from(Platform.environment)
          ..remove('STACK_IOS_SIMULATOR')
          ..['APP_PROJECT_ROOT_DIR'] = fixture.path;
        if (scenario.flag != null) env['STACK_IOS_SIMULATOR'] = scenario.flag!;
        run('bash', [
          '${project.path}/scripts/app_config/configure_$app.sh',
          scenario.platform,
        ], env: env);

        final generated = pubspec.readAsStringSync();
        final simulator = scenario.platform == 'ios' && scenario.flag == '1';
        final overrides = generated.split('dependency_overrides:').last;
        bool enabled(String package) =>
            RegExp('^  $package:', multiLine: true).hasMatch(overrides);
        expect(enabled('cs_monero_flutter_libs_ios'), simulator);
        expect(
          enabled('cs_wownero_flutter_libs_ios'),
          simulator && app == 'stack_wallet',
        );
        expect(
          enabled('flutter_mwebd'),
          isFalse,
          reason:
              'simulator configuration must not downgrade '
              'the native-assets MWEB package',
        );
        expect(
          File('${fixture.path}/lib/app_config.g.dart').existsSync(),
          isTrue,
        );
      });
    }
  }
}
