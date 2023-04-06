import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';

class XPubView extends ConsumerStatefulWidget {
  const XPubView({Key? key}) : super(key: key);

  static const String routeName = "/xpub";

  @override
  ConsumerState<XPubView> createState() => _XPubViewState();
}

class _XPubViewState extends ConsumerState<XPubView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () async {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            "Wallet xPub",
            style: STextStyles.navBarTitle(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(
            top: 12,
            left: 16,
            right: 16,
          ),
          child: Text("TODO"),
        ),
      ),
    );
  }
}
