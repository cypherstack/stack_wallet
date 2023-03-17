import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/providers/ui/color_theme_provider.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
import 'package:stackwallet/utilities/theme/dark_colors.dart';
import 'package:stackwallet/utilities/theme/forest_colors.dart';
import 'package:stackwallet/utilities/theme/fruit_sorbet_colors.dart';
import 'package:stackwallet/utilities/theme/light_colors.dart';
import 'package:stackwallet/utilities/theme/ocean_breeze_colors.dart';
import 'package:stackwallet/utilities/theme/oled_black_colors.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/draggable_switch_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class AppearanceSettingsView extends ConsumerWidget {
  const AppearanceSettingsView({Key? key}) : super(key: key);

  static const String routeName = "/appearanceSettings";

  String chooseThemeType(ThemeType type) {
    switch (type) {
      case ThemeType.light:
        return "Light theme";
      case ThemeType.chan:
        return "Chan theme";
      case ThemeType.dark:
        return "Dark theme";
      case ThemeType.oceanBreeze:
        return "Ocean theme";
      case ThemeType.oledBlack:
        return "Oled Black theme";
      case ThemeType.fruitSorbet:
        return "Fruit Sorbet theme";
      case ThemeType.forest:
        return "Forest theme";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () async {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            "Appearance",
            style: STextStyles.navBarTitle(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RoundedWhiteContainer(
                          child: Consumer(
                            builder: (_, ref, __) {
                              return RawMaterialButton(
                                splashColor: Theme.of(context)
                                    .extension<StackColors>()!
                                    .highlight,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    Constants.size.circularBorderRadius,
                                  ),
                                ),
                                onPressed: null,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Display favorite wallets",
                                        style: STextStyles.titleBold12(context),
                                        textAlign: TextAlign.left,
                                      ),
                                      SizedBox(
                                        height: 20,
                                        width: 40,
                                        child: DraggableSwitchButton(
                                          isOn: ref.watch(
                                            prefsChangeNotifierProvider.select(
                                                (value) =>
                                                    value.showFavoriteWallets),
                                          ),
                                          onValueChanged: (newValue) {
                                            ref
                                                .read(
                                                    prefsChangeNotifierProvider)
                                                .showFavoriteWallets = newValue;
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        RoundedWhiteContainer(
                          padding: const EdgeInsets.all(0),
                          child: RawMaterialButton(
                            // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
                            padding: const EdgeInsets.all(0),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                Constants.size.circularBorderRadius,
                              ),
                            ),
                            onPressed: null,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Choose Theme",
                                        style: STextStyles.titleBold12(context),
                                        textAlign: TextAlign.left,
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: ThemeOptionsView(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ThemeOptionsView extends ConsumerStatefulWidget {
  const ThemeOptionsView({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<ThemeOptionsView> createState() => _ThemeOptionsView();
}

class _ThemeOptionsView extends ConsumerState<ThemeOptionsView> {
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
                Row(
                  children: [
                    SizedBox(
                      width: 10,
                      height: 10,
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
                            .textDark2,
                      ),
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
                Row(
                  children: [
                    SizedBox(
                      width: 10,
                      height: 10,
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
                            .textDark2,
                      ),
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
              value: ThemeType.oceanBreeze.name,
            );
            ref.read(colorThemeProvider.state).state =
                StackColors.fromStackColorTheme(
              OceanBreezeColors(),
            );

            setState(() {
              _selectedTheme = "oceanBreeze";
            });
          },
          child: SizedBox(
            width: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: Radio(
                        activeColor: Theme.of(context)
                            .extension<StackColors>()!
                            .radioButtonIconEnabled,
                        value: "oceanBreeze",
                        groupValue: _selectedTheme,
                        onChanged: (newValue) {
                          if (newValue is String && newValue == "oceanBreeze") {
                            DB.instance.put<dynamic>(
                              boxName: DB.boxNameTheme,
                              key: "colorScheme",
                              value: ThemeType.oceanBreeze.name,
                            );
                            ref.read(colorThemeProvider.state).state =
                                StackColors.fromStackColorTheme(
                              OceanBreezeColors(),
                            );

                            setState(() {
                              _selectedTheme = "oceanBreeze";
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 14,
                    ),
                    Text(
                      "Ocean Breeze",
                      style:
                          STextStyles.desktopTextExtraSmall(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textDark2,
                      ),
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
              value: ThemeType.oledBlack.name,
            );
            ref.read(colorThemeProvider.state).state =
                StackColors.fromStackColorTheme(
              OledBlackColors(),
            );

            setState(() {
              _selectedTheme = "oledBlack";
            });
          },
          child: SizedBox(
            width: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: Radio(
                        activeColor: Theme.of(context)
                            .extension<StackColors>()!
                            .radioButtonIconEnabled,
                        value: "oledBlack",
                        groupValue: _selectedTheme,
                        onChanged: (newValue) {
                          if (newValue is String && newValue == "oledBlack") {
                            DB.instance.put<dynamic>(
                              boxName: DB.boxNameTheme,
                              key: "colorScheme",
                              value: ThemeType.oledBlack.name,
                            );
                            ref.read(colorThemeProvider.state).state =
                                StackColors.fromStackColorTheme(
                              OledBlackColors(),
                            );

                            setState(() {
                              _selectedTheme = "oledBlack";
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 14,
                    ),
                    Text(
                      "OLED Black",
                      style:
                          STextStyles.desktopTextExtraSmall(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textDark2,
                      ),
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
              value: ThemeType.fruitSorbet.name,
            );
            ref.read(colorThemeProvider.state).state =
                StackColors.fromStackColorTheme(
              FruitSorbetColors(),
            );

            setState(() {
              _selectedTheme = "fruitSorbet";
            });
          },
          child: SizedBox(
            width: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: Radio(
                        activeColor: Theme.of(context)
                            .extension<StackColors>()!
                            .radioButtonIconEnabled,
                        value: "fruitSorbet",
                        groupValue: _selectedTheme,
                        onChanged: (newValue) {
                          if (newValue is String && newValue == "fruitSorbet") {
                            DB.instance.put<dynamic>(
                              boxName: DB.boxNameTheme,
                              key: "colorScheme",
                              value: ThemeType.fruitSorbet.name,
                            );
                            ref.read(colorThemeProvider.state).state =
                                StackColors.fromStackColorTheme(
                              FruitSorbetColors(),
                            );

                            setState(() {
                              _selectedTheme = "fruitSorbet";
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 14,
                    ),
                    Text(
                      "Fruit Sorbet",
                      style:
                          STextStyles.desktopTextExtraSmall(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textDark2,
                      ),
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
              value: ThemeType.forest.name,
            );
            ref.read(colorThemeProvider.state).state =
                StackColors.fromStackColorTheme(
              ForestColors(),
            );

            setState(() {
              _selectedTheme = "forest";
            });
          },
          child: SizedBox(
            width: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: Radio(
                        activeColor: Theme.of(context)
                            .extension<StackColors>()!
                            .radioButtonIconEnabled,
                        value: "forest",
                        groupValue: _selectedTheme,
                        onChanged: (newValue) {
                          if (newValue is String && newValue == "forest") {
                            DB.instance.put<dynamic>(
                              boxName: DB.boxNameTheme,
                              key: "colorScheme",
                              value: ThemeType.forest.name,
                            );
                            ref.read(colorThemeProvider.state).state =
                                StackColors.fromStackColorTheme(
                              ForestColors(),
                            );

                            setState(() {
                              _selectedTheme = "forest";
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 14,
                    ),
                    Text(
                      "Forest",
                      style:
                          STextStyles.desktopTextExtraSmall(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textDark2,
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
