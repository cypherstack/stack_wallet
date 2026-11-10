import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as path;

import '../app_config.dart';
import '../db/hive/db.dart';
import '../db/isar/main_db.dart';
import '../db/sqlite/firo_cache.dart';
import '../models/isar/stack_theme.dart';
import '../pages/already_running_view.dart';
import '../themes/stack_colors.dart';
import '../themes/stack_theme_data.dart';
import '../themes/theme_providers.dart';
import '../themes/theme_service.dart';
import '../widgets/desktop/primary_button.dart';
import '../widgets/desktop/secondary_button.dart';
import 'stack_file_system.dart';
import 'text_styles.dart';

abstract final class DesktopStartupAndReset {
  static const _dataDirectories = <String>[
    'isar',
    'wallets',
    'epiccash',
    'mimblewimblecoin',
    'xelis',
    'drift',
    'sqlite',
    'mwebd',
    'themes',
    'hive',
  ];

  // Keep this file and its handle until exit, including while deleting Hive.
  static RandomAccessFile? _instanceLock;
  static final Map<String, Future<_BundledAppearance>> _bundledAppearances = {};
  static StackTheme? _displayTheme;

  /// Run before opening Hive, Isar, or caches on desktop.
  static Future<bool> prepareForStartup() async {
    try {
      await _acquireInstanceLock();
    } on FileSystemException catch (e) {
      if (isLockConflict(e)) {
        await showAlreadyRunning();
        return false;
      }
      rethrow;
    }

    if (!await isPending()) return true;
    await askToFinishReset();
    await showMessage('Resetting ${AppConfig.appName}...');
    try {
      await deleteData();
      await clearPending();
    } catch (e, s) {
      debugPrint('Desktop reset failed: $e\n$s');
      await showMessage(
        'Could not delete all ${AppConfig.appName} data.\n'
        'Close any program using it and reopen the app.',
      );
      return false;
    }
    return true;
  }

  static bool isLockConflict(FileSystemException e) =>
      e.osError?.errorCode == 11 || e.message.contains('lock failed');

  static Future<void> _acquireInstanceLock() async {
    final root = await StackFileSystem.applicationRootDirectory();
    _instanceLock = await File(path.join(root.path, '.instance.lock'))
        .open(mode: FileMode.append);
    await _instanceLock!.lock();
  }

  static Future<File> _marker() async => File(
    path.join(
      (await StackFileSystem.applicationRootDirectory()).path,
      '.reset-pending',
    ),
  );

  /// Never infer from password files that an unfinished reset was cancelled.
  static Future<bool> isPending() async {
    return (await _marker()).exists();
  }

  static Future<void> clearPending() async {
    final marker = await _marker();
    if (await marker.exists()) await marker.delete();
  }

  // Only called from the login reset flow, before wallets are loaded.
  // The caller must exit afterwards, even if closing or deleting fails.
  static Future<void> resetBeforeExit() async {
    // Stays behind if the reset does not finish, so the next launch can ask.
    await (await _marker()).writeAsString('reset', flush: true);

    await _deleteKeys();
    await FiroCacheCoordinator.close();
    await DB.instance.hive.close();
    for (final name in Isar.instanceNames.toList()) {
      final isar = Isar.getInstance(name);
      if (isar != null && !await isar.close()) {
        throw StateError('Could not close Isar database $name');
      }
    }
    await deleteData();
    await clearPending();
  }

  static Future<void> deleteData() async {
    final root = await StackFileSystem.applicationRootDirectory();
    // Only app-owned paths: the root may be a custom -d directory or the
    // iPad Library directory. Leave backups, exports, logs and the lock alone.
    // tor/ is kept: it only holds Tor network state, and a running Tor client
    // keeps files there open.
    await _deleteKeys();
    for (final name in _dataDirectories) {
      await _deleteExceptSwb(Directory(path.join(root.path, name)));
    }
  }

  static Future<void> _deleteExceptSwb(FileSystemEntity entity) async {
    final type = await FileSystemEntity.type(entity.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return;

    if (type == FileSystemEntityType.directory) {
      final directory = Directory(entity.path);
      await for (final child in directory.list(followLinks: false)) {
        await _deleteExceptSwb(child);
      }
      if (await directory.list(followLinks: false).isEmpty) {
        await directory.delete();
      }
    } else if (!entity.path.toLowerCase().endsWith('.swb')) {
      // Delete links themselves, never the files or directories they target.
      if (type == FileSystemEntityType.link) {
        await Link(entity.path).delete();
      } else {
        await File(entity.path).delete();
      }
    }
  }

  // The password, then the secure storage holding the wallet keys. Deleted
  // first, so a reset is permanent once it starts. Neither is open before
  // login.
  static Future<void> _deleteKeys() async {
    final root = (await StackFileSystem.applicationRootDirectory()).path;
    for (final file in [
      // Hive restores .hivec if .hive is missing. Remove it first so a crash
      // cannot resurrect the password after deleting .hive.
      for (final ext in ['hivec', 'hive', 'lock'])
        File(path.join(root, 'hive', 'desktopdata.$ext')),
      for (final ext in ['isar', 'isar-lck', 'isar.lock'])
        File(path.join(root, 'isar', 'desktopStore.$ext')),
    ]) {
      if (await file.exists()) await file.delete();
    }
  }

  static Future<void> askToFinishReset() async {
    final done = Completer<void>();
    await _show(
      title: 'Unfinished reset',
      message:
          'A reset of ${AppConfig.appName} did not finish. Continuing will '
          'delete current wallet data and settings, including anything '
          'created since the reset began. Files ending in .swb will be kept.',
      primaryAction: (
        label: 'Retry deleting',
        onPressed: () {
          if (!done.isCompleted) done.complete();
        },
      ),
      secondaryAction: (label: 'Quit', onPressed: () => exit(0)),
    );
    return done.future;
  }

  static Future<void> showMessage(String message, {StackTheme? theme}) =>
      _show(title: AppConfig.appName, message: message, theme: theme);

  static Future<void> showAlreadyRunning() async {
    try {
      await StackFileSystem.initThemesDir();
      await MainDB.instance.initMainDB();
      ThemeService.instance.init(MainDB.instance);
      final theme = ThemeService.instance.getTheme(themeId: 'light');
      if (theme == null) throw StateError('Default theme is unavailable');
      _showScreen(const AlreadyRunningView(), theme);
    } catch (_) {
      await _show(
        title: AppConfig.appName,
        message: 'is already running.\nClose the other window and try again.',
      );
    }
  }

  static Future<void> _show({
    required String title,
    required String message,
    ({String label, VoidCallback onPressed})? primaryAction,
    ({String label, VoidCallback onPressed})? secondaryAction,
    StackTheme? theme,
  }) async {
    final screenTheme =
        theme ?? _displayTheme ?? (await _bundledAppearance('light')).theme;
    final logoTheme =
        screenTheme.brightness == Brightness.dark &&
            AppConfig.hasFeature(AppFeature.themeSelection)
        ? 'dark'
        : 'light';
    final appearance = await _bundledAppearance(logoTheme);
    _showScreen(
      _DesktopStatusView(
        title: title,
        message: message,
        logo: appearance.logo,
        logoIsPng: appearance.logoIsPng,
        primaryAction: primaryAction,
        secondaryAction: secondaryAction,
      ),
      screenTheme,
    );
  }

  static Future<_BundledAppearance> _bundledAppearance(String name) =>
      _bundledAppearances.putIfAbsent(name, () => _loadBundledAppearance(name));

  static Future<_BundledAppearance> _loadBundledAppearance(String name) async {
    final data = await rootBundle.load('assets/default_themes/$name.zip');
    final archive = ZipDecoder().decodeBytes(data.buffer.asUint8List());
    final themeJson = archive.files.singleWhere(
      (file) => file.name == 'theme.json',
    );
    final json = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(themeJson.content as List<int>)) as Map,
    );
    final logoPath =
        'assets/${(json['assets'] as Map)['stack_icon'] as String}';
    final logo = archive.files.singleWhere((file) => file.name == logoPath);
    return _BundledAppearance(
      theme: StackTheme.fromJson(json: json),
      logo: Uint8List.fromList(logo.content as List<int>),
      logoIsPng: logoPath.toLowerCase().endsWith('.png'),
    );
  }

  static void _showScreen(Widget home, StackTheme theme) {
    _displayTheme = theme;
    runApp(
      KeyedSubtree(
        // Dispose the normal ProviderScope before its databases are closed.
        key: UniqueKey(),
        child: ProviderScope(
          overrides: [
            themeProvider.overrideWithProvider(
              StateProvider<StackTheme>((ref) => theme),
            ),
          ],
          child: _DesktopAppShell(home: home),
        ),
      ),
    );
  }
}

class _DesktopAppShell extends ConsumerWidget {
  const _DesktopAppShell({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = ref.watch(colorProvider.state).state;
    return MaterialApp(
      title: AppConfig.appName,
      theme: stackThemeData(colorScheme),
      home: home,
    );
  }
}

class _BundledAppearance {
  const _BundledAppearance({
    required this.theme,
    required this.logo,
    required this.logoIsPng,
  });

  final StackTheme theme;
  final Uint8List logo;
  final bool logoIsPng;
}

class _DesktopStatusView extends StatelessWidget {
  const _DesktopStatusView({
    required this.title,
    required this.message,
    required this.logo,
    required this.logoIsPng,
    this.primaryAction,
    this.secondaryAction,
  });

  final String title;
  final String message;
  final Uint8List logo;
  final bool logoIsPng;
  final ({String label, VoidCallback onPressed})? primaryAction;
  final ({String label, VoidCallback onPressed})? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<StackColors>()!;
    return Material(
      color: colors.background,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          gradient: colors.gradientBackground,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: SizedBox(
                    width: 480,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: logoIsPng
                              ? Image.memory(logo, fit: BoxFit.contain)
                              : SvgPicture.memory(logo, fit: BoxFit.contain),
                        ),
                        const SizedBox(height: 42),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: STextStyles.desktopH1(context),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: STextStyles.desktopTextSmall(context)
                              .copyWith(color: colors.textSubtitle1),
                        ),
                        if (primaryAction != null) ...[
                          const SizedBox(height: 48),
                          PrimaryButton(
                            label: primaryAction!.label,
                            onPressed: primaryAction!.onPressed,
                          ),
                        ],
                        if (secondaryAction != null) ...[
                          const SizedBox(height: 24),
                          SecondaryButton(
                            label: secondaryAction!.label,
                            onPressed: secondaryAction!.onPressed,
                          ),
                        ],
                        if (primaryAction != null || secondaryAction != null)
                          const SizedBox(height: 96),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
