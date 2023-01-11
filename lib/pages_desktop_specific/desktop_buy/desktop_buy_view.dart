import 'package:flutter/material.dart';
import 'package:stackwallet/pages/buy_view/buy_form.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class DesktopBuyView extends StatefulWidget {
  const DesktopBuyView({Key? key}) : super(key: key);

  static const String routeName = "/desktopBuy";

  @override
  State<DesktopBuyView> createState() => _DesktopBuyViewState();
}

class _DesktopBuyViewState extends State<DesktopBuyView> {
  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      appBar: DesktopAppBar(
        isCompactHeight: true,
        leading: Padding(
          padding: const EdgeInsets.only(
            left: 24,
          ),
          child: Text(
            "Buy crypto",
            style: STextStyles.desktopH3(context),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: 24,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text(
                  //   "Coming soon",
                  //   style: STextStyles.desktopTextExtraExtraSmall(context),
                  // ),
                  const SizedBox(
                    height: 16,
                  ),
                  const RoundedWhiteContainer(
                    padding: EdgeInsets.all(24),
                    child: BuyForm(),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 16,
            ),
            // Expanded(
            //   child: Row(
            //     children: const [
            //       Expanded(
            //         child: DesktopTradeHistory(),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
