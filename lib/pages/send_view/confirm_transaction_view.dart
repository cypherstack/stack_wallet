import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:epicmobile/pages/pinpad_views/lock_screen_view.dart';
import 'package:epicmobile/pages/send_view/sub_widgets/sending_transaction_dialog.dart';
import 'package:epicmobile/pages/wallet_view/wallet_view.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/route_generator.dart';
import 'package:epicmobile/services/coins/epiccash/epiccash_wallet.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/format.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/utilities/util.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/conditional_parent.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/desktop/primary_button.dart';
import 'package:epicmobile/widgets/rounded_container.dart';
import 'package:epicmobile/widgets/rounded_white_container.dart';
import 'package:epicmobile/widgets/stack_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

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
  late final bool isDesktop;

  int _fee = 12;
  final List<int> _dropDownItems = [
    12,
    22,
    234,
  ];

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
    final manager = ref.read(walletProvider)!;

    try {
      String txid;
      final coin = manager.coin;
      txid = await manager.confirmSend(txData: transactionInfo);

      // save note
      await ref
          .read(notesServiceChangeNotifierProvider(walletId))
          .editOrAddNote(txid: txid, note: note);

      unawaited(manager.refresh());

      // pop back to wallet
      if (mounted) {
        Navigator.of(context).popUntil(ModalRoute.withName(routeOnSuccessName));
      }
    } on BadEpicHttpAddressException catch (_) {
      if (mounted) {
        // pop building dialog
        Navigator.of(context).pop();
        // unawaited(
        // showFloatingFlushBar(
        //   type: FlushBarType.warning,
        //   message:
        //       "Connection failed. Please check the address and try again.",
        //   context: context,
        // ),
        // );
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
              style: Theme.of(context)
                  .extension<StackColors>()!
                  .getSecondaryEnabledButtonColor(context),
              child: Text(
                "Ok",
                style: STextStyles.button(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .accentColorDark),
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
    isDesktop = Util.isDesktop;
    transactionInfo = widget.transactionInfo;
    walletId = widget.walletId;
    routeOnSuccessName = widget.routeOnSuccessName;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) => Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
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
              style: STextStyles.navBarTitle(context),
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
                        child: child,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      child: ConditionalParent(
        condition: isDesktop,
        builder: (child) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                AppBarBackButton(
                  size: 40,
                  iconSize: 24,
                  onPressed: () => Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pop(),
                ),
                Text(
                  "Confirm ${ref.watch(walletProvider.select((value) => value!.coin.ticker.toUpperCase()))} transaction",
                  style: STextStyles.desktopH3(context),
                ),
              ],
            ),
            child,
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: isDesktop ? MainAxisSize.min : MainAxisSize.max,
          children: [
            if (!isDesktop)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Send ${ref.watch(walletProvider.select((value) => value!.coin)).ticker}",
                    style: STextStyles.pageTitleH1(context),
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
                          style: STextStyles.smallMed12(context),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          "${transactionInfo["address"] ?? "ERROR"}",
                          style: STextStyles.itemSubtitle12(context),
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
                          style: STextStyles.smallMed12(context),
                        ),
                        Text(
                          "${Format.satoshiAmountToPrettyString(
                            transactionInfo["recipientAmt"] as int,
                            ref.watch(
                              localeServiceChangeNotifierProvider
                                  .select((value) => value.locale),
                            ),
                          )} ${ref.watch(
                                walletProvider.select((value) => value!.coin),
                              ).ticker}",
                          style: STextStyles.itemSubtitle12(context),
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
                          style: STextStyles.smallMed12(context),
                        ),
                        Text(
                          "${Format.satoshiAmountToPrettyString(
                            transactionInfo["fee"] as int,
                            ref.watch(
                              localeServiceChangeNotifierProvider
                                  .select((value) => value.locale),
                            ),
                          )} ${ref.watch(
                                walletProvider.select((value) => value!.coin),
                              ).ticker}",
                          style: STextStyles.itemSubtitle12(context),
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
                          style: STextStyles.smallMed12(context),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          transactionInfo["note"] as String,
                          style: STextStyles.itemSubtitle12(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            if (isDesktop)
              Padding(
                padding: const EdgeInsets.only(
                  top: 16,
                  left: 32,
                  right: 32,
                  bottom: 50,
                ),
                child: RoundedWhiteContainer(
                  padding: const EdgeInsets.all(0),
                  borderColor:
                      Theme.of(context).extension<StackColors>()!.background,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .background,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(
                              Constants.size.circularBorderRadius,
                            ),
                            topRight: Radius.circular(
                              Constants.size.circularBorderRadius,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 22,
                          ),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                Assets.svg.send(context),
                                width: 32,
                                height: 32,
                              ),
                              const SizedBox(
                                width: 16,
                              ),
                              Text(
                                "Send ${ref.watch(
                                      walletProvider
                                          .select((value) => value!.coin),
                                    ).ticker}",
                                style: STextStyles.desktopTextMedium(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Amount",
                              style: STextStyles.desktopTextExtraExtraSmall(
                                  context),
                            ),
                            const SizedBox(
                              height: 2,
                            ),
                            Builder(
                              builder: (context) {
                                final amount =
                                    transactionInfo["recipientAmt"] as int;
                                final coin = ref.watch(
                                  walletProvider.select(
                                    (value) => value!.coin,
                                  ),
                                );

                                String fiatAmount = "N/A";

                                final price = ref
                                    .read(priceAnd24hChangeNotifierProvider)
                                    .getPrice(coin)
                                    .item1;
                                if (price > Decimal.zero) {
                                  fiatAmount = Format.localizedStringAsFixed(
                                    value: Format.satoshisToAmount(amount,
                                            coin: coin) *
                                        price,
                                    locale: ref
                                        .read(
                                            localeServiceChangeNotifierProvider)
                                        .locale,
                                    decimalPlaces: 2,
                                  );
                                }

                                return Row(
                                  children: [
                                    Text(
                                      "${Format.satoshiAmountToPrettyString(
                                        amount,
                                        ref.watch(
                                          localeServiceChangeNotifierProvider
                                              .select((value) => value.locale),
                                        ),
                                      )} ${coin.ticker}",
                                      style: STextStyles
                                              .desktopTextExtraExtraSmall(
                                                  context)
                                          .copyWith(
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .textDark,
                                      ),
                                    ),
                                    Text(
                                      " | ",
                                      style: STextStyles
                                          .desktopTextExtraExtraSmall(context),
                                    ),
                                    Text(
                                      "~$fiatAmount ${ref.watch(prefsChangeNotifierProvider.select(
                                        (value) => value.currency,
                                      ))}",
                                      style: STextStyles
                                          .desktopTextExtraExtraSmall(context),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 1,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .background,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Send to",
                              style: STextStyles.desktopTextExtraExtraSmall(
                                  context),
                            ),
                            const SizedBox(
                              height: 2,
                            ),
                            Text(
                              "${transactionInfo["address"] ?? "ERROR"}",
                              style: STextStyles.desktopTextExtraExtraSmall(
                                      context)
                                  .copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textDark,
                              ),
                            )
                          ],
                        ),
                      ),
                      Container(
                        height: 1,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .background,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Note",
                              style: STextStyles.desktopTextExtraExtraSmall(
                                  context),
                            ),
                            const SizedBox(
                              height: 2,
                            ),
                            Text(
                              transactionInfo["note"] as String,
                              style: STextStyles.desktopTextExtraExtraSmall(
                                      context)
                                  .copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textDark,
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (isDesktop)
              Padding(
                padding: const EdgeInsets.only(
                  left: 32,
                ),
                child: Text(
                  "Transaction fee (estimated)",
                  style: STextStyles.desktopTextExtraExtraSmall(context),
                ),
              ),
            if (isDesktop)
              Padding(
                padding: const EdgeInsets.only(
                  top: 10,
                  left: 32,
                  right: 32,
                ),
                child: DropdownButtonFormField(
                  value: _fee,
                  items: _dropDownItems
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            e.toString(),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value is int) {
                      setState(() {
                        _fee = value;
                      });
                    }
                  },
                ),
              ),
            if (!isDesktop) const Spacer(),
            SizedBox(
              height: isDesktop ? 23 : 12,
            ),
            Padding(
              padding: isDesktop
                  ? const EdgeInsets.symmetric(
                      horizontal: 32,
                    )
                  : const EdgeInsets.all(0),
              child: RoundedContainer(
                padding: isDesktop
                    ? const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      )
                    : const EdgeInsets.all(12),
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .snackBarBackSuccess,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isDesktop ? "Total amount to send" : "Total amount",
                      style: isDesktop
                          ? STextStyles.desktopTextExtraExtraSmall(context)
                              .copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textConfirmTotalAmount,
                            )
                          : STextStyles.titleBold12(context).copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textConfirmTotalAmount,
                            ),
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
                            walletProvider.select((value) => value!.coin),
                          ).ticker}",
                      style: isDesktop
                          ? STextStyles.desktopTextExtraExtraSmall(context)
                              .copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textConfirmTotalAmount,
                            )
                          : STextStyles.itemSubtitle12(context).copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textConfirmTotalAmount,
                            ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: isDesktop ? 28 : 16,
            ),
            Padding(
              padding: isDesktop
                  ? const EdgeInsets.symmetric(
                      horizontal: 32,
                    )
                  : const EdgeInsets.all(0),
              child: PrimaryButton(
                label: "Send",
                desktopMed: true,
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
                        biometricsAuthenticationTitle: "Confirm Transaction",
                      ),
                      settings:
                          const RouteSettings(name: "/confirmsendlockscreen"),
                    ),
                  );

                  if (unlocked is bool && unlocked && mounted) {
                    unawaited(_attemptSend(context));
                  }
                },
              ),
            ),
            if (isDesktop)
              const SizedBox(
                height: 32,
              ),
          ],
        ),
      ),
    );
  }
}
