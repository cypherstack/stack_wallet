import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../app_config.dart';
import '../../models/isar/models/blockchain_data/address.dart';
import '../../providers/providers.dart';
import '../../route_generator.dart';
import '../../themes/coin_icon_provider.dart';
import '../../themes/stack_colors.dart';
import '../../themes/theme_providers.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/amount/amount_formatter.dart';
import '../../utilities/constants.dart';
import '../../utilities/enums/fee_rate_type_enum.dart';
import '../../utilities/logger.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../../wallets/isar/providers/wallet_info_provider.dart';
import '../../wallets/models/tx_data.dart';
import '../../wallets/wallet/intermediate/external_wallet.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_dialog.dart';
import '../../pages_desktop_specific/desktop_home_view.dart';
import '../home_view/home_view.dart';
import '../send_view/sub_widgets/building_transaction_dialog.dart';
import 'cakepay_confirm_send_view.dart';

class CakePaySendFromView extends ConsumerStatefulWidget {
  const CakePaySendFromView({
    super.key,
    this.coin,
    this.amount,
    required this.address,
    required this.orderId,
    this.shouldPopRoot = false,
  });

  static const String routeName = "/cakePaySendFrom";

  final CryptoCurrency? coin;
  final Amount? amount;
  final String address;
  final String orderId;
  final bool shouldPopRoot;

  @override
  ConsumerState<CakePaySendFromView> createState() =>
      _CakePaySendFromViewState();
}

class _CakePaySendFromViewState extends ConsumerState<CakePaySendFromView> {
  @override
  Widget build(BuildContext context) {
    final List<String> walletIds;
    if (widget.coin != null) {
      walletIds = ref
          .watch(pWallets)
          .wallets
          .where((e) => e.info.coin == widget.coin)
          .map((e) => e.walletId)
          .toList();
    } else {
      walletIds = ref.watch(pWallets).wallets.map((e) => e.walletId).toList();
    }

    final isDesktop = Util.isDesktop;

    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) {
        return Background(
          child: Scaffold(
            backgroundColor: Theme.of(
              context,
            ).extension<StackColors>()!.background,
            appBar: AppBar(
              leading: AppBarBackButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text("Send from", style: STextStyles.navBarTitle(context)),
            ),
            body: SafeArea(
              child: Padding(padding: const EdgeInsets.all(16), child: child),
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
                    padding: const EdgeInsets.only(left: 32),
                    child: Text(
                      "Send from ${AppConfig.prefix}",
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
                padding: const EdgeInsets.only(left: 32, right: 32, bottom: 32),
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
                  widget.amount != null && widget.coin != null
                      ? "You need to send ${ref.watch(pAmountFormatter(widget.coin!)).format(widget.amount!)}"
                      : "Select a wallet to pay",
                  style: isDesktop
                      ? STextStyles.desktopTextExtraExtraSmall(context)
                      : STextStyles.itemSubtitle(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ConditionalParent(
              condition: !isDesktop,
              builder: (child) => Expanded(child: child),
              child: ListView.builder(
                primary: isDesktop ? false : null,
                shrinkWrap: isDesktop,
                itemCount: walletIds.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _CakePaySendFromCard(
                      walletId: walletIds[index],
                      amount: widget.amount,
                      address: widget.address,
                      orderId: widget.orderId,
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

class _CakePaySendFromCard extends ConsumerStatefulWidget {
  const _CakePaySendFromCard({
    required this.walletId,
    this.amount,
    required this.address,
    required this.orderId,
  });

  final String walletId;
  final Amount? amount;
  final String address;
  final String orderId;

  @override
  ConsumerState<_CakePaySendFromCard> createState() =>
      _CakePaySendFromCardState();
}

class _CakePaySendFromCardState extends ConsumerState<_CakePaySendFromCard> {
  Future<void> _send() async {
    final coin = ref.read(pWalletCoin(widget.walletId));
    final Amount? sendAmount = widget.amount;

    if (sendAmount == null) {
      await showDialog<dynamic>(
        context: context,
        useSafeArea: false,
        barrierDismissible: true,
        builder: (context) {
          return StackDialog(
            title: "Transaction failed",
            message: "Payment amount not available yet",
            rightButton: TextButton(
              style: Theme.of(context)
                  .extension<StackColors>()!
                  .getSecondaryEnabledButtonStyle(context),
              child: Text(
                "Ok",
                style: STextStyles.button(context).copyWith(
                  color: Theme.of(
                    context,
                  ).extension<StackColors>()!.buttonTextSecondary,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          );
        },
      );
      return;
    }

    bool wasCancelled = false;

    try {
      final wallet = ref.read(pWallets).getWallet(widget.walletId);

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
                child: Padding(padding: const EdgeInsets.all(32), child: child),
              ),
              child: BuildingTransactionDialog(
                coin: coin,
                isSpark: false,
                onCancel: () {
                  wasCancelled = true;
                  Navigator.of(context).pop();
                },
              ),
            );
          },
        ),
      );

      if (wallet is ExternalWallet) {
        await wallet.init();
        await wallet.open();
      }

      final time = Future<dynamic>.delayed(const Duration(milliseconds: 2500));

      final addressType =
          wallet.cryptoCurrency.getAddressType(widget.address) ??
          AddressType.unknown;

      final recipient = TxRecipient(
        address: widget.address,
        amount: sendAmount,
        isChange: false,
        addressType: addressType,
      );

      final txDataFuture = wallet.prepareSend(
        txData: TxData(
          recipients: [recipient],
          feeRateType: FeeRateType.average,
        ),
      );

      final results = await Future.wait([txDataFuture, time]);

      final txData = (results.first as TxData).copyWith(
        note: "CakePay payment",
      );

      if (!wasCancelled) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        if (mounted) {
          await Navigator.of(context).push(
            RouteGenerator.getRoute<dynamic>(
              shouldUseMaterialRoute: RouteGenerator.useMaterialPageRoute,
              builder: (_) => CakePayConfirmSendView(
                txData: txData,
                walletId: widget.walletId,
                routeOnSuccessName: Util.isDesktop
                    ? DesktopHomeView.routeName
                    : HomeView.routeName,
                orderId: widget.orderId,
              ),
              settings: const RouteSettings(
                name: CakePayConfirmSendView.routeName,
              ),
            ),
          );
        }
      }
    } catch (e, s) {
      Logging.instance.e("$e\n$s", error: e, stackTrace: s);
      if (mounted && !wasCancelled) {
        Navigator.of(context, rootNavigator: true).pop();

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
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.buttonTextSecondary,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coin = ref.watch(pWalletCoin(widget.walletId));

    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(0),
      child: MaterialButton(
        splashColor: Theme.of(context).extension<StackColors>()!.highlight,
        key: Key("cakePayWalletKey_${widget.walletId}"),
        padding: const EdgeInsets.all(8),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
        ),
        onPressed: () async {
          if (mounted) unawaited(_send());
        },
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: ref.watch(pCoinColor(coin)).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: SvgPicture.file(
                  File(ref.watch(coinIconProvider(coin))),
                  width: 24,
                  height: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ref.watch(pWalletName(widget.walletId)),
                    style: STextStyles.titleBold12(context),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ref
                        .watch(pAmountFormatter(coin))
                        .format(
                          ref.watch(pWalletBalance(widget.walletId)).spendable,
                        ),
                    style: STextStyles.itemSubtitle(context),
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
