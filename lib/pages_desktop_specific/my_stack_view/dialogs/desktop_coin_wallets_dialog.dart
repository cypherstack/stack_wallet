import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/ethereum/ethereum_wallet.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/animated_widgets/rotate_icon.dart';
import 'package:stackwallet/widgets/expandable.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';
import 'package:stackwallet/widgets/wallet_card.dart';
import 'package:stackwallet/widgets/wallet_info_row/sub_widgets/wallet_info_row_balance_future.dart';
import 'package:stackwallet/widgets/wallet_info_row/sub_widgets/wallet_info_row_coin_icon.dart';
import 'package:tuple/tuple.dart';

class DesktopCoinWalletsDialog extends ConsumerStatefulWidget {
  const DesktopCoinWalletsDialog({
    Key? key,
    required this.coin,
    required this.navigatorState,
  }) : super(key: key);

  final Coin coin;
  final NavigatorState navigatorState;

  @override
  ConsumerState<DesktopCoinWalletsDialog> createState() =>
      _DesktopCoinWalletsDialogState();
}

class _DesktopCoinWalletsDialogState
    extends ConsumerState<DesktopCoinWalletsDialog> {
  final isDesktop = Util.isDesktop;

  late final TextEditingController _searchController;
  late final FocusNode searchFieldFocusNode;

  String _searchString = "";

  final List<Tuple2<Manager, List<EthContract>>> wallets = [];

  List<Tuple2<Manager, List<EthContract>>> _filter(String searchTerm) {
    if (searchTerm.isEmpty) {
      return wallets;
    }

    final List<Tuple2<Manager, List<EthContract>>> results = [];
    final term = searchTerm.toLowerCase();

    for (final tuple in wallets) {
      bool includeManager = false;
      // search wallet name and total balance
      includeManager |= _elementContains(tuple.item1.walletName, term);
      includeManager |= _elementContains(
        tuple.item1.balance.total.decimal.toString(),
        term,
      );

      final List<EthContract> contracts = [];

      for (final contract in tuple.item2) {
        if (_elementContains(contract.name, term)) {
          contracts.add(contract);
        } else if (_elementContains(contract.symbol, term)) {
          contracts.add(contract);
        } else if (_elementContains(contract.type.name, term)) {
          contracts.add(contract);
        } else if (_elementContains(contract.address, term)) {
          contracts.add(contract);
        }
      }

      if (includeManager || contracts.isNotEmpty) {
        results.add(Tuple2(tuple.item1, contracts));
      }
    }

    return results;
  }

  bool _elementContains(String element, String term) {
    return element.toLowerCase().contains(term);
  }

  @override
  void initState() {
    _searchController = TextEditingController();
    searchFieldFocusNode = FocusNode();

    final walletsData =
        ref.read(walletsServiceChangeNotifierProvider).fetchWalletsData();
    walletsData.removeWhere((key, value) => value.coin != widget.coin);

    if (widget.coin == Coin.ethereum) {
      for (final data in walletsData.values) {
        final List<EthContract> contracts = [];
        final manager =
            ref.read(walletsChangeNotifierProvider).getManager(data.walletId);
        final contractAddresses = (manager.wallet as EthereumWallet)
            .getWalletTokenContractAddresses();

        // fetch each contract
        for (final contractAddress in contractAddresses) {
          final contract = ref
              .read(
                mainDBProvider,
              )
              .getEthContractSync(
                contractAddress,
              );

          // add it to list if it exists in DB
          if (contract != null) {
            contracts.add(contract);
          }
        }

        // add tuple to list
        wallets.add(
          Tuple2(
            ref.read(walletsChangeNotifierProvider).getManager(
                  data.walletId,
                ),
            contracts,
          ),
        );
      }
    } else {
      // add non token wallet tuple to list
      for (final data in walletsData.values) {
        wallets.add(
          Tuple2(
            ref.read(walletsChangeNotifierProvider).getManager(
                  data.walletId,
                ),
            [],
          ),
        );
      }
    }

    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    searchFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
          child: TextField(
            autocorrect: !isDesktop,
            enableSuggestions: !isDesktop,
            controller: _searchController,
            focusNode: searchFieldFocusNode,
            onChanged: (value) {
              setState(() {
                _searchString = value;
              });
            },
            style: isDesktop
                ? STextStyles.desktopTextExtraSmall(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textFieldActiveText,
                    height: 1.8,
                  )
                : STextStyles.field(context),
            decoration: standardInputDecoration(
              "Search...",
              searchFieldFocusNode,
              context,
              desktopMed: isDesktop,
            ).copyWith(
              prefixIcon: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 12 : 10,
                  vertical: isDesktop ? 18 : 16,
                ),
                child: SvgPicture.asset(
                  Assets.svg.search,
                  width: isDesktop ? 20 : 16,
                  height: isDesktop ? 20 : 16,
                ),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(right: 0),
                      child: UnconstrainedBox(
                        child: Row(
                          children: [
                            TextFieldIconButton(
                              child: const XIcon(),
                              onTap: () async {
                                setState(() {
                                  _searchController.text = "";
                                  _searchString = "";
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
          height: 16,
        ),
        Expanded(
          child: Builder(builder: (context) {
            final data = _filter(_searchString);
            return ListView.separated(
              itemBuilder: (_, index) => widget.coin == Coin.ethereum
                  ? _DesktopWalletCard(
                      key: Key(
                          "${data[index].item1.walletName}_${data[index].item2.map((e) => e.address).join()}"),
                      data: data[index],
                      navigatorState: widget.navigatorState,
                    )
                  : RoundedWhiteContainer(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                      borderColor: Theme.of(context)
                          .extension<StackColors>()!
                          .backgroundAppBar,
                      child: WalletSheetCard(
                        walletId: data[index].item1.walletId,
                        popPrevious: true,
                        desktopNavigatorState: widget.navigatorState,
                      ),
                    ),
              separatorBuilder: (_, __) => const SizedBox(
                height: 10,
              ),
              itemCount: data.length,
            );
          }),
        ),
      ],
    );
  }
}

class _DesktopWalletCard extends StatefulWidget {
  const _DesktopWalletCard({
    Key? key,
    required this.data,
    required this.navigatorState,
  }) : super(key: key);

  final Tuple2<Manager, List<EthContract>> data;
  final NavigatorState navigatorState;

  @override
  State<_DesktopWalletCard> createState() => _DesktopWalletCardState();
}

class _DesktopWalletCardState extends State<_DesktopWalletCard> {
  final expandableController = ExpandableController();
  final rotateIconController = RotateIconController();
  final List<String> tokenContractAddresses = [];

  @override
  void initState() {
    if (widget.data.item1.hasTokenSupport) {
      tokenContractAddresses.addAll(
        widget.data.item2.map((e) => e.address),
      );
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      padding: EdgeInsets.zero,
      borderColor: Theme.of(context).extension<StackColors>()!.backgroundAppBar,
      child: Expandable(
        initialState: widget.data.item1.hasTokenSupport
            ? ExpandableState.expanded
            : ExpandableState.collapsed,
        controller: expandableController,
        expandOverride: () {},
        header: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          WalletInfoCoinIcon(
                            coin: widget.data.item1.coin,
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Text(
                            widget.data.item1.walletName,
                            style: STextStyles.desktopTextExtraSmall(context)
                                .copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: WalletInfoRowBalance(
                        walletId: widget.data.item1.walletId,
                      ),
                    ),
                  ],
                ),
              ),
              MaterialButton(
                padding: const EdgeInsets.all(5),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minWidth: 32,
                height: 32,
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldDefaultBG,
                elevation: 0,
                hoverElevation: 0,
                disabledElevation: 0,
                highlightElevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                onPressed: () {
                  if (expandableController.state == ExpandableState.collapsed) {
                    rotateIconController.forward?.call();
                  } else {
                    rotateIconController.reverse?.call();
                  }
                  expandableController.toggle?.call();
                },
                child: RotateIcon(
                  controller: rotateIconController,
                  icon: RotatedBox(
                    quarterTurns: 2,
                    child: SvgPicture.asset(
                      Assets.svg.chevronDown,
                      width: 14,
                    ),
                  ),
                  curve: Curves.easeInOut,
                ),
              ),
            ],
          ),
        ),
        body: ListView(
          shrinkWrap: true,
          primary: false,
          children: [
            Container(
              width: double.infinity,
              height: 1,
              color:
                  Theme.of(context).extension<StackColors>()!.backgroundAppBar,
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 32,
                right: 14,
                top: 14,
                bottom: 14,
              ),
              child: WalletSheetCard(
                walletId: widget.data.item1.walletId,
                popPrevious: true,
                desktopNavigatorState: widget.navigatorState,
              ),
            ),
            ...tokenContractAddresses.map(
              (e) => Padding(
                padding: const EdgeInsets.only(
                  left: 32,
                  right: 14,
                  top: 14,
                  bottom: 14,
                ),
                child: WalletSheetCard(
                  walletId: widget.data.item1.walletId,
                  contractAddress: e,
                  popPrevious: true,
                  desktopNavigatorState: widget.navigatorState,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
