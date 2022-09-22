import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/manage_nodes_views/add_edit_node_view.dart';
import 'package:stackwallet/pages/settings_views/sub_widgets/nodes_list.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:tuple/tuple.dart';

class CoinNodesView extends ConsumerStatefulWidget {
  const CoinNodesView({
    Key? key,
    required this.coin,
  }) : super(key: key);

  static const String routeName = "/coinNodes";

  final Coin coin;

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
    return Scaffold(
      backgroundColor: Theme.of(context).extension<StackColors>()!.background,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "${widget.coin.prettyName} nodes",
          style: STextStyles.navBarTitle(context),
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
                color: Theme.of(context).extension<StackColors>()!.background,
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
    );
  }
}
