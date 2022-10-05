import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsMenu extends ConsumerStatefulWidget {
  const SettingsMenu({Key? key}) : super(key: key);

  static const String routeName = "/settingsMenu";

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends ConsumerState<SettingsMenu> {
  @override
  Widget build(BuildContext context) {
    // // TODO: implement build
    // throw UnimplementedError();
    debugPrint("BUILD: $runtimeType");

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: Colors.teal),
        ),
      ],
    );
  }
}
