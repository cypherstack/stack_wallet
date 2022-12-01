import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages_desktop_specific/settings/settings_menu_item.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

class SettingsMenu extends ConsumerStatefulWidget {
  const SettingsMenu({
    Key? key,
    required this.onSelectionChanged,
  }) : super(key: key);

  final void Function(int)?
      onSelectionChanged; //is a function that takes in an int and returns void/.;

  static const String routeName = "/settingsMenu";

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends ConsumerState<SettingsMenu> {
  int selectedMenuItem = 0;

  void updateSelectedMenuItem(int index) {
    setState(() {
      selectedMenuItem = index;
    });
    widget.onSelectionChanged?.call(index);
  }

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
              SettingsMenuItem(
                icon: SvgPicture.asset(
                  Assets.svg.polygon,
                  width: 11,
                  height: 11,
                  color: selectedMenuItem == 0
                      ? Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorBlue
                      : Colors.transparent,
                ),
                label: "Backup and restore",
                value: 0,
                group: selectedMenuItem,
                onChanged: updateSelectedMenuItem,
              ),
              const SizedBox(
                height: 2,
              ),
              SettingsMenuItem(
                icon: SvgPicture.asset(
                  Assets.svg.polygon,
                  width: 11,
                  height: 11,
                  color: selectedMenuItem == 1
                      ? Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorBlue
                      : Colors.transparent,
                ),
                label: "Security",
                value: 1,
                group: selectedMenuItem,
                onChanged: updateSelectedMenuItem,
              ),
              const SizedBox(
                height: 2,
              ),
              SettingsMenuItem(
                icon: SvgPicture.asset(
                  Assets.svg.polygon,
                  width: 11,
                  height: 11,
                  color: selectedMenuItem == 2
                      ? Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorBlue
                      : Colors.transparent,
                ),
                label: "Currency",
                value: 2,
                group: selectedMenuItem,
                onChanged: updateSelectedMenuItem,
              ),
              const SizedBox(
                height: 2,
              ),
              SettingsMenuItem(
                icon: SvgPicture.asset(
                  Assets.svg.polygon,
                  width: 11,
                  height: 11,
                  color: selectedMenuItem == 3
                      ? Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorBlue
                      : Colors.transparent,
                ),
                label: "Language",
                value: 3,
                group: selectedMenuItem,
                onChanged: updateSelectedMenuItem,
              ),
              const SizedBox(
                height: 2,
              ),
              SettingsMenuItem(
                icon: SvgPicture.asset(
                  Assets.svg.polygon,
                  width: 11,
                  height: 11,
                  color: selectedMenuItem == 4
                      ? Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorBlue
                      : Colors.transparent,
                ),
                label: "Nodes",
                value: 4,
                group: selectedMenuItem,
                onChanged: updateSelectedMenuItem,
              ),
              const SizedBox(
                height: 2,
              ),
              SettingsMenuItem(
                icon: SvgPicture.asset(
                  Assets.svg.polygon,
                  width: 11,
                  height: 11,
                  color: selectedMenuItem == 5
                      ? Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorBlue
                      : Colors.transparent,
                ),
                label: "Syncing preferences",
                value: 5,
                group: selectedMenuItem,
                onChanged: updateSelectedMenuItem,
              ),
              const SizedBox(
                height: 2,
              ),
              SettingsMenuItem(
                icon: SvgPicture.asset(
                  Assets.svg.polygon,
                  width: 11,
                  height: 11,
                  color: selectedMenuItem == 6
                      ? Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorBlue
                      : Colors.transparent,
                ),
                label: "Appearance",
                value: 6,
                group: selectedMenuItem,
                onChanged: updateSelectedMenuItem,
              ),
              const SizedBox(
                height: 2,
              ),
              SettingsMenuItem(
                icon: SvgPicture.asset(
                  Assets.svg.polygon,
                  width: 11,
                  height: 11,
                  color: selectedMenuItem == 7
                      ? Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorBlue
                      : Colors.transparent,
                ),
                label: "Advanced",
                value: 7,
                group: selectedMenuItem,
                onChanged: updateSelectedMenuItem,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
