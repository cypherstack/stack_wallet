import 'package:flutter/material.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/pages/buy_view/buy_form.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

class BuyView extends StatelessWidget {
  const BuyView({
    Key? key,
    this.coin,
    this.tokenContract,
  }) : super(key: key);

  static const String routeName = "/stackBuyView";

  final Coin? coin;
  final EthContract? tokenContract;

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
        ),
        child: BuyForm(
          coin: coin,
          tokenContract: tokenContract,
        ),
      ),
    );
  }
}
