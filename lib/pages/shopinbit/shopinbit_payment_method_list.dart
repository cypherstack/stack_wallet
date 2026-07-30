import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../app_config.dart';
import '../../notifications/show_flush_bar.dart';
import '../../providers/providers.dart';
import '../../themes/coin_icon_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/address_utils.dart';
import '../../utilities/assets.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/dialogs/s_dialog.dart';
import '../../widgets/dialogs/simple_mobile_dialog.dart';
import '../../widgets/icon_widgets/copy_icon.dart';
import '../../widgets/qr.dart';
import '../../widgets/rounded_container.dart';
import '../../widgets/rounded_white_container.dart';
import 'shopinbit_payment_shared.dart';

class ShopInBitPaymentMethodList extends ConsumerStatefulWidget {
  const ShopInBitPaymentMethodList({
    super.key,
    required this.methods,
    required this.addresses,
    required this.enabled,
    required this.onPayFromWallet,
    required this.onCheckForPayment,
  });

  final List<String> methods;
  final List<String> addresses;
  final bool enabled;
  final ValueChanged<int> onPayFromWallet;
  final ValueChanged<int> onCheckForPayment;

  @override
  ConsumerState<ShopInBitPaymentMethodList> createState() =>
      _ShopInBitPaymentMethodListState();
}

class _ShopInBitPaymentMethodListState
    extends ConsumerState<ShopInBitPaymentMethodList> {
  int? _openIndex;
  String? _openTicker;
  String? _openAddress;
  BuildContext? _dialogContext;
  bool _dismissScheduled = false;

  bool get _openPaymentIsCurrent {
    final index = _openIndex;
    return mounted &&
        widget.enabled &&
        index != null &&
        index < widget.methods.length &&
        index < widget.addresses.length &&
        widget.methods[index].toUpperCase() == _openTicker &&
        widget.addresses[index] == _openAddress;
  }

  void _dismissPaymentDetails() {
    final dialogContext = _dialogContext;
    if (dialogContext == null || _dismissScheduled) return;
    _dismissScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dismissScheduled = false;
      final route = ModalRoute.of(dialogContext);
      if (dialogContext.mounted && route != null && route.isActive) {
        Navigator.of(dialogContext).removeRoute(route);
      }
    });
  }

  @override
  void didUpdateWidget(ShopInBitPaymentMethodList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dialogContext != null && !_openPaymentIsCurrent) {
      _dismissPaymentDetails();
    }
  }

  @override
  void dispose() {
    _dismissPaymentDetails();
    super.dispose();
  }

  String? _parseAmount(String paymentUri) {
    final parsed = AddressUtils.parsePaymentUri(paymentUri);
    String? amount = parsed?.amount;
    if (amount == null || amount.isEmpty) {
      amount = Uri.tryParse(paymentUri)?.queryParameters["amount"];
    }
    return amount == null || amount.isEmpty ? null : amount;
  }

  Future<void> _showPaymentDetails(
    BuildContext context,
    int index,
    String ticker,
    String address,
  ) async {
    _openIndex = index;
    _openTicker = ticker;
    _openAddress = address;
    try {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        builder: (ctx) {
          _dialogContext = ctx;
          return _ExternalPaymentDialog(
            ticker: ticker,
            address: address,
            onCheckForPayment: () {
              final isCurrent = _openPaymentIsCurrent;
              Navigator.of(ctx).pop();
              if (isCurrent) {
                widget.onCheckForPayment(index);
              }
            },
          );
        },
      );
    } finally {
      _openIndex = null;
      _openTicker = null;
      _openAddress = null;
      _dialogContext = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final methods = widget.methods;
    final addresses = widget.addresses;
    final enabled = widget.enabled;
    final count = methods.length < addresses.length
        ? methods.length
        : addresses.length;
    if (count == 0) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          "No payment address available",
          textAlign: TextAlign.center,
          style: STextStyles.itemSubtitle(context),
        ),
      );
    }

    final wallets = ref.watch(pWallets);
    final rows = <Widget>[];

    for (var i = 0; i < count; i++) {
      final ticker = methods[i].toUpperCase();
      final address = addresses[i];
      final coin = AppConfig.getCryptoCurrencyForTicker(ticker);
      final hasAddress = address.isNotEmpty;
      final hasWallet = hasShopInBitWalletForTicker(
        wallets: wallets,
        ticker: ticker,
        paymentUri: address,
      );
      final canPayNow = hasWallet && hasAddress;
      final amount = hasAddress ? _parseAmount(address) : null;

      if (i > 0) {
        rows.add(const SizedBox(height: 8));
      }

      rows.add(
        RoundedWhiteContainer(
          child: Opacity(
            opacity: enabled && canPayNow ? 1 : 0.5,
            child: InkWell(
              onTap: !enabled || !hasAddress
                  ? null
                  : hasWallet
                  ? () => widget.onPayFromWallet(i)
                  : () => unawaited(
                      _showPaymentDetails(context, i, ticker, address),
                    ),
              child: Row(
                children: [
                  if (coin != null)
                    SvgPicture.file(
                      File(ref.watch(coinIconProvider(coin))),
                      width: 24,
                      height: 24,
                    )
                  else
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Center(
                        child: Text(
                          ticker.substring(
                            0,
                            ticker.length > 2 ? 2 : ticker.length,
                          ),
                          style: STextStyles.itemSubtitle12(context),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ticker, style: STextStyles.titleBold12(context)),
                        if (amount != null)
                          Text(
                            "$amount $ticker",
                            style: STextStyles.itemSubtitle12(context),
                          ),
                      ],
                    ),
                  ),
                  if (canPayNow)
                    Text("PAY NOW", style: STextStyles.link2(context))
                  else
                    SvgPicture.asset(
                      Assets.svg.circleInfo,
                      width: 18,
                      height: 18,
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.textSubtitle2,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class _ExternalPaymentDialog extends StatelessWidget {
  const _ExternalPaymentDialog({
    required this.ticker,
    required this.address,
    required this.onCheckForPayment,
  });

  final String ticker;
  final String address;
  final VoidCallback onCheckForPayment;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final showUsdtWarning =
        ticker == "USDT" && !isShopInBitEthereumUsdtUri(address);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: QR(data: address, size: isDesktop ? 200 : 180),
        ),
        if (showUsdtWarning) SizedBox(height: isDesktop ? 24 : 16),
        if (showUsdtWarning)
          RoundedContainer(
            color: Theme.of(
              context,
            ).extension<StackColors>()!.warningBackground,
            child: Center(
              child: Text(
                "IMPORTANT: Only send USDT (TRC20) to this address, not TRX",
                style: (isDesktop
                    ? STextStyles.desktopTextExtraExtraSmall(context)
                    : STextStyles.itemSubtitle12(context).copyWith(
                        color: Theme.of(
                          context,
                        ).extension<StackColors>()!.warningForeground,
                      )),
              ),
            ),
          ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: address));
            if (!context.mounted) return;
            unawaited(
              showFloatingFlushBar(
                type: FlushBarType.info,
                message: "Copied to clipboard",
                iconAsset: Assets.svg.copy,
                context: context,
              ),
            );
          },
          child: RoundedWhiteContainer(
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      "$ticker address",
                      style: isDesktop
                          ? STextStyles.desktopTextExtraExtraSmall(context)
                          : STextStyles.itemSubtitle12(context),
                    ),
                    const Spacer(),
                    CopyIcon(
                      width: isDesktop ? 15 : 10,
                      height: isDesktop ? 15 : 10,
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.infoItemIcons,
                    ),
                    const SizedBox(width: 4),
                    Text("Copy", style: STextStyles.link2(context)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        address,
                        style: isDesktop
                            ? STextStyles.desktopTextExtraExtraSmall(context)
                            : STextStyles.itemSubtitle12(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(label: "CHECK FOR PAYMENT", onPressed: onCheckForPayment),
      ],
    );

    if (!isDesktop) {
      return SimpleMobileDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("$ticker Payment", style: STextStyles.pageTitleH2(context)),
            const SizedBox(height: 16),
            content,
          ],
        ),
      );
    }

    return SDialog(
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    "$ticker Payment",
                    style: STextStyles.desktopH3(context),
                  ),
                ),
                const DesktopDialogCloseButton(),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
                  child: content,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
