import 'package:flutter/material.dart';
import 'package:stackwallet/pages/exchange_view/exchange_form.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/subwidgets/desktop_trade_history.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class DesktopExchangeView extends StatefulWidget {
  const DesktopExchangeView({Key? key}) : super(key: key);

  static const String routeName = "/desktopExchange";

  @override
  State<DesktopExchangeView> createState() => _DesktopExchangeViewState();
}

class _DesktopExchangeViewState extends State<DesktopExchangeView> {
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
            "Exchange",
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
                  Text(
                    "Exchange details",
                    style: STextStyles.desktopTextExtraExtraSmall(context),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  const RoundedWhiteContainer(
                    padding: EdgeInsets.all(24),
                    child: ExchangeForm(),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 16,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Exchange details",
                    style: STextStyles.desktopTextExtraExtraSmall(context),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  const RoundedWhiteContainer(
                    padding: EdgeInsets.all(0),
                    child: DesktopTradeHistory(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
