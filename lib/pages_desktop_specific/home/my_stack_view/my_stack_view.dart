import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/pages/wallets_view/sub_widgets/empty_wallets.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';

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

    final showFavorites = ref.watch(prefsChangeNotifierProvider
        .select((value) => value.showFavoriteWallets));

    return Column(
      children: [
        DesktopAppBar(
          isCompactHeight: true,
          leading: Row(
            children: [
              const SizedBox(
                width: 24,
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: SvgPicture.asset(
                  Assets.svg.stackIcon,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Text(
                "My Stack",
                style: STextStyles.desktopH3,
              )
            ],
          ),
        ),
        Expanded(
          child: hasWallets ? Container() : const EmptyWallets(),
        ),
      ],
    );
  }
}
