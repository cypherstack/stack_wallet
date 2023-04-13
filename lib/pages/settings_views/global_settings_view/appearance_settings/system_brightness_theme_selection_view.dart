import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/appearance_settings/sub_widgets/theme_option.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/ui/color_theme_provider.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class SystemBrightnessThemeSelectionView extends ConsumerWidget {
  const SystemBrightnessThemeSelectionView({
    Key? key,
  }) : super(key: key);

  static const String routeName = "/chooseSystemTheme";

  void _setTheme({
    required BuildContext context,
    required bool isDark,
    required ThemeType type,
    required WidgetRef ref,
  }) {
    final brightness = MediaQuery.of(context).platformBrightness;
    if (isDark) {
      ref.read(prefsChangeNotifierProvider).systemBrightnessDarkTheme = type;
      if (brightness == Brightness.dark) {
        ref.read(colorThemeProvider.notifier).state =
            StackColors.fromStackColorTheme(
          type.colorTheme,
        );
      }
    } else {
      ref.read(prefsChangeNotifierProvider).systemBrightnessLightTheme = type;
      if (brightness == Brightness.light) {
        ref.read(colorThemeProvider.notifier).state =
            StackColors.fromStackColorTheme(
          type.colorTheme,
        );
      }
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
            "System default theme",
            style: STextStyles.navBarTitle(context),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(
                          height: 16,
                        ),
                        RoundedWhiteContainer(
                          child: Text(
                            "Select a light and dark theme that will be"
                            " activated automatically when your phone system"
                            " switches light and dark mode.",
                            style: STextStyles.smallMed12(context),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        RoundedWhiteContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Choose dark mode theme",
                                style: STextStyles.titleBold12(context),
                              ),
                              const SizedBox(
                                height: 18,
                              ),
                              for (int i = 0;
                                  i < (2 * ThemeType.values.length) - 1;
                                  i++)
                                (i % 2 == 1)
                                    ? const SizedBox(
                                        height: 10,
                                      )
                                    : ThemeOption(
                                        label:
                                            ThemeType.values[i ~/ 2].prettyName,
                                        onPressed: () {
                                          _setTheme(
                                            context: context,
                                            isDark: false,
                                            type: ThemeType.values[i ~/ 2],
                                            ref: ref,
                                          );
                                        },
                                        onChanged: (newValue) {
                                          final value =
                                              ThemeType.values[i ~/ 2];
                                          if (newValue == value &&
                                              ref
                                                      .read(
                                                          prefsChangeNotifierProvider)
                                                      .systemBrightnessLightTheme !=
                                                  value) {
                                            _setTheme(
                                              context: context,
                                              isDark: false,
                                              type: value,
                                              ref: ref,
                                            );
                                          }
                                        },
                                        value: ThemeType.values[i ~/ 2],
                                        groupValue: ref.watch(
                                            prefsChangeNotifierProvider.select(
                                                (value) => value
                                                    .systemBrightnessLightTheme)),
                                      ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        RoundedWhiteContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Choose dark mode theme",
                                style: STextStyles.titleBold12(context),
                              ),
                              const SizedBox(
                                height: 18,
                              ),
                              for (int i = 0;
                                  i < (2 * ThemeType.values.length) - 1;
                                  i++)
                                (i % 2 == 1)
                                    ? const SizedBox(
                                        height: 10,
                                      )
                                    : ThemeOption(
                                        label:
                                            ThemeType.values[i ~/ 2].prettyName,
                                        onPressed: () {
                                          _setTheme(
                                            context: context,
                                            isDark: true,
                                            type: ThemeType.values[i ~/ 2],
                                            ref: ref,
                                          );
                                        },
                                        onChanged: (newValue) {
                                          final value =
                                              ThemeType.values[i ~/ 2];
                                          if (newValue == value &&
                                              ref
                                                      .read(
                                                          prefsChangeNotifierProvider)
                                                      .systemBrightnessDarkTheme !=
                                                  value) {
                                            _setTheme(
                                              context: context,
                                              isDark: true,
                                              type: value,
                                              ref: ref,
                                            );
                                          }
                                        },
                                        value: ThemeType.values[i ~/ 2],
                                        groupValue: ref.watch(
                                            prefsChangeNotifierProvider.select(
                                                (value) => value
                                                    .systemBrightnessDarkTheme)),
                                      ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
