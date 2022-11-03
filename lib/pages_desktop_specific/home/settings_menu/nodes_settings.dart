import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/manage_nodes_views/coin_nodes_view.dart';
import 'package:stackwallet/providers/global/node_service_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

import '../../../utilities/util.dart';
import '../../../widgets/stack_text_field.dart';

class NodesSettings extends ConsumerStatefulWidget {
  const NodesSettings({Key? key}) : super(key: key);

  static const String routeName = "/settingsMenuNodes";

  @override
  ConsumerState<NodesSettings> createState() => _NodesSettings();
}

class _NodesSettings extends ConsumerState<NodesSettings> {
  List<Coin> _coins = [...Coin.values];

  late final TextEditingController searchNodeController;
  late final FocusNode searchNodeFocusNode;

  String filter = "";

  @override
  void initState() {
    _coins = _coins.toList();
    _coins.remove(Coin.firoTestNet);

    searchNodeController = TextEditingController();
    searchNodeFocusNode = FocusNode();

    super.initState();
  }

  @override
  void dispose() {
    searchNodeController.dispose();
    searchNodeFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool showTestNet = ref.watch(
      prefsChangeNotifierProvider.select((value) => value.showTestNetCoins),
    );

    List<Coin> coins = showTestNet
        ? _coins
        : _coins.sublist(0, _coins.length - kTestNetCoinCount);

    debugPrint("BUILD: $runtimeType");
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            right: 30,
          ),
          child: RoundedWhiteContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  Assets.svg.circleNode,
                  width: 48,
                  height: 48,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: RichText(
                        textAlign: TextAlign.start,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Nodes",
                              style: STextStyles.desktopTextSmall(context),
                            ),
                            TextSpan(
                              text: "\n\nSelect a coin to see nodes",
                              style: STextStyles.desktopTextExtraExtraSmall(
                                  context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                    child: TextField(
                      autocorrect: Util.isDesktop ? false : true,
                      enableSuggestions: Util.isDesktop ? false : true,
                      controller: searchNodeController,
                      focusNode: searchNodeFocusNode,
                      onChanged: (newString) {
                        setState(() => filter = newString);
                      },
                      style: STextStyles.field(context),
                      decoration: standardInputDecoration(
                        "Search",
                        searchNodeFocusNode,
                        context,
                      ).copyWith(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 16,
                          ),
                          child: SvgPicture.asset(
                            Assets.svg.search,
                            width: 16,
                            height: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...coins.map(
                          (coin) {
                            final count = ref
                                .watch(nodeServiceChangeNotifierProvider
                                    .select((value) => value.getNodesFor(coin)))
                                .length;

                            return Padding(
                              padding: const EdgeInsets.all(0),
                              child: RawMaterialButton(
                                // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    Constants.size.circularBorderRadius,
                                  ),
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                    CoinNodesView.routeName,
                                    arguments: coin,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    12.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Row(
                                        children: [
                                          SvgPicture.asset(
                                            Assets.svg.iconFor(coin: coin),
                                            width: 24,
                                            height: 24,
                                          ),
                                          const SizedBox(
                                            width: 12,
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${coin.prettyName} nodes",
                                                style: STextStyles.titleBold12(
                                                    context),
                                              ),
                                              Text(
                                                count > 1
                                                    ? "$count nodes"
                                                    : "Default",
                                                style:
                                                    STextStyles.label(context),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                        child: SvgPicture.asset(
                                          Assets.svg.chevronRight,
                                          alignment: Alignment.centerRight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
