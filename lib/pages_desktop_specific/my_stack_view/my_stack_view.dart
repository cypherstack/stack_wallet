import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackduo/pages/wallets_view/sub_widgets/empty_wallets.dart';
import 'package:stackduo/pages_desktop_specific/my_stack_view/my_wallets.dart';
import 'package:stackduo/providers/global/wallets_provider.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/widgets/background.dart';
import 'package:stackduo/widgets/desktop/desktop_app_bar.dart';

class MyStackView extends ConsumerStatefulWidget {
  const MyStackView({Key? key}) : super(key: key);

  static const String routeName = "/myStackDesktop";

  @override
  ConsumerState<MyStackView> createState() => _MyStackViewState();
}

class _MyStackViewState extends ConsumerState<MyStackView> {
  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    final hasWallets = ref.watch(walletsChangeNotifierProvider).hasWallets;

    return Background(
      child: Column(
        children: [
          const DesktopAppBar(
            isCompactHeight: true,
            leading: DesktopMyStackTitle(),
          ),
          Expanded(
            child: hasWallets ? const MyWallets() : const EmptyWallets(),
          ),
        ],
      ),
    );
  }
}

class DesktopMyStackTitle extends StatelessWidget {
  const DesktopMyStackTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 24,
        ),
        SizedBox(
          width: 32,
          height: 32,
          child: SvgPicture.asset(
            Assets.svg.stackDuoIcon(context),
          ),
        ),
        const SizedBox(
          width: 12,
        ),
        Text(
          "My Stack",
          style: STextStyles.desktopH3(context),
        )
      ],
    );
  }
}
