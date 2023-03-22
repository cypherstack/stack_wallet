import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackduo/providers/providers.dart';
import 'package:stackduo/providers/ui/color_theme_provider.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/color_theme.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/widgets/background.dart';
import 'package:stackduo/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackduo/widgets/custom_buttons/draggable_switch_button.dart';
import 'package:stackduo/widgets/expandable.dart';
import 'package:stackduo/widgets/rounded_container.dart';
import 'package:stackduo/widgets/rounded_white_container.dart';
import 'package:tuple/tuple.dart';

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
                        const SystemBrightnessToggle(),
                        if (!ref.watch(
                          prefsChangeNotifierProvider
                              .select((value) => value.enableSystemBrightness),
                        ))
                          const SizedBox(
                            height: 10,
                          ),
                        if (!ref.watch(
                          prefsChangeNotifierProvider
                              .select((value) => value.enableSystemBrightness),
                        ))
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
                                          style:
                                              STextStyles.titleBold12(context),
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

class SystemBrightnessToggle extends ConsumerStatefulWidget {
  const SystemBrightnessToggle({Key? key}) : super(key: key);

  @override
  ConsumerState<SystemBrightnessToggle> createState() =>
      _SystemBrightnessToggleState();
}

class _SystemBrightnessToggleState
    extends ConsumerState<SystemBrightnessToggle> {
  final controller = ExpandableController();

  void _toggle(bool enable) {
    ref.read(prefsChangeNotifierProvider).enableSystemBrightness = enable;

    if (enable && controller.state == ExpandableState.collapsed) {
      controller.toggle?.call();
    } else if (!enable && controller.state == ExpandableState.expanded) {
      controller.toggle?.call();
    }

    if (enable) {
      final ThemeType type;
      switch (MediaQuery.of(context).platformBrightness) {
        case Brightness.dark:
          type = ref
              .read(prefsChangeNotifierProvider.notifier)
              .systemBrightnessDarkTheme;
          break;
        case Brightness.light:
          type = ref
              .read(prefsChangeNotifierProvider.notifier)
              .systemBrightnessLightTheme;
          break;
      }
      ref.read(colorThemeProvider.notifier).state =
          StackColors.fromStackColorTheme(
        type.colorTheme,
      );
    } else {
      ref.read(prefsChangeNotifierProvider.notifier).theme =
          ref.read(colorThemeProvider.notifier).state.themeType;
    }
  }

  @override
  void initState() {
    if (ref.read(prefsChangeNotifierProvider).enableSystemBrightness) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.toggle?.call();
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final enable = ref.watch(
      prefsChangeNotifierProvider
          .select((value) => value.enableSystemBrightness),
    );

    return RoundedWhiteContainer(
      child: Expandable(
        controller: controller,
        expandOverride: () {
          _toggle(
              !ref.read(prefsChangeNotifierProvider).enableSystemBrightness);
        },
        header: RawMaterialButton(
          splashColor: Theme.of(context).extension<StackColors>()!.highlight,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
          ),
          onPressed: null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "System brightness",
                  style: STextStyles.titleBold12(context),
                  textAlign: TextAlign.left,
                ),
                SizedBox(
                  key: Key("${enable}enableSystemBrightnessToggleKey"),
                  height: 20,
                  width: 40,
                  child: DraggableSwitchButton(
                    isOn: enable,
                    onValueChanged: _toggle,
                  ),
                )
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            RoundedContainer(
              color: Colors.transparent,
              padding: EdgeInsets.zero,
              onPressed: () async {
                final result = await Navigator.of(context).pushNamed(
                  SystemBrightnessThemeSelectionView.routeName,
                  arguments: Tuple2(
                      "light",
                      ref
                          .read(prefsChangeNotifierProvider)
                          .systemBrightnessLightTheme),
                );
                if (result is ThemeType) {
                  ref
                      .read(prefsChangeNotifierProvider)
                      .systemBrightnessLightTheme = result;
                  if (ref
                      .read(prefsChangeNotifierProvider)
                      .enableSystemBrightness) {
                    if (mounted &&
                        MediaQuery.of(context).platformBrightness ==
                            Brightness.light) {
                      ref.read(colorThemeProvider.notifier).state =
                          StackColors.fromStackColorTheme(result.colorTheme);
                    }
                  }
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Light theme",
                          style: STextStyles.itemSubtitle(context),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Text(
                          ref
                              .watch(
                                prefsChangeNotifierProvider.select((value) =>
                                    value.systemBrightnessLightTheme),
                              )
                              .prettyName,
                          style: STextStyles.itemSubtitle12(context),
                        ),
                      ],
                    ),
                  ),
                  SvgPicture.asset(
                    Assets.svg.chevronRight,
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                ],
              ),
            ),
            RoundedContainer(
              color: Colors.transparent,
              padding: EdgeInsets.zero,
              onPressed: () async {
                final result = await Navigator.of(context).pushNamed(
                  SystemBrightnessThemeSelectionView.routeName,
                  arguments: Tuple2(
                      "dark",
                      ref
                          .read(prefsChangeNotifierProvider)
                          .systemBrightnessDarkTheme),
                );
                if (result is ThemeType) {
                  ref
                      .read(prefsChangeNotifierProvider)
                      .systemBrightnessDarkTheme = result;
                  if (ref
                      .read(prefsChangeNotifierProvider)
                      .enableSystemBrightness) {
                    if (mounted &&
                        MediaQuery.of(context).platformBrightness ==
                            Brightness.dark) {
                      ref.read(colorThemeProvider.notifier).state =
                          StackColors.fromStackColorTheme(result.colorTheme);
                    }
                  }
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dark theme",
                          style: STextStyles.itemSubtitle(context),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Text(
                          ref.watch(
                            prefsChangeNotifierProvider.select((value) =>
                                value.systemBrightnessDarkTheme.prettyName),
                          ),
                          style: STextStyles.itemSubtitle12(context),
                        ),
                      ],
                    ),
                  ),
                  SvgPicture.asset(
                    Assets.svg.chevronRight,
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                ],
              ),
            )
          ],
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

class SystemBrightnessThemeSelectionView extends StatelessWidget {
  const SystemBrightnessThemeSelectionView({
    Key? key,
    required this.brightness,
    required this.current,
  }) : super(key: key);

  final String brightness;
  final ThemeType current;

  static const String routeName = "/chooseSystemTheme";

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
            "Choose $brightness theme",
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
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          children: [
                                            for (int i = 0;
                                                i <
                                                    (2 *
                                                            ThemeType.values
                                                                .length) -
                                                        1;
                                                i++)
                                              (i % 2 == 1)
                                                  ? const SizedBox(
                                                      height: 10,
                                                    )
                                                  : ThemeOption(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop(ThemeType
                                                                    .values[
                                                                i ~/ 2]);
                                                      },
                                                      onChanged: (newValue) {
                                                        if (newValue ==
                                                            ThemeType.values[
                                                                i ~/ 2]) {
                                                          Navigator.of(context)
                                                              .pop(ThemeType
                                                                      .values[
                                                                  i ~/ 2]);
                                                        }
                                                      },
                                                      value: ThemeType
                                                          .values[i ~/ 2],
                                                      groupValue: current,
                                                    ),
                                          ],
                                        ),
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
