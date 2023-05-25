import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/show_loading.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/animated_text.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class StackThemeCard extends ConsumerStatefulWidget {
  const StackThemeCard({
    Key? key,
    required this.data,
  }) : super(key: key);

  final StackThemeMetaData data;

  @override
  ConsumerState<StackThemeCard> createState() => _StackThemeCardState();
}

class _StackThemeCardState extends ConsumerState<StackThemeCard> {
  final isDesktop = Util.isDesktop;
  late final StreamSubscription<void> _subscription;

  late bool _hasTheme;
  bool _needsUpdate = false;
  String? _cachedSize;

  Future<bool> _downloadAndInstall() async {
    final service = ref.read(pThemeService);

    try {
      final data = await service.fetchTheme(
        themeMetaData: widget.data,
      );

      await service.install(themeArchiveData: data);
      return true;
    } catch (e, s) {
      Logging.instance.log(
        "Failed _downloadAndInstall of ${widget.data.id}: $e\n$s",
        level: LogLevel.Warning,
      );
      return false;
    }
  }

  Future<void> _downloadPressed() async {
    final result = await showLoading(
      whileFuture: _downloadAndInstall(),
      context: context,
      message: "Downloading and installing theme...",
    );

    if (mounted) {
      final message = result
          ? "${widget.data.name} theme installed!"
          : "Failed to install ${widget.data.name} theme";
      if (isDesktop) {
        await showFloatingFlushBar(
          type: result ? FlushBarType.success : FlushBarType.warning,
          message: message,
          context: context,
        );
      } else {
        await showDialog<void>(
          context: context,
          builder: (_) => StackOkDialog(
            title: message,
            onOkPressed: (_) {
              setState(() {
                _needsUpdate = !result;
                _hasTheme = result;
              });
            },
          ),
        );
      }
    }
  }

  Future<void> _uninstallThemePressed() async {
    await ref.read(pThemeService).remove(themeId: widget.data.id);
    if (mounted) {
      await showFloatingFlushBar(
        type: FlushBarType.success,
        message: "${widget.data.name} uninstalled",
        context: context,
      );
    }
  }

  bool get themeIsInUse {
    final prefs = ref.read(prefsChangeNotifierProvider);
    final themeId = widget.data.id;

    return prefs.themeId == themeId ||
        prefs.systemBrightnessDarkThemeId == themeId ||
        prefs.systemBrightnessLightThemeId == themeId;
  }

  Future<String> getThemeDirectorySize() async {
    final themesDir = await StackFileSystem.applicationThemesDirectory();
    final themeDir = Directory("${themesDir.path}/${widget.data.id}");
    int bytes = 0;
    if (await themeDir.exists()) {
      await for (FileSystemEntity entity in themeDir.list(recursive: true)) {
        if (entity is File) {
          bytes += await entity.length();
        }
      }
    } else if (widget.data.size.isNotEmpty) {
      return widget.data.size;
    }

    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1048576) {
      double kbSize = bytes / 1024;
      return '${kbSize.toStringAsFixed(2)} KB';
    } else if (bytes < 1073741824) {
      double mbSize = bytes / 1048576;
      return '${mbSize.toStringAsFixed(2)} MB';
    } else {
      double gbSize = bytes / 1073741824;
      return '${gbSize.toStringAsFixed(2)} GB';
    }
  }

  StackTheme? getInstalled() => ref
      .read(mainDBProvider)
      .isar
      .stackThemes
      .where()
      .themeIdEqualTo(widget.data.id)
      .findFirstSync();

  @override
  void initState() {
    final installedTheme = getInstalled();
    _hasTheme = installedTheme != null;
    if (_hasTheme) {
      _needsUpdate = widget.data.version > (installedTheme?.version ?? 0);
    }

    _subscription = ref
        .read(mainDBProvider)
        .isar
        .stackThemes
        .watchLazy()
        .listen((event) async {
      final installedTheme = getInstalled();
      final hasTheme = installedTheme != null;
      if (_hasTheme != hasTheme && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          setState(() {
            _hasTheme = hasTheme;
            if (hasTheme) {
              _needsUpdate =
                  widget.data.version > (installedTheme.version ?? 0);
            }
          });
        });
      }
    });

    _subscription.resume();
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      radiusMultiplier: isDesktop ? 2.5 : 1,
      borderColor: isDesktop
          ? Theme.of(context).extension<StackColors>()!.textSubtitle6
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
            ),
            child: widget.data.previewImageUrl.isNotEmpty
                ? AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.network(
                        widget.data.previewImageUrl,
                      ),
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final themePreview = ref
                              .watch(pThemeService)
                              .getTheme(themeId: widget.data.id)
                              ?.assets
                              .themePreview ??
                          "";

                      return (themePreview.endsWith(".png"))
                          ? Image.file(
                              File(
                                themePreview,
                              ),
                              height: 100,
                            )
                          : SvgPicture.file(
                              File(
                                themePreview,
                              ),
                              height: 100,
                            );
                    },
                  ),
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            widget.data.name,
            style: STextStyles.itemSubtitle12(context),
          ),
          const SizedBox(
            height: 6,
          ),
          FutureBuilder(
            future: getThemeDirectorySize(),
            builder: (
              context,
              AsyncSnapshot<String> snapshot,
            ) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                _cachedSize = snapshot.data;
              }
              if (_cachedSize == null) {
                return AnimatedText(
                  stringsToLoopThrough: const [
                    "Calculating size   ",
                    "Calculating size.  ",
                    "Calculating size.. ",
                    "Calculating size...",
                  ],
                  style: STextStyles.label(context),
                );
              } else {
                return Text(
                  _cachedSize!,
                  style: STextStyles.label(context),
                );
              }
            },
          ),
          if (_hasTheme && _needsUpdate)
            const SizedBox(
              height: 12,
            ),
          if (_hasTheme && _needsUpdate)
            PrimaryButton(
              label: "Update",
              buttonHeight: isDesktop ? ButtonHeight.s : ButtonHeight.l,
              onPressed: _downloadPressed,
            ),
          const SizedBox(
            height: 12,
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _hasTheme
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: PrimaryButton(
              label: "Download",
              buttonHeight: isDesktop ? ButtonHeight.s : ButtonHeight.l,
              onPressed: _downloadPressed,
            ),
            secondChild: SecondaryButton(
              label: themeIsInUse ? "Theme is active" : "Remove",
              enabled: !themeIsInUse,
              buttonHeight: isDesktop ? ButtonHeight.s : ButtonHeight.l,
              onPressed: _uninstallThemePressed,
            ),
          ),
        ],
      ),
    );
  }
}
