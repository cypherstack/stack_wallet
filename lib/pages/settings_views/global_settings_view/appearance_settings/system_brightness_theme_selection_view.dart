import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/appearance_settings/sub_widgets/theme_option.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:tuple/tuple.dart';

class SystemBrightnessThemeSelectionView extends ConsumerStatefulWidget {
  const SystemBrightnessThemeSelectionView({Key? key}) : super(key: key);

  static const String routeName = "/chooseSystemTheme";

  @override
  ConsumerState<SystemBrightnessThemeSelectionView> createState() =>
      _SystemBrightnessThemeSelectionViewState();
}

class _SystemBrightnessThemeSelectionViewState
    extends ConsumerState<SystemBrightnessThemeSelectionView> {
  List<Tuple2<String, String>> installedThemeIdNames = [];

  void _setTheme({
    required BuildContext context,
    required bool isDark,
    required String themeId,
    required WidgetRef ref,
  }) {
    final brightness = MediaQuery.of(context).platformBrightness;
    if (isDark) {
      ref.read(prefsChangeNotifierProvider).systemBrightnessDarkThemeId =
          themeId;
      if (brightness == Brightness.dark) {
        // apply theme
        ref.read(themeProvider.notifier).state =
            ref.read(pThemeService).getTheme(themeId: themeId)!;
      }
    } else {
      ref.read(prefsChangeNotifierProvider).systemBrightnessLightThemeId =
          themeId;
      if (brightness == Brightness.light) {
        // apply theme
        ref.read(themeProvider.notifier).state =
            ref.read(pThemeService).getTheme(themeId: themeId)!;
      }
    }
  }

  @override
  void initState() {
    installedThemeIdNames = ref
        .read(pThemeService)
        .installedThemes
        .map((e) => Tuple2(e.themeId, e.name))
        .toList();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
                                "Choose light mode theme",
                                style: STextStyles.titleBold12(context),
                              ),
                              const SizedBox(
                                height: 18,
                              ),
                              for (int i = 0;
                                  i < (2 * installedThemeIdNames.length) - 1;
                                  i++)
                                (i % 2 == 1)
                                    ? const SizedBox(
                                        height: 10,
                                      )
                                    : ThemeOption(
                                        label:
                                            installedThemeIdNames[i ~/ 2].item2,
                                        onPressed: () {
                                          _setTheme(
                                            context: context,
                                            isDark: false,
                                            themeId:
                                                installedThemeIdNames[i ~/ 2]
                                                    .item1,
                                            ref: ref,
                                          );
                                        },
                                        onChanged: (newValue) {
                                          final value =
                                              installedThemeIdNames[i ~/ 2]
                                                  .item1;
                                          if (newValue == value &&
                                              ref
                                                      .read(
                                                          prefsChangeNotifierProvider)
                                                      .systemBrightnessLightThemeId !=
                                                  value) {
                                            _setTheme(
                                              context: context,
                                              isDark: false,
                                              themeId: value,
                                              ref: ref,
                                            );
                                          }
                                        },
                                        value:
                                            installedThemeIdNames[i ~/ 2].item1,
                                        groupValue: ref.watch(
                                            prefsChangeNotifierProvider.select(
                                                (value) => value
                                                    .systemBrightnessLightThemeId)),
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
                                  i < (2 * installedThemeIdNames.length) - 1;
                                  i++)
                                (i % 2 == 1)
                                    ? const SizedBox(
                                        height: 10,
                                      )
                                    : ThemeOption(
                                        label:
                                            installedThemeIdNames[i ~/ 2].item2,
                                        onPressed: () {
                                          _setTheme(
                                            context: context,
                                            isDark: true,
                                            themeId:
                                                installedThemeIdNames[i ~/ 2]
                                                    .item1,
                                            ref: ref,
                                          );
                                        },
                                        onChanged: (newValue) {
                                          final value =
                                              installedThemeIdNames[i ~/ 2]
                                                  .item1;
                                          if (newValue == value &&
                                              ref
                                                      .read(
                                                          prefsChangeNotifierProvider)
                                                      .systemBrightnessDarkThemeId !=
                                                  value) {
                                            _setTheme(
                                              context: context,
                                              isDark: true,
                                              themeId: value,
                                              ref: ref,
                                            );
                                          }
                                        },
                                        value:
                                            installedThemeIdNames[i ~/ 2].item1,
                                        groupValue: ref.watch(
                                            prefsChangeNotifierProvider.select(
                                                (value) => value
                                                    .systemBrightnessDarkThemeId)),
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
