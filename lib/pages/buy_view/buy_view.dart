import 'package:flutter/material.dart';
import 'package:stackwallet/pages/buy_view/buy_form.dart';

class BuyView extends StatefulWidget {
  const BuyView({Key? key}) : super(key: key);

  static const String routeName = "/stackBuyView";

  @override
  State<BuyView> createState() => _BuyViewState();
}

class _BuyViewState extends State<BuyView> {
  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
        ),
        child: BuyForm(),
      ),
    );
  }
}
