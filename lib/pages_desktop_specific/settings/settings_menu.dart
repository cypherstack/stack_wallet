import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackduo/pages_desktop_specific/settings/settings_menu_item.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';

final selectedSettingsMenuItemStateProvider = StateProvider<int>((_) => 0);

class SettingsMenu extends ConsumerStatefulWidget {
  const SettingsMenu({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends ConsumerState<SettingsMenu> {
  final List<String> labels = [
    "Backup and restore",
    "Security",
    "Currency",
    "Language",
    "Nodes",
    "Syncing preferences",
    "Appearance",
    "Advanced",
  ];

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < labels.length; i++)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (i > 0)
                      const SizedBox(
                        height: 2,
                      ),
                    SettingsMenuItem<int>(
                      icon: SvgPicture.asset(
                        Assets.svg.polygon,
                        width: 11,
                        height: 11,
                        color: ref
                                    .watch(selectedSettingsMenuItemStateProvider
                                        .state)
                                    .state ==
                                i
                            ? Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorBlue
                            : Colors.transparent,
                      ),
                      label: labels[i],
                      value: i,
                      group: ref
                          .watch(selectedSettingsMenuItemStateProvider.state)
                          .state,
                      onChanged: (newValue) => ref
                          .read(selectedSettingsMenuItemStateProvider.state)
                          .state = newValue,
                    ),
                  ],
                )

              // SettingsMenuItem(
              //   icon: SvgPicture.asset(
              //     Assets.svg.polygon,
              //     width: 11,
              //     height: 11,
              //     color: selectedMenuItem == 0
              //         ? Theme.of(context)
              //             .extension<StackColors>()!
              //             .accentColorBlue
              //         : Colors.transparent,
              //   ),
              //   label: "Backup and restore",
              //   value: 0,
              //   group: selectedMenuItem,
              //   onChanged: updateSelectedMenuItem,
              // ),
              // const SizedBox(
              //   height: 2,
              // ),
              // SettingsMenuItem(
              //   icon: SvgPicture.asset(
              //     Assets.svg.polygon,
              //     width: 11,
              //     height: 11,
              //     color: selectedMenuItem == 1
              //         ? Theme.of(context)
              //             .extension<StackColors>()!
              //             .accentColorBlue
              //         : Colors.transparent,
              //   ),
              //   label: "Security",
              //   value: 1,
              //   group: selectedMenuItem,
              //   onChanged: updateSelectedMenuItem,
              // ),
              // const SizedBox(
              //   height: 2,
              // ),
              // SettingsMenuItem(
              //   icon: SvgPicture.asset(
              //     Assets.svg.polygon,
              //     width: 11,
              //     height: 11,
              //     color: selectedMenuItem == 2
              //         ? Theme.of(context)
              //             .extension<StackColors>()!
              //             .accentColorBlue
              //         : Colors.transparent,
              //   ),
              //   label: "Currency",
              //   value: 2,
              //   group: selectedMenuItem,
              //   onChanged: updateSelectedMenuItem,
              // ),
              // const SizedBox(
              //   height: 2,
              // ),
              // SettingsMenuItem(
              //   icon: SvgPicture.asset(
              //     Assets.svg.polygon,
              //     width: 11,
              //     height: 11,
              //     color: selectedMenuItem == 3
              //         ? Theme.of(context)
              //             .extension<StackColors>()!
              //             .accentColorBlue
              //         : Colors.transparent,
              //   ),
              //   label: "Language",
              //   value: 3,
              //   group: selectedMenuItem,
              //   onChanged: updateSelectedMenuItem,
              // ),
              // const SizedBox(
              //   height: 2,
              // ),
              // SettingsMenuItem(
              //   icon: SvgPicture.asset(
              //     Assets.svg.polygon,
              //     width: 11,
              //     height: 11,
              //     color: selectedMenuItem == 4
              //         ? Theme.of(context)
              //             .extension<StackColors>()!
              //             .accentColorBlue
              //         : Colors.transparent,
              //   ),
              //   label: "Nodes",
              //   value: 4,
              //   group: selectedMenuItem,
              //   onChanged: updateSelectedMenuItem,
              // ),
              // const SizedBox(
              //   height: 2,
              // ),
              // SettingsMenuItem(
              //   icon: SvgPicture.asset(
              //     Assets.svg.polygon,
              //     width: 11,
              //     height: 11,
              //     color: selectedMenuItem == 5
              //         ? Theme.of(context)
              //             .extension<StackColors>()!
              //             .accentColorBlue
              //         : Colors.transparent,
              //   ),
              //   label: "Syncing preferences",
              //   value: 5,
              //   group: selectedMenuItem,
              //   onChanged: updateSelectedMenuItem,
              // ),
              // const SizedBox(
              //   height: 2,
              // ),
              // SettingsMenuItem(
              //   icon: SvgPicture.asset(
              //     Assets.svg.polygon,
              //     width: 11,
              //     height: 11,
              //     color: selectedMenuItem == 6
              //         ? Theme.of(context)
              //             .extension<StackColors>()!
              //             .accentColorBlue
              //         : Colors.transparent,
              //   ),
              //   label: "Appearance",
              //   value: 6,
              //   group: selectedMenuItem,
              //   onChanged: updateSelectedMenuItem,
              // ),
              // const SizedBox(
              //   height: 2,
              // ),
              // SettingsMenuItem(
              //   icon: SvgPicture.asset(
              //     Assets.svg.polygon,
              //     width: 11,
              //     height: 11,
              //     color: selectedMenuItem == 7
              //         ? Theme.of(context)
              //             .extension<StackColors>()!
              //             .accentColorBlue
              //         : Colors.transparent,
              //   ),
              //   label: "Advanced",
              //   value: 7,
              //   group: selectedMenuItem,
              //   onChanged: updateSelectedMenuItem,
              // ),
            ],
          ),
        ),
      ],
    );
  }
}
