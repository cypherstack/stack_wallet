import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class BuyView extends StatefulWidget {
  const BuyView({Key? key}) : super(key: key);

  @override
  State<BuyView> createState() => _BuyViewState();
}

class _BuyViewState extends State<BuyView> {
  @override
  Widget build(BuildContext context) {
    //todo: check if print needed
    // debugPrint("BUILD: BuyView");
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Text(
                  "Coming soon",
                  style: STextStyles.pageTitleH1(context),
                ),
              ),
            ],
          ),
        ),
        // child: Column(
        //   children: [
        //     Container(
        //       color: Colors.green,
        //       child: Text("BuyView"),
        //     ),
        //     Container(
        //       color: Colors.green,
        //       child: Text("BuyView"),
        //     ),
        //     Spacer(),
        //     Container(
        //       color: Colors.green,
        //       child: Text("BuyView"),
        //     ),
        //   ],
        // ),
      ),
    );
  }
}
