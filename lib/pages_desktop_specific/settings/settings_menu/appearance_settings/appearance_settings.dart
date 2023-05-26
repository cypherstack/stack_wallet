import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages_desktop_specific/settings/settings_menu/appearance_settings/sub_widgets/desktop_manage_themes.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/draggable_switch_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:tuple/tuple.dart';

class AppearanceOptionSettings extends ConsumerStatefulWidget {
  const AppearanceOptionSettings({Key? key}) : super(key: key);

  static const String routeName = "/settingsMenuAppearance";

  @override
  ConsumerState<AppearanceOptionSettings> createState() =>
      _AppearanceOptionSettings();
}

class _AppearanceOptionSettings
    extends ConsumerState<AppearanceOptionSettings> {
  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return SingleChildScrollView(
        child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            right: 30,
          ),
          child: RoundedWhiteContainer(
            radiusMultiplier: 2,
            child: Wrap(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SvgPicture.asset(
                        Assets.svg.circleSun,
                        width: 48,
                        height: 48,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: RichText(
                            textAlign: TextAlign.left,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "Appearances",
                                  style: STextStyles.desktopTextSmall(context),
                                ),
                                TextSpan(
                                  text:
                                      "\n\nCustomize how your Stack Wallet looks according to your preferences.",
                                  style: STextStyles.desktopTextExtraExtraSmall(
                                      context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Divider(
                        thickness: 0.5,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Display favorite wallets",
                            style: STextStyles.desktopTextExtraSmall(context)
                                .copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textDark),
                            textAlign: TextAlign.left,
                          ),
                          SizedBox(
                            height: 20,
                            width: 40,
                            child: DraggableSwitchButton(
                              isOn: ref.watch(
                                prefsChangeNotifierProvider.select(
                                    (value) => value.showFavoriteWallets),
                              ),
                              onValueChanged: (newValue) {
                                ref
                                    .read(prefsChangeNotifierProvider)
                                    .showFavoriteWallets = newValue;
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Divider(
                        thickness: 0.5,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Choose theme",
                            style: STextStyles.desktopTextExtraSmall(context)
                                .copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textDark),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(2),
                      child: ThemeToggle(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ));
  }
}

class ThemeToggle extends ConsumerStatefulWidget {
  const ThemeToggle({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<ThemeToggle> createState() => _ThemeToggle();
}

class _ThemeToggle extends ConsumerState<ThemeToggle> {
  late final StreamSubscription<void> _subscription;
  late int _current;

  List<Tuple3<String, String, String>> installedThemeIdNames = [];

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
        .map((e) => Tuple3(e.themeId, e.name, e.assets.themeSelector))
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

  void _manageThemesPressed() {
    showDialog<void>(
      context: context,
      builder: (_) => const DesktopManageThemesDialog(),
    );
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
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (int i = 0; i < installedThemeIdNames.length; i++)
          Padding(
            key: Key("installedTheme_${installedThemeIdNames[i].item1}"),
            padding: const EdgeInsets.all(8.0),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  if (_current != i) {
                    setTheme(i);
                  }
                },
                child: Container(
                  width: 200,
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 2.5,
                            color: _current == i
                                ? Theme.of(context)
                                    .extension<StackColors>()!
                                    .infoItemIcons
                                : Theme.of(context)
                                    .extension<StackColors>()!
                                    .popupBG,
                          ),
                          borderRadius: BorderRadius.circular(
                            Constants.size.circularBorderRadius,
                          ),
                        ),
                        child: SvgPicture.file(
                          File(
                            installedThemeIdNames[i].item3,
                          ),
                          height: 160,
                          width: 200,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Radio(
                              activeColor: Theme.of(context)
                                  .extension<StackColors>()!
                                  .radioButtonIconEnabled,
                              value: i,
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
                          Text(
                            installedThemeIdNames[i].item2,
                            style: STextStyles.desktopTextExtraSmall(context)
                                .copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              width: 2.5,
              color: Theme.of(context).extension<StackColors>()!.popupBG,
            ),
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Semantics(
              label: "Manage themes",
              button: true,
              excludeSemantics: true,
              child: RawMaterialButton(
                onPressed: _manageThemesPressed,
                elevation: 0,
                focusElevation: 0,
                hoverElevation: 0,
                highlightElevation: 0,
                fillColor: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldActiveBG,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                child: Container(
                  color: Colors.transparent,
                  height: 160,
                  width: 200,
                  child: Center(
                    child: SvgPicture.asset(
                      Assets.svg.circlePlusFilled,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textSubtitle2,
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
