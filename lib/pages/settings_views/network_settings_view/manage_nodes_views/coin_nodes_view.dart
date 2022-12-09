import 'package:epicpay/pages/settings_views/network_settings_view/manage_nodes_views/add_edit_node_view.dart';
import 'package:epicpay/pages/settings_views/network_settings_view/sub_widgets/nodes_list.dart';
import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/enums/coin_enum.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/utilities/util.dart';
import 'package:epicpay/widgets/background.dart';
import 'package:epicpay/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicpay/widgets/custom_buttons/blue_text_button.dart';
import 'package:epicpay/widgets/desktop/desktop_dialog.dart';
import 'package:epicpay/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tuple/tuple.dart';

class CoinNodesView extends ConsumerStatefulWidget {
  const CoinNodesView({
    Key? key,
    required this.coin,
    this.rootNavigator = false,
  }) : super(key: key);

  static const String routeName = "/coinNodes";

  final Coin coin;
  final bool rootNavigator;

  @override
  ConsumerState<CoinNodesView> createState() => _CoinNodesViewState();
}

class _CoinNodesViewState extends ConsumerState<CoinNodesView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Util.isDesktop) {
      return DesktopDialog(
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 32,
                ),
                SvgPicture.asset(
                  Assets.svg.iconFor(coin: widget.coin),
                  width: 24,
                  height: 24,
                ),
                const SizedBox(
                  width: 12,
                ),
                Text(
                  "${widget.coin.prettyName} nodes",
                  style: STextStyles.desktopH3(context),
                  textAlign: TextAlign.center,
                ),
                Expanded(
                  child: DesktopDialogCloseButton(
                    onPressedOverride: Navigator.of(
                      context,
                      rootNavigator: widget.rootNavigator,
                    ).pop,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 32,
                right: 32,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${widget.coin.prettyName} nodes",
                    style: STextStyles.desktopTextExtraSmall(context).copyWith(
                      color:
                          Theme.of(context).extension<StackColors>()!.textDark,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  BlueTextButton(
                    text: "Add new node",
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AddEditNodeView.routeName,
                        arguments: Tuple4(
                          AddEditNodeViewType.add,
                          widget.coin,
                          null,
                          CoinNodesView.routeName,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: NodesList(
                coin: widget.coin,
                popBackToRoute: CoinNodesView.routeName,
              ),
            ),
          ],
        ),
      );
    } else {
      return Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: AppBarBackButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: Text(
              "${widget.coin.prettyName} nodes",
              style: STextStyles.titleH4(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 10,
                  bottom: 10,
                  right: 10,
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AppBarIconButton(
                    key: const Key("manageNodesAddNewNodeButtonKey"),
                    size: 36,
                    shadows: const [],
                    color:
                        Theme.of(context).extension<StackColors>()!.background,
                    icon: SvgPicture.asset(
                      Assets.svg.plus,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorDark,
                      width: 20,
                      height: 20,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AddEditNodeView.routeName,
                        arguments: Tuple4(
                          AddEditNodeViewType.add,
                          widget.coin,
                          null,
                          CoinNodesView.routeName,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.only(
              top: 12,
              left: 12,
              right: 12,
            ),
            child: SingleChildScrollView(
              child: NodesList(
                coin: widget.coin,
                popBackToRoute: CoinNodesView.routeName,
              ),
            ),
          ),
        ),
      );
    }
  }
}
