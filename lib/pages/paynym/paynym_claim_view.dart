import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';

import 'dialogs/claiming_paynym_dialog.dart';

class PaynymClaimView extends StatefulWidget {
  const PaynymClaimView({Key? key}) : super(key: key);

  static const String routeName = "/claimPaynym";

  @override
  State<PaynymClaimView> createState() => _PaynymClaimViewState();
}

class _PaynymClaimViewState extends State<PaynymClaimView> {
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
              const Spacer(
                flex: 1,
              ),
              Image(
                image: AssetImage(
                  Assets.png.stack,
                ),
                width: MediaQuery.of(context).size.width / 2,
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                "You do not have a PayNym yet.\nClaim yours now!",
                style: STextStyles.baseXS(context).copyWith(
                  color:
                      Theme.of(context).extension<StackColors>()!.textSubtitle1,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(
                flex: 2,
              ),
              PrimaryButton(
                label: "Claim",
                onPressed: () async {
                  bool shouldCancel = false;
                  unawaited(
                    showDialog<bool?>(
                      context: context,
                      builder: (context) => const ClaimingPaynymDialog(),
                    ).then((value) => shouldCancel = value == true),
                  );
                  // generate and submit paynym to api

                  await Future<void>.delayed(const Duration(seconds: 3));

                  if (mounted && !shouldCancel) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
