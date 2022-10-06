import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages_desktop_specific/home/settings_menu_item.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
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
    // // TODO: implement build
    // throw UnimplementedError();
    debugPrint("BUILD: $runtimeType");

    return Material(
      color: Theme.of(context).extension<StackColors>()!.background,
      child: SizedBox(
        width: 300,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 10.0, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 20,
                // width: 300,
              ),
              Text(
                "Settings",
                style: STextStyles.desktopH3(context).copyWith(
                  fontSize: 24,
                ),
              ),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      3.0,
                      30.0,
                      55.0,
                      0,
                    ),
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
                          label: "Currency",
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
                          label: "Language",
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
                          label: "Nodes",
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
                          label: "Syncing preferences",
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
                          label: "Appearance",
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
                          label: "Advanced",
                          value: 0,
                          group: selectedMenuItem,
                          onChanged: updateSelectedMenuItem,
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
    );
  }
}
