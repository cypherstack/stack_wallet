import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/paynym/dialogs/claiming_paynym_dialog.dart';
import 'package:stackwallet/providers/global/paynym_api_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/coins/coin_paynym_extension.dart';
import 'package:stackwallet/services/coins/dogecoin/dogecoin_wallet.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';

class PaynymClaimView extends ConsumerStatefulWidget {
  const PaynymClaimView({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  static const String routeName = "/claimPaynym";

  @override
  ConsumerState<PaynymClaimView> createState() => _PaynymClaimViewState();
}

class _PaynymClaimViewState extends ConsumerState<PaynymClaimView> {
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
                      barrierDismissible: false,
                      builder: (context) => const ClaimingPaynymDialog(),
                    ).then((value) => shouldCancel = value == true),
                  );

                  // ghet wallet to access paynym calls
                  final wallet = ref
                      .read(walletsChangeNotifierProvider)
                      .getManager(widget.walletId)
                      .wallet as DogecoinWallet;

                  // get payment code
                  final pCode = await wallet.getPaymentCode();

                  // attempt to create new entry in paynym.is db
                  final created = await ref
                      .read(paynymAPIProvider)
                      .create(pCode.toString());

                  if (created.claimed) {
                    // payment code already claimed
                    debugPrint("pcode already claimed!!");
                    return;
                  }

                  String token;

                  if (created.token == null) {
                    // payment code already in db
                    // so we need to fetch a token

                    token = await ref
                        .read(paynymAPIProvider)
                        .token(pCode.toString());
                  } else {
                    token = created.token!;
                  }

                  // sign token with notification private key
                  final signatureBytes = await wallet.signWithNotificationKey(
                      Uint8List.fromList(token.codeUnits));
                  final signature = Format.uint8listToString(signatureBytes);

                  // claim paynym account
                  final claim =
                      await ref.read(paynymAPIProvider).claim(token, signature);

                  if (claim["claimed"] == pCode.toString()) {
                    // mark claim successful
                  }

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
