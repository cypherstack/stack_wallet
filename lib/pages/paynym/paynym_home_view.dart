import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';

class PaynymHomeView extends StatefulWidget {
  const PaynymHomeView({
    Key? key,
    required this.walletId,
    required this.paymentCodeString,
  }) : super(key: key);

  final String walletId;
  final String paymentCodeString;

  static const String routeName = "/paynymHome";

  @override
  State<PaynymHomeView> createState() => _PaynymHomeViewState();
}

class _PaynymHomeViewState extends State<PaynymHomeView> {
  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    final isDesktop = Util.isDesktop;

    return MasterScaffold(
      isDesktop: isDesktop,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        titleSpacing: 0,
        title: Text(
          "PayNym",
          style: STextStyles.navBarTitle(context),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              PayNymBot(
                paymentCodeString: widget.paymentCodeString,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PayNymBot extends StatelessWidget {
  const PayNymBot({
    Key? key,
    required this.paymentCodeString,
  }) : super(key: key);

  final String paymentCodeString;

  @override
  Widget build(BuildContext context) {
    return Image.network("https://paynym.is/$paymentCodeString/avatar");
  }
}
