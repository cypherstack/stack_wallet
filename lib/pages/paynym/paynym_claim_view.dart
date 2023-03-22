import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackduo/pages/paynym/dialogs/claiming_paynym_dialog.dart';
import 'package:stackduo/pages/paynym/paynym_home_view.dart';
import 'package:stackduo/pages/wallet_view/wallet_view.dart';
import 'package:stackduo/providers/global/paynym_api_provider.dart';
import 'package:stackduo/providers/global/wallets_provider.dart';
import 'package:stackduo/providers/wallet/my_paynym_account_state_provider.dart';
import 'package:stackduo/services/mixins/paynym_wallet_interface.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/enums/derive_path_type_enum.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/utilities/util.dart';
import 'package:stackduo/widgets/conditional_parent.dart';
import 'package:stackduo/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackduo/widgets/desktop/desktop_app_bar.dart';
import 'package:stackduo/widgets/desktop/desktop_scaffold.dart';
import 'package:stackduo/widgets/desktop/primary_button.dart';

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
      appBar: isDesktop
          ? DesktopAppBar(
              isCompactHeight: true,
              background: Theme.of(context).extension<StackColors>()!.popupBG,
              leading: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 20,
                    ),
                    child: AppBarIconButton(
                      size: 32,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textFieldDefaultBG,
                      shadows: const [],
                      icon: SvgPicture.asset(
                        Assets.svg.arrowLeft,
                        width: 18,
                        height: 18,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .topNavIconPrimary,
                      ),
                      onPressed: Navigator.of(context).pop,
                    ),
                  ),
                  SvgPicture.asset(
                    Assets.svg.user,
                    width: 42,
                    height: 42,
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    "PayNym",
                    style: STextStyles.desktopH3(context),
                  )
                ],
              ),
            )
          : AppBar(
              leading: const AppBarBackButton(),
              titleSpacing: 0,
              title: Text(
                "PayNym",
                style: STextStyles.navBarTitle(context),
                overflow: TextOverflow.ellipsis,
              ),
            ),
      body: ConditionalParent(
        condition: !isDesktop,
        builder: (child) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
        child: ConditionalParent(
          condition: isDesktop,
          builder: (child) => SizedBox(
            width: 328,
            child: child,
          ),
          child: Column(
            children: [
              const Spacer(
                flex: 1,
              ),
              SvgPicture.asset(
                Assets.svg.unclaimedPaynym,
                width: MediaQuery.of(context).size.width / 2,
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                "You do not have a PayNym yet.\nClaim yours now!",
                style: isDesktop
                    ? STextStyles.desktopSubtitleH2(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textSubtitle1,
                      )
                    : STextStyles.baseXS(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textSubtitle1,
                      ),
                textAlign: TextAlign.center,
              ),
              if (isDesktop)
                const SizedBox(
                  height: 30,
                ),
              if (!isDesktop)
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

                  final manager = ref
                      .read(walletsChangeNotifierProvider)
                      .getManager(widget.walletId);

                  // get wallet to access paynym calls
                  final wallet = manager.wallet as PaynymWalletInterface;

                  if (shouldCancel) return;

                  // get payment code
                  final pCode = await wallet.getPaymentCode(
                      DerivePathTypeExt.primaryFor(manager.coin));

                  if (shouldCancel) return;

                  // attempt to create new entry in paynym.is db
                  final created = await ref
                      .read(paynymAPIProvider)
                      .create(pCode.toString());

                  debugPrint("created:$created");
                  if (shouldCancel) return;

                  if (created.value!.claimed) {
                    // payment code already claimed
                    debugPrint("pcode already claimed!!");
                    if (mounted) {
                      if (isDesktop) {
                        Navigator.of(context, rootNavigator: true).pop();
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).popUntil(
                          ModalRoute.withName(
                            WalletView.routeName,
                          ),
                        );
                      }
                    }
                    return;
                  }

                  if (shouldCancel) return;

                  final token =
                      await ref.read(paynymAPIProvider).token(pCode.toString());

                  if (shouldCancel) return;

                  // sign token with notification private key
                  final signature =
                      await wallet.signStringWithNotificationKey(token.value!);

                  if (shouldCancel) return;

                  // claim paynym account
                  final claim = await ref
                      .read(paynymAPIProvider)
                      .claim(token.value!, signature);

                  if (shouldCancel) return;

                  if (claim.value?.claimed == pCode.toString()) {
                    final account =
                        await ref.read(paynymAPIProvider).nym(pCode.toString());

                    ref.read(myPaynymAccountStateProvider.state).state =
                        account.value!;
                    if (mounted) {
                      if (isDesktop) {
                        Navigator.of(context, rootNavigator: true).pop();
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).popUntil(
                          ModalRoute.withName(
                            WalletView.routeName,
                          ),
                        );
                      }
                      await Navigator.of(context).pushNamed(
                        PaynymHomeView.routeName,
                        arguments: widget.walletId,
                      );
                    }
                  } else if (mounted && !shouldCancel) {
                    Navigator.of(context, rootNavigator: isDesktop).pop();
                  }
                },
              ),
              if (isDesktop)
                const Spacer(
                  flex: 2,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
