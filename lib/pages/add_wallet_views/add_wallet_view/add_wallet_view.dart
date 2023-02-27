import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/sub_widgets/add_wallet_text.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/sub_widgets/mobile_coin_list.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/sub_widgets/next_button.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/sub_widgets/searchable_coin_list.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/default_eth_tokens.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/expandable.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class AddWalletView extends ConsumerStatefulWidget {
  const AddWalletView({Key? key}) : super(key: key);

  static const routeName = "/addWallet";

  @override
  ConsumerState<AddWalletView> createState() => _AddWalletViewState();
}

class _AddWalletViewState extends ConsumerState<AddWalletView> {
  late final TextEditingController _searchFieldController;
  late final FocusNode _searchFocusNode;

  String _searchTerm = "";

  final List<Coin> _coinsTestnet = [
    ...Coin.values.sublist(Coin.values.length - kTestNetCoinCount - 1),
  ];
  final List<Coin> _coins = [
    ...Coin.values.sublist(0, Coin.values.length - kTestNetCoinCount - 1)
  ];
  final List<AddWalletListEntity> coinEntities = [];
  final List<AddWalletListEntity> tokenEntities = [];

  final bool isDesktop = Util.isDesktop;

  @override
  void initState() {
    _searchFieldController = TextEditingController();
    _searchFocusNode = FocusNode();
    _coinsTestnet.remove(Coin.firoTestNet);
    if (isDesktop) {
      _coins.remove(Coin.wownero);
      if (Platform.isWindows) {
        _coins.remove(Coin.monero);
      }
    }

    coinEntities.addAll(_coins.map((e) => CoinEntity(e)));

    if (ref.read(prefsChangeNotifierProvider).showTestNetCoins) {
      coinEntities.addAll(_coinsTestnet.map((e) => CoinEntity(e)));
    }

    tokenEntities.addAll(DefaultTokens.list.map((e) => EthTokenEntity(e)));
    tokenEntities.sort((a, b) => a.name.compareTo(b.name));

    super.initState();
  }

  @override
  void dispose() {
    _searchFieldController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    if (isDesktop) {
      return DesktopScaffold(
        appBar: const DesktopAppBar(
          isCompactHeight: false,
          leading: AppBarBackButton(),
          trailing: ExitToMyStackButton(),
        ),
        body: Column(
          children: [
            const AddWalletText(
              isDesktop: true,
            ),
            const SizedBox(
              height: 16,
            ),
            Expanded(
              child: SizedBox(
                width: 480,
                child: RoundedWhiteContainer(
                  radiusMultiplier: 2,
                  padding: const EdgeInsets.only(
                    left: 16,
                    top: 16,
                    right: 16,
                    bottom: 0,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            Constants.size.circularBorderRadius,
                          ),
                          child: TextField(
                            autocorrect: Util.isDesktop ? false : true,
                            enableSuggestions: Util.isDesktop ? false : true,
                            controller: _searchFieldController,
                            focusNode: _searchFocusNode,
                            onChanged: (value) {
                              setState(() {
                                _searchTerm = value;
                              });
                            },
                            style:
                                STextStyles.desktopTextMedium(context).copyWith(
                              height: 2,
                            ),
                            decoration: standardInputDecoration(
                              "Search",
                              _searchFocusNode,
                              context,
                            ).copyWith(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  // vertical: 20,
                                ),
                                child: SvgPicture.asset(
                                  Assets.svg.search,
                                  width: 24,
                                  height: 24,
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textFieldDefaultSearchIconLeft,
                                ),
                              ),
                              suffixIcon: _searchFieldController.text.isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: UnconstrainedBox(
                                        child: Row(
                                          children: [
                                            TextFieldIconButton(
                                              child: const XIcon(
                                                width: 24,
                                                height: 24,
                                              ),
                                              onTap: () async {
                                                setState(() {
                                                  _searchFieldController.text =
                                                      "";
                                                  _searchTerm = "";
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SearchableCoinList(
                          entities: coinEntities,
                          isDesktop: true,
                          searchTerm: _searchTerm,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            const SizedBox(
              height: 70,
              width: 480,
              child: AddWalletNextButton(
                isDesktop: true,
              ),
            ),
            const SizedBox(
              height: 32,
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
          ),
          body: Container(
            color: Theme.of(context).extension<StackColors>()!.background,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AddWalletText(
                    isDesktop: false,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ExpandingSubListItem(
                            title: "Coins",
                            entities: coinEntities,
                            initialState: ExpandableState.expanded,
                          ),
                          ExpandingSubListItem(
                            title: "Tokens",
                            entities: tokenEntities,
                            initialState: ExpandableState.collapsed,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  const AddWalletNextButton(
                    isDesktop: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}

class ExpandingSubListItem extends StatefulWidget {
  const ExpandingSubListItem({
    Key? key,
    required this.title,
    required this.entities,
    required this.initialState,
  }) : super(key: key);

  final String title;
  final List<AddWalletListEntity> entities;
  final ExpandableState initialState;

  @override
  State<ExpandingSubListItem> createState() => _ExpandingSubListItemState();
}

class _ExpandingSubListItemState extends State<ExpandingSubListItem> {
  final isDesktop = Util.isDesktop;

  late final ExpandableController _controller;

  late bool _expandedState;

  @override
  void initState() {
    _expandedState = widget.initialState == ExpandableState.expanded;
    _controller = ExpandableController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_expandedState) {
        _controller.toggle?.call();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Expandable(
      controller: _controller,
      onExpandChanged: (state) {
        setState(() {
          _expandedState = state == ExpandableState.expanded;
        });
      },
      header: Container(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(
            top: 8.0,
            bottom: 8.0,
            right: 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: isDesktop
                    ? STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textDark3,
                      )
                    : STextStyles.smallMed12(context),
                textAlign: TextAlign.left,
              ),
              SvgPicture.asset(
                _expandedState ? Assets.svg.chevronUp : Assets.svg.chevronDown,
                width: 12,
                height: 6,
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldActiveSearchIconRight,
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        primary: false,
        child: MobileCoinList(
          entities: widget.entities,
        ),
      ),
    );
  }
}
