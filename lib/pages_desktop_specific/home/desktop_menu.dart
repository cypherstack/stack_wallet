import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/pages_desktop_specific/home/desktop_menu_item.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class DesktopMenu extends StatefulWidget {
  const DesktopMenu({Key? key}) : super(key: key);

  @override
  State<DesktopMenu> createState() => _DesktopMenuState();
}

class _DesktopMenuState extends State<DesktopMenu> {
  double _width = 225;
  int selectedMenuItem = 0;

  void updateSelectedMenuItem(int index) {
    setState(() {
      selectedMenuItem = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CFColors.popupBackground,
      child: SizedBox(
        width: _width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 22,
            ),
            SizedBox(
              width: 70,
              height: 70,
              child: SvgPicture.asset(
                Assets.svg.stackIcon,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              "Stack Wallet",
              style: STextStyles.desktopH2.copyWith(
                fontSize: 18,
                height: 23.4 / 18,
              ),
            ),
            const SizedBox(
              height: 60,
            ),
            SizedBox(
              width: _width - 32, // 16 padding on either side
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DesktopMenuItem(
                    icon: SvgPicture.asset(
                      Assets.svg.bell,
                      width: 20,
                      height: 20,
                    ),
                    label: "My Stack",
                    value: 0,
                    group: selectedMenuItem,
                    onChanged: updateSelectedMenuItem,
                  ),
                  DesktopMenuItem(
                    icon: SvgPicture.asset(
                      Assets.svg.bell,
                      width: 20,
                      height: 20,
                    ),
                    label: "Exchange",
                    value: 1,
                    group: selectedMenuItem,
                    onChanged: updateSelectedMenuItem,
                  ),
                  DesktopMenuItem(
                    icon: SvgPicture.asset(
                      Assets.svg.bell,
                      width: 20,
                      height: 20,
                    ),
                    label: "Notifications",
                    value: 2,
                    group: selectedMenuItem,
                    onChanged: updateSelectedMenuItem,
                  ),
                  DesktopMenuItem(
                    icon: SvgPicture.asset(
                      Assets.svg.bell,
                      width: 20,
                      height: 20,
                    ),
                    label: "Address Book",
                    value: 3,
                    group: selectedMenuItem,
                    onChanged: updateSelectedMenuItem,
                  ),
                  DesktopMenuItem(
                    icon: SvgPicture.asset(
                      Assets.svg.bell,
                      width: 20,
                      height: 20,
                    ),
                    label: "Settings",
                    value: 4,
                    group: selectedMenuItem,
                    onChanged: updateSelectedMenuItem,
                  ),
                  DesktopMenuItem(
                    icon: SvgPicture.asset(
                      Assets.svg.bell,
                      width: 20,
                      height: 20,
                    ),
                    label: "Support",
                    value: 5,
                    group: selectedMenuItem,
                    onChanged: updateSelectedMenuItem,
                  ),
                  DesktopMenuItem(
                    icon: SvgPicture.asset(
                      Assets.svg.bell,
                      width: 20,
                      height: 20,
                    ),
                    label: "About",
                    value: 6,
                    group: selectedMenuItem,
                    onChanged: updateSelectedMenuItem,
                  ),
                  DesktopMenuItem(
                    icon: SvgPicture.asset(
                      Assets.svg.bell,
                      width: 20,
                      height: 20,
                    ),
                    label: "Exit",
                    value: 7,
                    group: selectedMenuItem,
                    onChanged: updateSelectedMenuItem,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
