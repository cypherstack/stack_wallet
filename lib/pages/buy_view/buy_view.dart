import 'package:flutter/material.dart';
import 'package:stackwallet/pages/buy_view/buy_form.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

class BuyView extends StatefulWidget {
  const BuyView({
    Key? key,
    this.coin,
  }) : super(key: key);

  static const String routeName = "/stackBuyView";

  final Coin? coin;

  @override
  State<BuyView> createState() => _BuyViewState();
}

class _BuyViewState extends State<BuyView> {
  late final Coin? coin;

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
        child: BuyForm(coin: widget.coin),
      ),
    );
  }
}
