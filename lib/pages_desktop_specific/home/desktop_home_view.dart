import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicmobile/pages_desktop_specific/home/address_book_view/desktop_address_book.dart';
import 'package:epicmobile/pages_desktop_specific/home/desktop_menu.dart';
import 'package:epicmobile/pages_desktop_specific/home/desktop_settings_view.dart';
import 'package:epicmobile/pages_desktop_specific/home/my_stack_view/my_stack_view.dart';
import 'package:epicmobile/pages_desktop_specific/home/support_and_about_view/desktop_about_view.dart';
import 'package:epicmobile/pages_desktop_specific/home/support_and_about_view/desktop_support_view.dart';
import 'package:epicmobile/route_generator.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';

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
      key: Key("desktopStackHomeKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: MyStackView.routeName,
    ),
    Container(
      color: Colors.green,
    ),
    Container(
      color: Colors.red,
    ),
    const Navigator(
      key: Key("desktopAddressBookHomeKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: DesktopAddressBook.routeName,
    ),
    const Navigator(
      key: Key("desktopSettingHomeKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: DesktopSettingsView.routeName,
    ),
    const Navigator(
      key: Key("desktopSupportHomeKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: DesktopSupportView.routeName,
    ),
    const Navigator(
      key: Key("desktopAboutHomeKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: DesktopAboutView.routeName,
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
          Container(
            width: 1,
            color: Theme.of(context).extension<StackColors>()!.background,
          ),
          Expanded(
            child: contentViews[currentViewIndex],
          ),
        ],
      ),
    );
  }
}
