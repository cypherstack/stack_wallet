import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/appearance_settings/sub_widgets/theme_option.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/appearance_settings/system_brightness_theme_selection_view.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:tuple/tuple.dart';

class ThemeOptionsWidget extends ConsumerStatefulWidget {
  const ThemeOptionsWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<ThemeOptionsWidget> createState() => _ThemeOptionsWidgetState();
}

class _ThemeOptionsWidgetState extends ConsumerState<ThemeOptionsWidget> {
  late final StreamSubscription<void> _subscription;
  late int _current;

  List<Tuple2<String, String>> installedThemeIdNames = [];

  int get systemDefault => installedThemeIdNames.length;

  void setTheme(int index) {
    if (index == _current) {
      return;
    }

    if (index == systemDefault) {
      // update current index
      _current = index;

      // enable system brightness setting
      ref.read(prefsChangeNotifierProvider).enableSystemBrightness = true;

      // get theme
      final String themeId;
      switch (MediaQuery.of(context).platformBrightness) {
        case Brightness.dark:
          themeId = ref
              .read(prefsChangeNotifierProvider.notifier)
              .systemBrightnessDarkThemeId;
          break;
        case Brightness.light:
          themeId = ref
              .read(prefsChangeNotifierProvider.notifier)
              .systemBrightnessLightThemeId;
          break;
      }

      // apply theme
      ref.read(themeProvider.notifier).state =
          ref.read(pThemeService).getTheme(themeId: themeId)!;

      // Assets.precache(context);
    } else {
      if (_current == systemDefault) {
        // disable system brightness setting
        ref.read(prefsChangeNotifierProvider).enableSystemBrightness = false;
      }

      // update current index
      _current = index;

      // get theme
      final themeId = installedThemeIdNames[index].item1;

      // save theme setting
      ref.read(prefsChangeNotifierProvider.notifier).themeId = themeId;

      // apply theme
      ref.read(themeProvider.notifier).state =
          ref.read(pThemeService).getTheme(themeId: themeId)!;

      // Assets.precache(context);
    }
  }

  void _updateInstalledList() {
    installedThemeIdNames = ref
        .read(pThemeService)
        .installedThemes
        .map((e) => Tuple2(e.themeId, e.name))
        .toList();

    if (ref.read(prefsChangeNotifierProvider).enableSystemBrightness) {
      _current = installedThemeIdNames.length;
    } else {
      final themeId = ref.read(prefsChangeNotifierProvider).themeId;

      for (int i = 0; i < installedThemeIdNames.length; i++) {
        if (installedThemeIdNames[i].item1 == themeId) {
          _current = i;
          break;
        }
      }
    }
  }

  @override
  void initState() {
    _updateInstalledList();

    _subscription =
        ref.read(mainDBProvider).isar.stackThemes.watchLazy().listen((_) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _updateInstalledList();
          });
        });
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MaterialButton(
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          padding: const EdgeInsets.all(0),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
          ),
          onPressed: () {
            // setTheme(systemDefault);
          },
          child: SizedBox(
            width: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 26,
                      child: Radio(
                        activeColor: Theme.of(context)
                            .extension<StackColors>()!
                            .radioButtonIconEnabled,
                        value: installedThemeIdNames.length,
                        groupValue: _current,
                        onChanged: (newValue) {
                          if (newValue is int) {
                            setTheme(newValue);
                          }
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 14,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "System default",
                          style: STextStyles.desktopTextExtraSmall(context)
                              .copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark2,
                          ),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        CustomTextButton(
                          text: "Options",
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              SystemBrightnessThemeSelectionView.routeName,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        for (int i = 0; i < installedThemeIdNames.length; i++)
          ConditionalParent(
            key: Key("installedTheme_${installedThemeIdNames[i].item1}"),
            condition: i > 0,
            builder: (child) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: child,
            ),
            child: ThemeOption(
              label: installedThemeIdNames[i].item2,
              onPressed: () {
                setTheme(i);
              },
              onChanged: (newValue) {
                if (newValue is int) {
                  setTheme(newValue);
                }
              },
              value: i,
              groupValue: _current,
            ),
          ),
      ],
    );
  }
}
