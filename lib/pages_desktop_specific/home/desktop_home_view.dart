import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages_desktop_specific/home/desktop_menu.dart';
import 'package:stackwallet/pages_desktop_specific/home/my_stack_view/my_stack_view.dart';
import 'package:stackwallet/pages_desktop_specific/home/settings_menu/settings_menu.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

class DesktopHomeView extends ConsumerStatefulWidget {
  const DesktopHomeView({Key? key}) : super(key: key);

  static const String routeName = "/desktopHome";

  @override
  ConsumerState<DesktopHomeView> createState() => _DesktopHomeViewState();
}

class _DesktopHomeViewState extends ConsumerState<DesktopHomeView> {
  int currentViewIndex = 0;
  final List<Widget> contentViews = [
    const Navigator(
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: MyStackView.routeName,
    ),
    Container(
      color: Colors.green,
    ),
    Container(
      color: Colors.red,
    ),
    Container(
      color: Colors.orange,
    ),
    const Navigator(
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: SettingsMenu.routeName,
    ),
    Container(
      color: Colors.blue,
    ),
    Container(
      color: Colors.pink,
    ),
    Container(
      color: Colors.purple,
    ),
  ];

  void onMenuSelectionChanged(int newIndex) {
    setState(() {
      currentViewIndex = newIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).extension<StackColors>()!.background,
      child: Row(
        children: [
          DesktopMenu(
            onSelectionChanged: onMenuSelectionChanged,
          ),
          Expanded(
            child: contentViews[currentViewIndex],
          ),
        ],
      ),
    );
  }
}
