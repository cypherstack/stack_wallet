import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/pinpad_views/lock_screen_view.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/sending_transaction_dialog.dart';
import 'package:stackwallet/pages/wallet_view/wallet_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/providers/wallet/public_private_balance_state_provider.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/services/coins/epiccash/epiccash_wallet.dart';
import 'package:stackwallet/services/coins/firo/firo_wallet.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class ConfirmTransactionView extends ConsumerStatefulWidget {
  const ConfirmTransactionView({
    Key? key,
    required this.transactionInfo,
    required this.walletId,
    this.routeOnSuccessName = WalletView.routeName,
  }) : super(key: key);

  static const String routeName = "/confirmTransactionView";

  final Map<String, dynamic> transactionInfo;
  final String walletId;
  final String routeOnSuccessName;

  @override
  ConsumerState<ConfirmTransactionView> createState() =>
      _ConfirmTransactionViewState();
}

class _ConfirmTransactionViewState
    extends ConsumerState<ConfirmTransactionView> {
  late final Map<String, dynamic> transactionInfo;
  late final String walletId;
  late final String routeOnSuccessName;

  Future<void> _attemptSend(BuildContext context) async {
    unawaited(showDialog<dynamic>(
      context: context,
      useSafeArea: false,
      barrierDismissible: false,
      builder: (context) {
        return const SendingTransactionDialog();
      },
    ));

    final note = transactionInfo["note"] as String? ?? "";
    final manager =
        ref.read(walletsChangeNotifierProvider).getManager(walletId);

    try {
      String txid;
      final coin = manager.coin;
      if ((coin == Coin.firo || coin == Coin.firoTestNet) &&
          ref.read(publicPrivateBalanceStateProvider.state).state !=
              "Private") {
        txid = await (manager.wallet as FiroWallet)
            .confirmSendPublic(txData: transactionInfo);
      } else {
        txid = await manager.confirmSend(txData: transactionInfo);
      }

      unawaited(manager.refresh());

      // save note
      await ref
          .read(notesServiceChangeNotifierProvider(walletId))
          .editOrAddNote(txid: txid, note: note);

      // pop back to wallet
      if (mounted) {
        Navigator.of(context).popUntil(ModalRoute.withName(routeOnSuccessName));
      }
    } on BadEpicHttpAddressException catch (_) {
      if (mounted) {
        // pop building dialog
        Navigator.of(context).pop();
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.warning,
            message:
                "Connection failed. Please check the address and try again.",
            context: context,
          ),
        );
        return;
      }
    } catch (e, s) {
      debugPrint("$e\n$s");
      // pop sending dialog
      Navigator.of(context).pop();

      await showDialog<void>(
        context: context,
        useSafeArea: false,
        barrierDismissible: true,
        builder: (context) {
          return StackDialog(
            title: "Broadcast transaction failed",
            message: e.toString(),
            rightButton: TextButton(
              style:
                  StackTheme.instance.getSecondaryEnabledButtonColor(context),
              child: Text(
                "Ok",
                style: STextStyles.button.copyWith(
                  color: CFColors.stackAccent,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          );
        },
      );
    }
  }

  @override
  void initState() {
    transactionInfo = widget.transactionInfo;
    walletId = widget.walletId;
    routeOnSuccessName = widget.routeOnSuccessName;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final managerProvider = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManagerProvider(walletId)));
    return Scaffold(
      appBar: AppBar(
        backgroundColor: StackTheme.instance.color.background,
        leading: AppBarBackButton(
          onPressed: () async {
            // if (FocusScope.of(context).hasFocus) {
            //   FocusScope.of(context).unfocus();
            //   await Future<void>.delayed(Duration(milliseconds: 50));
            // }
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "Confirm transaction",
          style: STextStyles.navBarTitle,
        ),
      ),
      body: LayoutBuilder(
        builder: (builderContext, constraints) {
          return Padding(
            padding: const EdgeInsets.only(
              left: 12,
              top: 12,
              right: 12,
            ),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Send ${ref.watch(managerProvider.select((value) => value.coin)).ticker}",
                          style: STextStyles.pageTitleH1,
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        RoundedWhiteContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Recipient",
                                style: STextStyles.smallMed12,
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                "${transactionInfo["address"] ?? "ERROR"}",
                                style: STextStyles.itemSubtitle12,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        RoundedWhiteContainer(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Amount",
                                style: STextStyles.smallMed12,
                              ),
                              Text(
                                "${Format.satoshiAmountToPrettyString(
                                  transactionInfo["recipientAmt"] as int,
                                  ref.watch(
                                    localeServiceChangeNotifierProvider
                                        .select((value) => value.locale),
                                  ),
                                )} ${ref.watch(
                                      managerProvider
                                          .select((value) => value.coin),
                                    ).ticker}",
                                style: STextStyles.itemSubtitle12,
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        RoundedWhiteContainer(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Transaction fee",
                                style: STextStyles.smallMed12,
                              ),
                              Text(
                                "${Format.satoshiAmountToPrettyString(
                                  transactionInfo["fee"] as int,
                                  ref.watch(
                                    localeServiceChangeNotifierProvider
                                        .select((value) => value.locale),
                                  ),
                                )} ${ref.watch(
                                      managerProvider
                                          .select((value) => value.coin),
                                    ).ticker}",
                                style: STextStyles.itemSubtitle12,
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        RoundedWhiteContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Note",
                                style: STextStyles.smallMed12,
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                transactionInfo["note"] as String,
                                style: STextStyles.itemSubtitle12,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(
                          height: 12,
                        ),
                        RoundedContainer(
                          color: StackTheme.instance.color.snackBarBackSuccess,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total amount",
                                style: STextStyles.titleBold12,
                              ),
                              Text(
                                "${Format.satoshiAmountToPrettyString(
                                  (transactionInfo["fee"] as int) +
                                      (transactionInfo["recipientAmt"] as int),
                                  ref.watch(
                                    localeServiceChangeNotifierProvider
                                        .select((value) => value.locale),
                                  ),
                                )} ${ref.watch(
                                      managerProvider
                                          .select((value) => value.coin),
                                    ).ticker}",
                                style: STextStyles.itemSubtitle12,
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        TextButton(
                          style:
                              Theme.of(context).textButtonTheme.style?.copyWith(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      CFColors.stackAccent,
                                    ),
                                  ),
                          onPressed: () async {
                            final unlocked = await Navigator.push(
                              context,
                              RouteGenerator.getRoute(
                                shouldUseMaterialRoute:
                                    RouteGenerator.useMaterialPageRoute,
                                builder: (_) => const LockscreenView(
                                  showBackButton: true,
                                  popOnSuccess: true,
                                  routeOnSuccessArguments: true,
                                  routeOnSuccess: "",
                                  biometricsCancelButtonString: "CANCEL",
                                  biometricsLocalizedReason:
                                      "Authenticate to send transaction",
                                  biometricsAuthenticationTitle:
                                      "Confirm Transaction",
                                ),
                                settings: const RouteSettings(
                                    name: "/confirmsendlockscreen"),
                              ),
                            );

                            if (unlocked is bool && unlocked && mounted) {
                              unawaited(_attemptSend(context));
                            }
                          },
                          child: Text(
                            "Send",
                            style: STextStyles.button,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
