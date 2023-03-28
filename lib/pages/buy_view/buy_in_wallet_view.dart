import 'package:flutter/material.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/pages/buy_view/buy_view.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';

class BuyInWalletView extends StatefulWidget {
  const BuyInWalletView({
    Key? key,
    required this.coin,
    this.contract,
  }) : super(key: key);

  static const String routeName = "/stackBuyInWalletView";

  final Coin? coin;
  final EthContract? contract;

  @override
  State<BuyInWalletView> createState() => _BuyInWalletViewState();
}

class _BuyInWalletViewState extends State<BuyInWalletView> {
  late final Coin? coin;

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            "Buy ${widget.coin?.ticker}",
            style: STextStyles.navBarTitle(context),
          ),
        ),
        body: BuyView(
          coin: widget.coin,
          tokenContract,
          widget.contract,
        ),
      ),
    );
  }
}
