import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/animated_widgets/rotate_icon.dart';
import 'package:stackwallet/widgets/expandable.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/wallet_card.dart';
import 'package:stackwallet/widgets/wallet_info_row/sub_widgets/wallet_info_row_balance.dart';
import 'package:stackwallet/widgets/wallet_info_row/sub_widgets/wallet_info_row_coin_icon.dart';
import 'package:tuple/tuple.dart';

class DesktopExpandingWalletCard extends StatefulWidget {
  const DesktopExpandingWalletCard({
    Key? key,
    required this.data,
    required this.navigatorState,
  }) : super(key: key);

  final Tuple2<Manager, List<EthContract>> data;
  final NavigatorState navigatorState;

  @override
  State<DesktopExpandingWalletCard> createState() =>
      _DesktopExpandingWalletCardState();
}

class _DesktopExpandingWalletCardState
    extends State<DesktopExpandingWalletCard> {
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
        onExpandWillChange: (toState) {
          if (toState == ExpandableState.expanded) {
            rotateIconController.forward?.call();
          } else {
            rotateIconController.reverse?.call();
          }
        },
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
              child: SimpleWalletCard(
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
                child: SimpleWalletCard(
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
