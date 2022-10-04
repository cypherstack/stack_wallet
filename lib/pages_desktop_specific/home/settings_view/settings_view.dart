import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  static const String routeName = "/settingsView";

  @override
  ConsumerState<SettingsView> createState() => _SettingsView();
}

class _SettingsView extends ConsumerState<SettingsView> {
  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    // TODO: implement build
    throw UnimplementedError();
  }
}
