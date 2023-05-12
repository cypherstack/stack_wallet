import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/ethereum/ethereum_wallet.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/widgets/animated_widgets/rotate_icon.dart';
import 'package:stackwallet/widgets/expandable.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/wallet_card.dart';
import 'package:stackwallet/widgets/wallet_info_row/wallet_info_row.dart';

class MasterWalletCard extends ConsumerStatefulWidget {
  const MasterWalletCard({
    Key? key,
    required this.walletId,
    this.popPrevious = false,
  }) : super(key: key);

  final String walletId;
  final bool popPrevious;

  @override
  ConsumerState<MasterWalletCard> createState() => _MasterWalletCardState();
}

class _MasterWalletCardState extends ConsumerState<MasterWalletCard> {
  final expandableController = ExpandableController();
  final rotateIconController = RotateIconController();
  late final List<String> tokenContractAddresses;

  @override
  void initState() {
    final ethWallet = ref
        .read(walletsChangeNotifierProvider)
        .getManager(widget.walletId)
        .wallet as EthereumWallet;

    tokenContractAddresses = ethWallet.getWalletTokenContractAddresses();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      padding: EdgeInsets.zero,
      child: Expandable(
        controller: expandableController,
        onExpandWillChange: (toState) {
          if (toState == ExpandableState.expanded) {
            rotateIconController.forward?.call();
          } else {
            rotateIconController.reverse?.call();
          }
        },
        header: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: WalletInfoRow(
                  walletId: widget.walletId,
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
                  icon: SvgPicture.asset(
                    Assets.svg.chevronDown,
                    width: 14,
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
              height: 1.5,
              color:
                  Theme.of(context).extension<StackColors>()!.backgroundAppBar,
            ),
            Padding(
              padding: const EdgeInsets.all(
                7,
              ),
              child: SimpleWalletCard(
                walletId: widget.walletId,
                popPrevious: true,
              ),
            ),
            ...tokenContractAddresses.map(
              (e) => Padding(
                padding: const EdgeInsets.only(
                  left: 7,
                  right: 7,
                  bottom: 7,
                ),
                child: SimpleWalletCard(
                  walletId: widget.walletId,
                  contractAddress: e,
                  popPrevious: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
