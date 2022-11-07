import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/ui/color_theme_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
import 'package:stackwallet/utilities/theme/dark_colors.dart';
import 'package:stackwallet/utilities/theme/light_colors.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/draggable_switch_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class AppearanceOptionSettings extends ConsumerStatefulWidget {
  const AppearanceOptionSettings({Key? key}) : super(key: key);

  static const String routeName = "/settingsMenuAppearance";

  @override
  ConsumerState<AppearanceOptionSettings> createState() =>
      _AppearanceOptionSettings();
}

class _AppearanceOptionSettings
    extends ConsumerState<AppearanceOptionSettings> {
  // late bool isLight;

  // @override
  // void initState() {
  //
  //   super.initState();
  // }
  //
  // @override
  // void dispose() {
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            right: 30,
          ),
          child: RoundedWhiteContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  Assets.svg.circleSun,
                  width: 48,
                  height: 48,
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
                            prefsChangeNotifierProvider
                                .select((value) => value.showFavoriteWallets),
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
                  padding: EdgeInsets.all(10),
                  child: ThemeToggle(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ThemeToggle extends ConsumerStatefulWidget {
  const ThemeToggle({
    Key? key,
  }) : super(key: key);

  // final bool externalCallsEnabled;
  // final void Function(bool)? onChanged;

  @override
  ConsumerState<ThemeToggle> createState() => _ThemeToggle();
}

class _ThemeToggle extends ConsumerState<ThemeToggle> {
  // late bool externalCallsEnabled;

  late String _selectedTheme;

  @override
  void initState() {
    _selectedTheme =
        DB.instance.get<dynamic>(boxName: DB.boxNameTheme, key: "colorScheme")
                as String? ??
            "light";

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
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
            DB.instance.put<dynamic>(
              boxName: DB.boxNameTheme,
              key: "colorScheme",
              value: ThemeType.light.name,
            );
            ref.read(colorThemeProvider.state).state =
                StackColors.fromStackColorTheme(
              LightColors(),
            );

            setState(() {
              _selectedTheme = "light";
            });
          },
          child: SizedBox(
            width: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 2.5,
                      color: _selectedTheme == "light"
                          ? Theme.of(context)
                              .extension<StackColors>()!
                              .infoItemIcons
                          : Theme.of(context).extension<StackColors>()!.popupBG,
                    ),
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                  ),
                  child: SvgPicture.asset(
                    Assets.svg.themeLight,
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
                        value: "light",
                        groupValue: _selectedTheme,
                        onChanged: (newValue) {
                          if (newValue is String && newValue == "light") {
                            DB.instance.put<dynamic>(
                              boxName: DB.boxNameTheme,
                              key: "colorScheme",
                              value: ThemeType.light.name,
                            );
                            ref.read(colorThemeProvider.state).state =
                                StackColors.fromStackColorTheme(
                              LightColors(),
                            );

                            setState(() {
                              _selectedTheme = "light";
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 14,
                    ),
                    Text(
                      "Light",
                      style:
                          STextStyles.desktopTextExtraSmall(context).copyWith(
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
        const SizedBox(
          width: 20,
        ),
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
            DB.instance.put<dynamic>(
              boxName: DB.boxNameTheme,
              key: "colorScheme",
              value: ThemeType.dark.name,
            );
            ref.read(colorThemeProvider.state).state =
                StackColors.fromStackColorTheme(
              DarkColors(),
            );

            setState(() {
              _selectedTheme = "dark";
            });
          },
          child: SizedBox(
            width: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 2.5,
                      color: _selectedTheme == "dark"
                          ? Theme.of(context)
                              .extension<StackColors>()!
                              .infoItemIcons
                          : Theme.of(context).extension<StackColors>()!.popupBG,
                    ),
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                  ),
                  child: SvgPicture.asset(
                    Assets.svg.themeDark,
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
                        value: "dark",
                        groupValue: _selectedTheme,
                        onChanged: (newValue) {
                          if (newValue is String && newValue == "dark") {
                            DB.instance.put<dynamic>(
                              boxName: DB.boxNameTheme,
                              key: "colorScheme",
                              value: ThemeType.dark.name,
                            );
                            ref.read(colorThemeProvider.state).state =
                                StackColors.fromStackColorTheme(
                              DarkColors(),
                            );

                            setState(() {
                              _selectedTheme = "dark";
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 14,
                    ),
                    Text(
                      "Dark",
                      style:
                          STextStyles.desktopTextExtraSmall(context).copyWith(
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
      ],
    );
  }
}
