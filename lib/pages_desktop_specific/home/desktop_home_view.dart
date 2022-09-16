import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages_desktop_specific/home/desktop_menu.dart';
import 'package:stackwallet/pages_desktop_specific/home/my_stack_view/my_stack_view.dart';
import 'package:stackwallet/utilities/cfcolors.dart';

final homeContent = Provider<Widget>((ref) => const MyStackView());

class DesktopHomeView extends ConsumerStatefulWidget {
  const DesktopHomeView({Key? key}) : super(key: key);

  static const String routeName = "/desktopHome";

  @override
  ConsumerState<DesktopHomeView> createState() => _DesktopHomeViewState();
}

class _DesktopHomeViewState extends ConsumerState<DesktopHomeView> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: CFColors.almostWhite,
      child: Row(
        children: [
          const DesktopMenu(),
          Expanded(child: ref.watch(homeContent)),
        ],
      ),
    );
  }
}
