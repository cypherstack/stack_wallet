import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/pages/exchange_view/confirm_change_now_send.dart';
import 'package:stackwallet/pages/home_view/home_view.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/building_transaction_dialog.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/desktop_exchange_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/services/coins/firo/firo_wallet.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/coin_icon_provider.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/expandable.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class SendFromView extends ConsumerStatefulWidget {
  const SendFromView({
    Key? key,
    required this.coin,
    required this.trade,
    required this.amount,
    required this.address,
    this.shouldPopRoot = false,
    this.fromDesktopStep4 = false,
  }) : super(key: key);

  static const String routeName = "/sendFrom";

  final Coin coin;
  final Amount amount;
  final String address;
  final Trade trade;
  final bool shouldPopRoot;
  final bool fromDesktopStep4;

  @override
  ConsumerState<SendFromView> createState() => _SendFromViewState();
}

class _SendFromViewState extends ConsumerState<SendFromView> {
  late final Coin coin;
  late final Amount amount;
  late final String address;
  late final Trade trade;

  @override
  void initState() {
    coin = widget.coin;
    address = widget.address;
    amount = widget.amount;
    trade = widget.trade;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final walletIds = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getWalletIdsFor(coin: coin)));

    final isDesktop = Util.isDesktop;

    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) {
        return Background(
          child: Scaffold(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
            appBar: AppBar(
              leading: AppBarBackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Text(
                "Send from",
                style: STextStyles.navBarTitle(context),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        );
      },
      child: ConditionalParent(
        condition: isDesktop,
        builder: (child) => DesktopDialog(
          maxHeight: double.infinity,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 32,
                    ),
                    child: Text(
                      "Send from Stack",
                      style: STextStyles.desktopH3(context),
                    ),
                  ),
                  DesktopDialogCloseButton(
                    onPressedOverride: Navigator.of(
                      context,
                      rootNavigator: widget.shouldPopRoot,
                    ).pop,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 32,
                  right: 32,
                  bottom: 32,
                ),
                child: child,
              ),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "You need to send ${amount.localizedStringAsFixed(
                    locale: ref.watch(
                      localeServiceChangeNotifierProvider.select(
                        (value) => value.locale,
                      ),
                    ),
                  )} ${coin.ticker}",
                  style: isDesktop
                      ? STextStyles.desktopTextExtraExtraSmall(context)
                      : STextStyles.itemSubtitle(context),
                ),
              ],
            ),
            const SizedBox(
              height: 16,
            ),
            ConditionalParent(
              condition: !isDesktop,
              builder: (child) => Expanded(
                child: child,
              ),
              child: ListView.builder(
                primary: isDesktop ? false : null,
                shrinkWrap: isDesktop,
                itemCount: walletIds.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: SendFromCard(
                      walletId: walletIds[index],
                      amount: amount,
                      address: address,
                      trade: trade,
                      fromDesktopStep4: widget.fromDesktopStep4,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SendFromCard extends ConsumerStatefulWidget {
  const SendFromCard({
    Key? key,
    required this.walletId,
    required this.amount,
    required this.address,
    required this.trade,
    this.fromDesktopStep4 = false,
  }) : super(key: key);

  final String walletId;
  final Amount amount;
  final String address;
  final Trade trade;
  final bool fromDesktopStep4;

  @override
  ConsumerState<SendFromCard> createState() => _SendFromCardState();
}

class _SendFromCardState extends ConsumerState<SendFromCard> {
  late final String walletId;
  late final Amount amount;
  late final String address;
  late final Trade trade;

  Future<void> _send(Manager manager, {bool? shouldSendPublicFiroFunds}) async {
    try {
      bool wasCancelled = false;

      unawaited(
        showDialog<dynamic>(
          context: context,
          useSafeArea: false,
          barrierDismissible: false,
          builder: (context) {
            return ConditionalParent(
              condition: Util.isDesktop,
              builder: (child) => DesktopDialog(
                maxWidth: 400,
                maxHeight: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: child,
                ),
              ),
              child: BuildingTransactionDialog(
                coin: manager.coin,
                onCancel: () {
                  wasCancelled = true;

                  Navigator.of(context).pop();
                },
              ),
            );
          },
        ),
      );

      final time = Future<dynamic>.delayed(
        const Duration(
          milliseconds: 2500,
        ),
      );

      Map<String, dynamic> txData;
      Future<Map<String, dynamic>> txDataFuture;

      // if not firo then do normal send
      if (shouldSendPublicFiroFunds == null) {
        txDataFuture = manager.prepareSend(
          address: address,
          amount: amount,
          args: {
            "feeRate": FeeRateType.average,
            // ref.read(feeRateTypeStateProvider)
          },
        );
      } else {
        final firoWallet = manager.wallet as FiroWallet;
        // otherwise do firo send based on balance selected
        if (shouldSendPublicFiroFunds) {
          txDataFuture = firoWallet.prepareSendPublic(
            address: address,
            amount: amount,
            args: {
              "feeRate": FeeRateType.average,
              // ref.read(feeRateTypeStateProvider)
            },
          );
        } else {
          txDataFuture = firoWallet.prepareSend(
            address: address,
            amount: amount,
            args: {
              "feeRate": FeeRateType.average,
              // ref.read(feeRateTypeStateProvider)
            },
          );
        }
      }

      final results = await Future.wait([
        txDataFuture,
        time,
      ]);

      txData = results.first as Map<String, dynamic>;

      if (!wasCancelled) {
        // pop building dialog

        if (mounted) {
          Navigator.of(
            context,
            rootNavigator: Util.isDesktop,
          ).pop();
        }

        txData["note"] =
            "${trade.payInCurrency.toUpperCase()}/${trade.payOutCurrency.toUpperCase()} exchange";
        txData["address"] = address;

        if (mounted) {
          await Navigator.of(context).push(
            RouteGenerator.getRoute(
              shouldUseMaterialRoute: RouteGenerator.useMaterialPageRoute,
              builder: (_) => ConfirmChangeNowSendView(
                transactionInfo: txData,
                walletId: walletId,
                routeOnSuccessName: Util.isDesktop
                    ? DesktopExchangeView.routeName
                    : HomeView.routeName,
                trade: trade,
                shouldSendPublicFiroFunds: shouldSendPublicFiroFunds,
                fromDesktopStep4: widget.fromDesktopStep4,
              ),
              settings: const RouteSettings(
                name: ConfirmChangeNowSendView.routeName,
              ),
            ),
          );
        }
      }
    } catch (e) {
      // if (mounted) {
      // pop building dialog
      Navigator.of(context).pop();

      await showDialog<dynamic>(
        context: context,
        useSafeArea: false,
        barrierDismissible: true,
        builder: (context) {
          return StackDialog(
            title: "Transaction failed",
            message: e.toString(),
            rightButton: TextButton(
              style: Theme.of(context)
                  .extension<StackColors>()!
                  .getSecondaryEnabledButtonStyle(context),
              child: Text(
                "Ok",
                style: STextStyles.button(context).copyWith(
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .buttonTextSecondary,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          );
        },
      );
      // }
    }
  }

  @override
  void initState() {
    walletId = widget.walletId;
    amount = widget.amount;
    address = widget.address;
    trade = widget.trade;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final manager = ref.watch(ref
        .watch(walletsChangeNotifierProvider.notifier)
        .getManagerProvider(walletId));

    final locale = ref.watch(
        localeServiceChangeNotifierProvider.select((value) => value.locale));

    final coin = manager.coin;

    final isFiro = coin == Coin.firoTestNet || coin == Coin.firo;

    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(0),
      child: ConditionalParent(
        condition: isFiro,
        builder: (child) => Expandable(
          header: Container(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MaterialButton(
                splashColor:
                    Theme.of(context).extension<StackColors>()!.highlight,
                key: Key("walletsSheetItemButtonFiroPrivateKey_$walletId"),
                padding: const EdgeInsets.all(0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                onPressed: () async {
                  if (mounted) {
                    unawaited(
                      _send(
                        manager,
                        shouldSendPublicFiroFunds: false,
                      ),
                    );
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 6,
                      left: 16,
                      right: 16,
                      bottom: 6,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Use private balance",
                              style: STextStyles.itemSubtitle(context),
                            ),
                            Text(
                              "${(manager.wallet as FiroWallet).availablePrivateBalance().localizedStringAsFixed(
                                    locale: locale,
                                  )} ${coin.ticker}",
                              style: STextStyles.itemSubtitle(context),
                            ),
                          ],
                        ),
                        SvgPicture.asset(
                          Assets.svg.chevronRight,
                          height: 14,
                          width: 7,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .infoItemLabel,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              MaterialButton(
                splashColor:
                    Theme.of(context).extension<StackColors>()!.highlight,
                key: Key("walletsSheetItemButtonFiroPublicKey_$walletId"),
                padding: const EdgeInsets.all(0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                onPressed: () async {
                  if (mounted) {
                    unawaited(
                      _send(
                        manager,
                        shouldSendPublicFiroFunds: true,
                      ),
                    );
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 6,
                      left: 16,
                      right: 16,
                      bottom: 6,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Use public balance",
                              style: STextStyles.itemSubtitle(context),
                            ),
                            Text(
                              "${(manager.wallet as FiroWallet).availablePublicBalance().localizedStringAsFixed(
                                    locale: locale,
                                  )} ${coin.ticker}",
                              style: STextStyles.itemSubtitle(context),
                            ),
                          ],
                        ),
                        SvgPicture.asset(
                          Assets.svg.chevronRight,
                          height: 14,
                          width: 7,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .infoItemLabel,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 6,
              ),
            ],
          ),
        ),
        child: ConditionalParent(
          condition: !isFiro,
          builder: (child) => MaterialButton(
            splashColor: Theme.of(context).extension<StackColors>()!.highlight,
            key: Key("walletsSheetItemButtonKey_$walletId"),
            padding: const EdgeInsets.all(8),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
            ),
            onPressed: () async {
              if (mounted) {
                unawaited(
                  _send(manager),
                );
              }
            },
            child: child,
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .colorForCoin(manager.coin)
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: SvgPicture.asset(
                    ref.watch(
                      coinIconProvider(coin),
                    ),
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manager.walletName,
                      style: STextStyles.titleBold12(context),
                    ),
                    if (!isFiro)
                      const SizedBox(
                        height: 2,
                      ),
                    if (!isFiro)
                      Text(
                        "${manager.balance.spendable.localizedStringAsFixed(
                          locale: locale,
                        )} ${coin.ticker}",
                        style: STextStyles.itemSubtitle(context),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
