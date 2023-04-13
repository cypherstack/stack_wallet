import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/appearance_settings/sub_widgets/theme_option.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/providers/ui/color_theme_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

class ThemeOptionsWidget extends ConsumerWidget {
  const ThemeOptionsWidget({Key? key}) : super(key: key);

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
                    ref.read(prefsChangeNotifierProvider.notifier).theme =
                        ThemeType.values[i ~/ 2];
                    ref.read(colorThemeProvider.notifier).state =
                        StackColors.fromStackColorTheme(
                      ThemeType.values[i ~/ 2].colorTheme,
                    );
                    Assets.precache(context);
                  },
                  onChanged: (newValue) {
                    if (newValue == ThemeType.values[i ~/ 2]) {
                      ref.read(prefsChangeNotifierProvider.notifier).theme =
                          ThemeType.values[i ~/ 2];
                      ref.read(colorThemeProvider.notifier).state =
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
