import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/ui/color_theme_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
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
                    // const Padding(
                    //   padding: EdgeInsets.all(10.0),
                    //   child: Divider(
                    //     thickness: 0.5,
                    //   ),
                    // ),
                    // Padding(
                    //   padding: const EdgeInsets.all(10.0),
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //     children: [
                    //       Text(
                    //         "System brightness",
                    //         style: STextStyles.desktopTextExtraSmall(context)
                    //             .copyWith(
                    //                 color: Theme.of(context)
                    //                     .extension<StackColors>()!
                    //                     .textDark),
                    //         textAlign: TextAlign.left,
                    //       ),
                    //       SizedBox(
                    //         height: 20,
                    //         width: 40,
                    //         child: DraggableSwitchButton(
                    //           isOn: ref.watch(
                    //             prefsChangeNotifierProvider.select(
                    //                 (value) => value.enableSystemBrightness),
                    //           ),
                    //           onValueChanged: (newValue) {
                    //             ref
                    //                 .read(prefsChangeNotifierProvider)
                    //                 .enableSystemBrightness = newValue;
                    //           },
                    //         ),
                    //       )
                    //     ],
                    //   ),
                    // ),
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
  String assetNameFor(ThemeType type) {
    switch (type) {
      case ThemeType.light:
        return Assets.svg.themeLight;
      case ThemeType.dark:
        return Assets.svg.themeDark;
      case ThemeType.darkChans:
        return Assets.svg.themeDarkChan;
      case ThemeType.oceanBreeze:
        return Assets.svg.themeOcean;
      case ThemeType.oledBlack:
        return Assets.svg.themeOledBlack;
      case ThemeType.orange:
        return Assets.svg.orange;
      case ThemeType.fruitSorbet:
        return Assets.svg.themeFruit;
      case ThemeType.forest:
        return Assets.svg.themeForest;
      case ThemeType.chan:
        return Assets.svg.themeChan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (int i = 0; i < ThemeType.values.length; i++)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  if (ref.read(colorThemeProvider.notifier).state.themeType !=
                      ThemeType.values[i]) {
                    ref.read(prefsChangeNotifierProvider.notifier).theme =
                        ThemeType.values[i];

                    ref.read(colorThemeProvider.notifier).state =
                        StackColors.fromStackColorTheme(
                            ThemeType.values[i].colorTheme);
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
                            color: ref
                                        .read(colorThemeProvider.notifier)
                                        .state
                                        .themeType ==
                                    ThemeType.values[i]
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
                        child: SvgPicture.asset(
                          assetNameFor(ThemeType.values[i]),
                          height: 160,
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
                            child: Radio<ThemeType>(
                              activeColor: Theme.of(context)
                                  .extension<StackColors>()!
                                  .radioButtonIconEnabled,
                              value: ThemeType.values[i],
                              groupValue: ref
                                  .read(colorThemeProvider.state)
                                  .state
                                  .themeType,
                              onChanged: (_) {},
                            ),
                          ),
                          const SizedBox(
                            width: 14,
                          ),
                          Text(
                            ThemeType.values[i].prettyName,
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
          )
      ],
    );
  }
}
