import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/add_wallet_list_entity/add_wallet_list_entity.dart';
import 'package:stackwallet/models/add_wallet_list_entity/sub_classes/coin_entity.dart';
import 'package:stackwallet/models/add_wallet_list_entity/sub_classes/eth_token_entity.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/pages/add_wallet_views/add_token_view/add_custom_token_view.dart';
import 'package:stackwallet/pages/add_wallet_views/add_token_view/sub_widgets/add_custom_token_selector.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/sub_widgets/add_wallet_text.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/sub_widgets/expanding_sub_list_item.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/sub_widgets/next_button.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import 'package:stackwallet/providers/providers.dart';
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
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
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
  final List<EthTokenEntity> tokenEntities = [];

  final bool isDesktop = Util.isDesktop;

  List<AddWalletListEntity> filter(
    String text,
    List<AddWalletListEntity> entities,
  ) {
    final _entities = [...entities];
    if (text.isNotEmpty) {
      final lowercaseTerm = text.toLowerCase();
      _entities.retainWhere(
        (e) =>
            e.ticker.toLowerCase().contains(lowercaseTerm) ||
            e.name.toLowerCase().contains(lowercaseTerm) ||
            e.coin.name.toLowerCase().contains(lowercaseTerm) ||
            (e is EthTokenEntity &&
                e.token.address.toLowerCase().contains(lowercaseTerm)),
      );
    }

    return _entities;
  }

  Future<void> _addToken() async {
    EthContract? contract;
    if (isDesktop) {
      contract = await showDialog(
        context: context,
        builder: (context) => const DesktopDialog(
          maxWidth: 580,
          maxHeight: 500,
          child: AddCustomTokenView(),
        ),
      );
    } else {
      contract = await Navigator.of(context).pushNamed(
        AddCustomTokenView.routeName,
      );
    }

    if (contract != null) {
      await MainDB.instance.putEthContract(contract);
      if (mounted) {
        setState(() {
          if (tokenEntities
              .where((e) => e.token.address == contract!.address)
              .isEmpty) {
            tokenEntities.add(EthTokenEntity(contract!));
            tokenEntities.sort((a, b) => a.token.name.compareTo(b.token.name));
          }
        });
      }
    }
  }

  @override
  void initState() {
    _searchFieldController = TextEditingController();
    _searchFocusNode = FocusNode();
    _coinsTestnet.remove(Coin.firoTestNet);
    if (Platform.isWindows) {
      _coins.remove(Coin.monero);
      _coins.remove(Coin.wownero);
    }

    coinEntities.addAll(_coins.map((e) => CoinEntity(e)));

    if (ref.read(prefsChangeNotifierProvider).showTestNetCoins) {
      coinEntities.addAll(_coinsTestnet.map((e) => CoinEntity(e)));
    }

    final contracts =
        MainDB.instance.getEthContracts().sortByName().findAllSync();

    if (contracts.isEmpty) {
      contracts.addAll(DefaultTokens.list);
      MainDB.instance.putEthContracts(contracts);
    }

    tokenEntities.addAll(contracts.map((e) => EthTokenEntity(e)));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.refresh(addWalletSelectedEntityStateProvider);
    });

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
                      const SizedBox(
                        height: 8,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              ExpandingSubListItem(
                                title: "Coins",
                                entities: filter(_searchTerm, coinEntities),
                                initialState: ExpandableState.expanded,
                              ),
                              ExpandingSubListItem(
                                title: "Tokens",
                                entities: filter(_searchTerm, tokenEntities),
                                initialState: ExpandableState.expanded,
                                trailing: AddCustomTokenSelector(
                                  addFunction: _addToken,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                    child: TextField(
                      autofocus: isDesktop,
                      autocorrect: !isDesktop,
                      enableSuggestions: !isDesktop,
                      controller: _searchFieldController,
                      focusNode: _searchFocusNode,
                      onChanged: (value) => setState(() => _searchTerm = value),
                      style: STextStyles.field(context),
                      decoration: standardInputDecoration(
                        "Search",
                        _searchFocusNode,
                        context,
                        desktopMed: isDesktop,
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
                        suffixIcon: _searchFieldController.text.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(right: 0),
                                child: UnconstrainedBox(
                                  child: Row(
                                    children: [
                                      TextFieldIconButton(
                                        child: const XIcon(),
                                        onTap: () async {
                                          setState(() {
                                            _searchFieldController.text = "";
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
                  const SizedBox(
                    height: 10,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ExpandingSubListItem(
                            title: "Coins",
                            entities: filter(_searchTerm, coinEntities),
                            initialState: ExpandableState.expanded,
                          ),
                          ExpandingSubListItem(
                            title: "Tokens",
                            entities: filter(_searchTerm, tokenEntities),
                            initialState: ExpandableState.expanded,
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
