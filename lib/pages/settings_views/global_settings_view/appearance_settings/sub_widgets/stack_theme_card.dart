import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/show_loading.dart';
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
  late final StreamSubscription<void> _subscription;

  late bool _hasTheme;

  Future<bool> _downloadAndInstall() async {
    final service = ref.read(pThemeService);

    try {
      final data = await service.fetchTheme(
        themeMetaData: widget.data,
      );

      await service.install(themeArchive: data);
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
      await showDialog<void>(
        context: context,
        builder: (_) => StackOkDialog(
          title: message,
          onOkPressed: (_) {
            setState(() {
              _hasTheme = result;
            });
          },
        ),
      );
    }
  }

  Future<void> _uninstallThemePressed() async {
    await ref.read(pThemeService).remove(themeId: widget.data.id);
  }

  bool get themeIsInUse {
    final prefs = ref.read(prefsChangeNotifierProvider);
    final themeId = widget.data.id;

    return prefs.themeId == themeId ||
        prefs.systemBrightnessDarkThemeId == themeId ||
        prefs.systemBrightnessLightThemeId == themeId;
  }

  @override
  void initState() {
    _hasTheme = ref
            .read(mainDBProvider)
            .isar
            .stackThemes
            .where()
            .themeIdEqualTo(widget.data.id)
            .countSync() >
        0;

    _subscription = ref
        .read(mainDBProvider)
        .isar
        .stackThemes
        .watchLazy()
        .listen((event) async {
      final hasTheme = (await ref
              .read(mainDBProvider)
              .isar
              .stackThemes
              .where()
              .themeIdEqualTo(widget.data.id)
              .count()) >
          0;
      if (_hasTheme != hasTheme && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          setState(() {
            _hasTheme = hasTheme;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.network(
                  widget.data.previewImageUrl,
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            widget.data.name,
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            widget.data.size,
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
              buttonHeight: ButtonHeight.l,
              onPressed: _downloadPressed,
            ),
            secondChild: SecondaryButton(
              label: themeIsInUse ? "Theme is active" : "Remove from device",
              enabled: !themeIsInUse,
              buttonHeight: ButtonHeight.l,
              onPressed: _uninstallThemePressed,
            ),
          ),
        ],
      ),
    );
  }
}
