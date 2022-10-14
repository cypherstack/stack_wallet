import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages_desktop_specific/home/settings_menu_item.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';

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
      children: [
        DesktopAppBar(
          isCompactHeight: true,
          leading: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
              ),
              Text(
                "Settings",
                style: STextStyles.desktopH3(context),
              )
            ],
          ),
        ),
        Column(
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
        ),
      ],
    );
  }
}
