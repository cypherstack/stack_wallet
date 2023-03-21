import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/pages_desktop_specific/desktop_menu.dart';

final currentDesktopMenuItemProvider =
    StateProvider<DesktopMenuItemId>((ref) => DesktopMenuItemId.myStack);

final prevDesktopMenuItemProvider =
    StateProvider<DesktopMenuItemId>((ref) => DesktopMenuItemId.myStack);
