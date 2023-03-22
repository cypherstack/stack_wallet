import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/providers/ui/color_theme_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/draggable_switch_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class AppearanceSettingsView extends ConsumerWidget {
  const AppearanceSettingsView({Key? key}) : super(key: key);

  static const String routeName = "/appearanceSettings";

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

class ThemeOptionsView extends ConsumerWidget {
  const ThemeOptionsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        for (int i = 0; i < (2 * ThemeType.values.length) - 1; i++)
          (i % 2 == 1)
              ? const SizedBox(
                  height: 10,
                )
              : ThemeOption(
                  onPressed: () {
                    DB.instance.put<dynamic>(
                      boxName: DB.boxNameTheme,
                      key: "colorScheme",
                      value: ThemeType.values[i ~/ 2].name,
                    );
                    ref.read(colorThemeProvider.state).state =
                        StackColors.fromStackColorTheme(
                      ThemeType.values[i ~/ 2].colorTheme,
                    );
                    Assets.precache(context);
                  },
                  onChanged: (newValue) {
                    if (newValue == ThemeType.values[i ~/ 2]) {
                      DB.instance.put<dynamic>(
                        boxName: DB.boxNameTheme,
                        key: "colorScheme",
                        value: ThemeType.values[i ~/ 2].name,
                      );
                      ref.read(colorThemeProvider.state).state =
                          StackColors.fromStackColorTheme(
                        ThemeType.values[i ~/ 2].colorTheme,
                      );
                      Assets.precache(context);
                    }
                  },
                  value: ThemeType.values[i ~/ 2],
                  groupValue:
                      Theme.of(context).extension<StackColors>()!.themeType,
                ),
      ],
    );
  }
}

class ThemeOption extends StatelessWidget {
  const ThemeOption(
      {Key? key,
      required this.onPressed,
      required this.onChanged,
      required this.value,
      required this.groupValue})
      : super(key: key);

  final VoidCallback onPressed;
  final void Function(Object?) onChanged;
  final ThemeType value;
  final ThemeType groupValue;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      padding: const EdgeInsets.all(0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          Constants.size.circularBorderRadius,
        ),
      ),
      onPressed: onPressed,
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
                    value: value,
                    groupValue: groupValue,
                    onChanged: onChanged,
                  ),
                ),
                const SizedBox(
                  width: 14,
                ),
                Text(
                  value.prettyName,
                  style: STextStyles.desktopTextExtraSmall(context).copyWith(
                    color:
                        Theme.of(context).extension<StackColors>()!.textDark2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
