import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/paynym/dialogs/claiming_paynym_dialog.dart';
import 'package:stackwallet/providers/global/paynym_api_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/coins/coin_paynym_extension.dart';
import 'package:stackwallet/services/coins/dogecoin/dogecoin_wallet.dart';
import 'package:stackwallet/utilities/assets.dart';
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
                      builder: (context) => const ClaimingPaynymDialog(),
                    ).then((value) => shouldCancel = value == true),
                  );
                  // generate and submit paynym to api

                  final wallet = ref
                      .read(walletsChangeNotifierProvider)
                      .getManager(widget.walletId)
                      .wallet as DogecoinWallet;
                  final pCode = await wallet.getPaymentCode();

                  final result = await ref
                      .read(paynymAPIProvider)
                      .create(pCode.toString());

                  // final result =
                  //     await ref.read(paynymAPIProvider).token(pCode.toString());

                  // final token =
                  //     "IlBNOFRKWWt1U2RZWEpud0RCcThDaGZpbmZYdjNzcnhoUXJ4M2VvRXdiU3c1MXdNamRvOUpKMkRzeWN3VDNndDN6SFE3Y1YxZ3J2YWJNbW1mMUJ0ajZmWTd0Z2tnU3o5QjhNWnVSM2tqWWZnTUxNVVJKQ1hOIg.FoPF3g.KUMZDC4U_ek-B6cqPLYilXniQv8";
                  //
                  // print("======================");
                  // print(token);
                  // print(token.codeUnits);
                  // print(utf8.encode(token));
                  // print(utf8.decode(token.codeUnits));
                  //
                  // print("======================");
                  //
                  // final signed = await wallet.signWithNotificationKey(
                  //     Uint8List.fromList(token.codeUnits));
                  //
                  // final signedString = Format.uint8listToString(signed);
                  //
                  // print("======================");
                  // print(signed);
                  // print(signedString);
                  //
                  // print("======================");

                  // final result2 = await ref
                  //     .read(paynymAPIProvider)
                  //     .claim(token, signedString);

                  // print("======================");
                  // print(
                  //     result2); //  {claimed: PM8TJYkuSdYXJnwDBq8ChfinfXv3srxhQrx3eoEwbSw51wMjdo9JJ2DsycwT3gt3zHQ7cV1grvabMmmf1Btj6fY7tgkgSz9B8MZuR3kjYfgMLMURJCXN, token: IlBNOFRKWWt1U2RZWEpud0RCcThDaGZpbmZYdjNzcnhoUXJ4M2VvRXdiU3c1MXdNamRvOUpKMkRzeWN3VDNndDN6SFE3Y1YxZ3J2YWJNbW1mMUJ0ajZmWTd0Z2tnU3o5QjhNWnVSM2tqWWZnTUxNVVJKQ1hOIg.FoPF3g.KUMZDC4U_ek-B6cqPLYilXniQv8}
                  // print("======================");

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
