import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages_desktop_specific/home/desktop_menu.dart';

final currentDesktopMenuItemProvider =
    StateProvider<DesktopMenuItemId>((ref) => DesktopMenuItemId.myStack);
