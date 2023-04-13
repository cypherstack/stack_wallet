import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/appearance_settings/sub_widgets/theme_option.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/appearance_settings/system_brightness_theme_selection_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/providers/ui/color_theme_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';

class ThemeOptionsWidget extends ConsumerStatefulWidget {
  const ThemeOptionsWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<ThemeOptionsWidget> createState() => _ThemeOptionsWidgetState();
}

class _ThemeOptionsWidgetState extends ConsumerState<ThemeOptionsWidget> {
  final systemDefault = ThemeType.values.length;
  late int _current;

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
      final ThemeType theme;
      switch (MediaQuery.of(context).platformBrightness) {
        case Brightness.dark:
          theme = ref
              .read(prefsChangeNotifierProvider.notifier)
              .systemBrightnessDarkTheme;
          break;
        case Brightness.light:
          theme = ref
              .read(prefsChangeNotifierProvider.notifier)
              .systemBrightnessLightTheme;
          break;
      }

      // apply theme
      ref.read(colorThemeProvider.notifier).state =
          StackColors.fromStackColorTheme(
        theme.colorTheme,
      );

      Assets.precache(context);
    } else {
      if (_current == systemDefault) {
        // disable system brightness setting
        ref.read(prefsChangeNotifierProvider).enableSystemBrightness = false;
      }

      // update current index
      _current = index;

      // get theme
      final theme = ThemeType.values[index];

      // save theme setting
      ref.read(prefsChangeNotifierProvider.notifier).theme = theme;

      // apply theme
      ref.read(colorThemeProvider.notifier).state =
          StackColors.fromStackColorTheme(
        theme.colorTheme,
      );

      Assets.precache(context);
    }
  }

  @override
  void initState() {
    if (ref.read(prefsChangeNotifierProvider).enableSystemBrightness) {
      _current = ThemeType.values.length;
    } else {
      _current =
          ThemeType.values.indexOf(ref.read(prefsChangeNotifierProvider).theme);
    }

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
            setTheme(systemDefault);
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
                        value: ThemeType.values.length,
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
        for (int i = 0; i < ThemeType.values.length; i++)
          ConditionalParent(
            condition: i > 0,
            builder: (child) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: child,
            ),
            child: ThemeOption(
              label: ThemeType.values[i].prettyName,
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
