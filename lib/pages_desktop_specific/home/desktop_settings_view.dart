import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages_desktop_specific/home/settings_menu/backup_and_restore.dart';
import 'package:stackwallet/pages_desktop_specific/home/settings_menu/settings_menu.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';

class DesktopSettingsView extends ConsumerStatefulWidget {
  const DesktopSettingsView({Key? key}) : super(key: key);

  static const String routeName = "/desktopSettings";

  @override
  ConsumerState<DesktopSettingsView> createState() =>
      _DesktopSettingsViewState();
}

class _DesktopSettingsViewState extends ConsumerState<DesktopSettingsView> {
  int currentViewIndex = 0;
  final List<Widget> contentViews = [
    const Navigator(
      key: Key("settingsBackupRestoreDesktopKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: BackupRestore.routeName,
    ), //b+r
    Container(
      color: Colors.green,
    ), //security
    Container(
      color: Colors.red,
    ), //currency
    Container(
      color: Colors.orange,
    ), //language
    Container(
      color: Colors.yellow,
    ), //nodes
    Container(
      color: Colors.blue,
    ), //syncing prefs
    Container(
      color: Colors.pink,
    ), //appearance
    Container(
      color: Colors.purple,
    ), //advanced
  ];

  void onMenuSelectionChanged(int newIndex) {
    setState(() {
      currentViewIndex = newIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      background: Theme.of(context).extension<StackColors>()!.background,
      appBar: DesktopAppBar(
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
      body: Row(
        children: [
          SettingsMenu(
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
