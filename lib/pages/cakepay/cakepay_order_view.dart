import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_config.dart';
import '../../notifications/show_flush_bar.dart';
import '../../providers/global/cakepay_orders_provider.dart';
import '../../providers/providers.dart';
import '../../route_generator.dart';
import '../../services/cakepay/cakepay_orders_service.dart';
import '../../services/cakepay/src/models/order.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/assets.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/dialogs/nested_navigator_dialog/nested_navigator_dialog.dart';
import '../../widgets/dialogs/s_dialog.dart';
import '../../widgets/qr.dart';
import '../../widgets/refresh_control.dart';
import '../../widgets/rounded_white_container.dart';
import '../wallet_view/transaction_views/transaction_details_view.dart';
import 'cakepay_send_from_view.dart';

class CakePayOrderView extends ConsumerStatefulWidget {
  const CakePayOrderView({super.key, required this.order});

  static const String routeName = "/cakePayOrder";

  final CakePayOrder order;

  @override
  ConsumerState<CakePayOrderView> createState() => _CakePayOrderViewState();
}

class _CakePayOrderViewState extends ConsumerState<CakePayOrderView> {
  late final CakePayOrdersService _ordersService;
  Timer? _countdownTimer;
  int? _countdownExpiration;
  int _selectedPaymentMethod = 0;
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    _ordersService = ref.read(pCakePayOrdersService);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _polling = true;
      _ordersService.startPolling(widget.order.orderId);
    });
  }

  @override
  void dispose() {
    if (_polling) {
      _ordersService.stopPolling(widget.order.orderId);
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _ensureCountdown(int? expirationTime) {
    if (expirationTime == null) {
      if (_countdownTimer != null) {
        _countdownTimer?.cancel();
        _countdownTimer = null;
        _countdownExpiration = null;
      }
      return;
    }
    if (_countdownExpiration == expirationTime && _countdownTimer != null) {
      return;
    }
    _countdownExpiration = expirationTime;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = _computeRemaining(expirationTime);
      if (remaining <= Duration.zero) {
        _countdownTimer?.cancel();
        _countdownTimer = null;
        _countdownExpiration = null;
      }
      setState(() {});
    });
  }

  Duration _computeRemaining(int expirationTime) {
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(expirationTime);
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String _formatDuration(Duration d) {
    if (d.isNegative || d == Duration.zero) return "Expired";
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    if (d.inHours > 0) {
      return "${d.inHours}h ${minutes % 60}m ${seconds}s";
    }
    return "${minutes}m ${seconds}s";
  }

  void _navigateToSendFrom({
    required CryptoCurrency coin,
    required Amount? amount,
    required String address,
    required String orderId,
  }) {
    final isDesktop = Util.isDesktop;
    if (isDesktop) {
      showDialog<void>(
        context: context,
        builder: (_) => CakePaySendFromView(
          coin: coin,
          amount: amount,
          address: address,
          orderId: orderId,
          shouldPopRoot: true,
        ),
      );
    } else {
      Navigator.of(context).push(
        RouteGenerator.getRoute<dynamic>(
          shouldUseMaterialRoute: RouteGenerator.useMaterialPageRoute,
          builder: (_) => CakePaySendFromView(
            coin: coin,
            amount: amount,
            address: address,
            orderId: orderId,
          ),
          settings: const RouteSettings(name: CakePaySendFromView.routeName),
        ),
      );
    }
  }

  /// Resolve an API ticker (e.g. "LTC_MWEB") to a Stack Wallet coin,
  /// falling back to the base ticker before "_" if the full one isn't
  /// recognised.
  CryptoCurrency? _resolveCoin(String apiTicker) {
    final ticker = apiTicker.toUpperCase();
    var coin = AppConfig.getCryptoCurrencyForTicker(ticker);
    if (coin == null && ticker.contains('_') && !ticker.endsWith('_LN')) {
      coin = AppConfig.getCryptoCurrencyForTicker(ticker.split('_').first);
    }
    return coin;
  }

  /// Pretty-print an API ticker for display.
  String _tickerLabel(String apiTicker) {
    switch (apiTicker.toUpperCase()) {
      case 'BTC_LN':
        return 'BTC (LN)';
      case 'LTC_MWEB':
        return 'LTC (MWEB)';
      default:
        return apiTicker.toUpperCase();
    }
  }

  void _payWithOption(CakePayPaymentOption option, String orderId) {
    final label = _tickerLabel(option.ticker);
    final coin = _resolveCoin(option.ticker);

    if (option.address.trim().isEmpty) {
      showFloatingFlushBar(
        type: FlushBarType.warning,
        message: "No payment address available for $label",
        context: context,
      );
      return;
    }

    if (coin == null) {
      showFloatingFlushBar(
        type: FlushBarType.warning,
        message: "No wallet support for $label",
        context: context,
      );
      return;
    }

    final hasWallet = ref
        .read(pWallets)
        .wallets
        .any((w) => w.info.coin == coin);

    if (!hasWallet) {
      showFloatingFlushBar(
        type: FlushBarType.warning,
        message: "No $label wallet found. Create one first.",
        context: context,
      );
      return;
    }

    Amount? amount;
    try {
      amount = Amount.fromDecimal(
        Decimal.parse(option.amountFrom.toString()),
        fractionDigits: coin.fractionDigits,
      );
    } catch (_) {}

    _navigateToSendFrom(
      coin: coin,
      amount: amount,
      address: option.address,
      orderId: orderId,
    );
  }

  /// Whether the order has received payment and is being processed or
  /// is already complete.  Payment UI should be hidden for these.
  bool _isPaidOrBeyond(CakePayOrderStatus status) {
    return const {
      CakePayOrderStatus.paid,
      CakePayOrderStatus.pendingPurchase,
      CakePayOrderStatus.purchaseProcessing,
      CakePayOrderStatus.purchased,
      CakePayOrderStatus.pendingEmail,
      CakePayOrderStatus.complete,
    }.contains(status);
  }

  /// Whether payment UI (tabs, QR, address, pay button) should be shown.
  bool _showPaymentUI(CakePayOrderStatus status) {
    return !_isPaidOrBeyond(status) &&
        status != CakePayOrderStatus.expired &&
        status != CakePayOrderStatus.failed &&
        status != CakePayOrderStatus.pendingRefund &&
        status != CakePayOrderStatus.refunded;
  }

  /// Copyable order ID and created-at timestamp for terminal state banners.
  List<Widget> _orderInfoWidgets(CakePayOrder order, bool isDesktop) {
    final subtitleStyle = isDesktop
        ? STextStyles.desktopTextExtraExtraSmall(context)
        : STextStyles.itemSubtitle12(context);

    return [
      // Copyable order ID.
      RoundedWhiteContainer(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: order.orderId));
          showFloatingFlushBar(
            type: FlushBarType.info,
            message: "Order ID copied",
            iconAsset: Assets.svg.copy,
            context: context,
          );
        },
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Order ID", style: subtitleStyle),
                  const SizedBox(height: 4),
                  Text(
                    order.orderId,
                    style: isDesktop
                        ? STextStyles.desktopTextSmall(context)
                        : STextStyles.titleBold12(context),
                  ),
                ],
              ),
            ),
            IconCopyButton(data: order.orderId),
          ],
        ),
      ),
      // Created-at timestamp.
      if (order.createdAt != null) ...[
        SizedBox(height: isDesktop ? 8 : 6),
        RoundedWhiteContainer(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Created", style: subtitleStyle),
              Text(order.createdAt!, style: subtitleStyle),
            ],
          ),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    final service = ref.watch(pCakePayOrdersService);
    final order = service.get(widget.order.orderId) ?? widget.order;
    final isRefreshing = service.isRefreshing(widget.order.orderId);
    _ensureCountdown(order.expirationTime);
    final remaining = order.expirationTime == null
        ? Duration.zero
        : _computeRemaining(order.expirationTime!);
    final paymentOptions = order.paymentOptions;

    final details = <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: order.status
                  .color(Theme.of(context).extension<StackColors>()!)
                  .withValues(alpha: 0.2),
            ),
            child: Text(
              order.status.label,
              style:
                  (isDesktop
                          ? STextStyles.desktopTextExtraExtraSmall(context)
                          : STextStyles.itemSubtitle12(context))
                      .copyWith(
                        color: order.status.color(
                          Theme.of(context).extension<StackColors>()!,
                        ),
                      ),
            ),
          ),
        ],
      ),
      SizedBox(height: isDesktop ? 8 : 6),
      RoundedWhiteContainer(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: order.orderId));
          showFloatingFlushBar(
            type: FlushBarType.info,
            message: "Order ID copied",
            iconAsset: Assets.svg.copy,
            context: context,
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order ID",
              style: isDesktop
                  ? STextStyles.desktopTextExtraExtraSmall(context)
                  : STextStyles.itemSubtitle12(context),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SelectableText(
                      order.orderId,
                      style: isDesktop
                          ? STextStyles.desktopTextSmall(context)
                          : STextStyles.titleBold12(context),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconCopyButton(data: order.orderId),
                ],
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: isDesktop ? 16 : 12),
    ];

    if (order.amountUsd != null) {
      details.add(
        RoundedWhiteContainer(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Amount",
                style: isDesktop
                    ? STextStyles.desktopTextExtraExtraSmall(context)
                    : STextStyles.itemSubtitle12(context),
              ),
              Text(
                "\$${order.amountUsd} USD",
                style: isDesktop
                    ? STextStyles.desktopTextSmall(context)
                    : STextStyles.titleBold12(context),
              ),
            ],
          ),
        ),
      );
      details.add(SizedBox(height: isDesktop ? 16 : 12));
    }

    if (order.cards != null && order.cards!.isNotEmpty) {
      for (final item in order.cards!) {
        details.add(
          RoundedWhiteContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name ?? "Gift Card",
                  style: isDesktop
                      ? STextStyles.desktopTextSmall(context)
                      : STextStyles.titleBold12(context),
                ),
                if (item.priceValue != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    "${item.priceValue} ${item.currencyCode ?? ''}".trim(),
                    style: isDesktop
                        ? STextStyles.desktopTextExtraExtraSmall(context)
                        : STextStyles.itemSubtitle12(context),
                  ),
                ],
                if (item.priceUsd != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.priceUsd!,
                    style:
                        (isDesktop
                                ? STextStyles.desktopTextExtraExtraSmall(
                                    context,
                                  )
                                : STextStyles.itemSubtitle12(context))
                            .copyWith(
                              color: Theme.of(
                                context,
                              ).extension<StackColors>()!.textSubtitle1,
                            ),
                  ),
                ],
              ],
            ),
          ),
        );
        details.add(SizedBox(height: isDesktop ? 8 : 6));
      }
    }

    // Commission / markup info.
    if (order.commission != null || order.markupPercent != null) {
      details.add(
        RoundedWhiteContainer(
          child: Column(
            children: [
              if (order.commission != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Commission",
                      style: isDesktop
                          ? STextStyles.desktopTextExtraExtraSmall(context)
                          : STextStyles.itemSubtitle12(context),
                    ),
                    Text(
                      order.commission!,
                      style: isDesktop
                          ? STextStyles.desktopTextExtraExtraSmall(context)
                          : STextStyles.itemSubtitle12(context),
                    ),
                  ],
                ),
              if (order.commission != null && order.markupPercent != null)
                const SizedBox(height: 4),
              if (order.markupPercent != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Markup",
                      style: isDesktop
                          ? STextStyles.desktopTextExtraExtraSmall(context)
                          : STextStyles.itemSubtitle12(context),
                    ),
                    Text(
                      "${order.markupPercent!.toStringAsFixed(2)}%",
                      style: isDesktop
                          ? STextStyles.desktopTextExtraExtraSmall(context)
                          : STextStyles.itemSubtitle12(context),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
      details.add(SizedBox(height: isDesktop ? 8 : 6));
    }

    // Expiration countdown.
    if (order.expirationTime != null) {
      final isExpired = remaining == Duration.zero;
      details.add(
        RoundedWhiteContainer(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Time remaining",
                style: isDesktop
                    ? STextStyles.desktopTextExtraExtraSmall(context)
                    : STextStyles.itemSubtitle12(context),
              ),
              Text(
                _formatDuration(remaining),
                style:
                    (isDesktop
                            ? STextStyles.desktopTextExtraExtraSmall(context)
                            : STextStyles.itemSubtitle12(context))
                        .copyWith(
                          color: isExpired
                              ? Theme.of(
                                  context,
                                ).extension<StackColors>()!.accentColorRed
                              : remaining.inMinutes < 5
                              ? Theme.of(
                                  context,
                                ).extension<StackColors>()!.accentColorOrange
                              : null,
                          fontWeight: FontWeight.w600,
                        ),
              ),
            ],
          ),
        ),
      );
      details.add(SizedBox(height: isDesktop ? 8 : 6));
    }

    // --- Status-dependent payment section ---
    final status = order.status;

    // Banner for paid / processing states.
    if (_isPaidOrBeyond(status)) {
      details.add(SizedBox(height: isDesktop ? 16 : 12));
      details.add(
        RoundedWhiteContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.accentColorGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status == CakePayOrderStatus.complete
                          ? "Order complete."
                          : "Payment received.",
                      style:
                          (isDesktop
                                  ? STextStyles.desktopTextExtraExtraSmall(
                                      context,
                                    )
                                  : STextStyles.itemSubtitle12(context))
                              .copyWith(
                                color: Theme.of(
                                  context,
                                ).extension<StackColors>()!.accentColorGreen,
                              ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Your gift card details will be sent to "
                "the email address provided when creating "
                "the order.",
                style: isDesktop
                    ? STextStyles.desktopTextExtraExtraSmall(context)
                    : STextStyles.itemSubtitle12(context),
              ),
            ],
          ),
        ),
      );
      details.add(SizedBox(height: isDesktop ? 8 : 6));
      details.addAll(_orderInfoWidgets(order, isDesktop));
      details.add(SizedBox(height: isDesktop ? 8 : 6));
      details.add(
        const PrimaryButton(
          label: "ORDER PAID",
          enabled: false,
          onPressed: null,
        ),
      );
      details.add(SizedBox(height: isDesktop ? 8 : 6));
    }

    // Banner for expired / failed / refund states.
    if (status == CakePayOrderStatus.expired ||
        status == CakePayOrderStatus.failed ||
        status == CakePayOrderStatus.pendingRefund ||
        status == CakePayOrderStatus.refunded) {
      details.add(SizedBox(height: isDesktop ? 16 : 12));
      details.add(
        RoundedWhiteContainer(
          child: Row(
            children: [
              Icon(
                Icons.cancel,
                size: 20,
                color: Theme.of(
                  context,
                ).extension<StackColors>()!.textSubtitle1,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status.label,
                  style:
                      (isDesktop
                              ? STextStyles.desktopTextExtraExtraSmall(context)
                              : STextStyles.itemSubtitle12(context))
                          .copyWith(
                            color: Theme.of(
                              context,
                            ).extension<StackColors>()!.textSubtitle1,
                          ),
                ),
              ),
            ],
          ),
        ),
      );
      details.add(SizedBox(height: isDesktop ? 8 : 6));
      details.addAll(_orderInfoWidgets(order, isDesktop));
      details.add(SizedBox(height: isDesktop ? 8 : 6));
    }

    // Payment UI: tabs + QR + address + pay button.
    // Only shown for states that still accept payment.
    if (_showPaymentUI(status) &&
        paymentOptions != null &&
        paymentOptions.isNotEmpty) {
      // Sort so BTC_LN always appears last.
      final options = paymentOptions.values.toList()
        ..sort((a, b) {
          final aLn = a.ticker.toUpperCase() == 'BTC_LN';
          final bLn = b.ticker.toUpperCase() == 'BTC_LN';
          if (aLn && !bLn) return 1;
          if (!aLn && bLn) return -1;
          return 0;
        });
      if (_selectedPaymentMethod >= options.length) {
        _selectedPaymentMethod = 0;
      }
      final selected = options[_selectedPaymentMethod];
      final label = _tickerLabel(selected.ticker);
      final coin = _resolveCoin(selected.ticker);
      final bool hasWallet =
          coin != null &&
          ref.watch(pWallets).wallets.any((w) => w.info.coin == coin);

      details.add(SizedBox(height: isDesktop ? 8 : 4));
      details.add(
        Text(
          "Pay with",
          style: isDesktop
              ? STextStyles.desktopTextSmall(context)
              : STextStyles.titleBold12(context),
        ),
      );
      details.add(SizedBox(height: isDesktop ? 8 : 6));

      // Tab selector.
      details.add(
        Row(
          children: List.generate(options.length, (index) {
            final isSelected = _selectedPaymentMethod == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedPaymentMethod = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected
                            ? Theme.of(
                                context,
                              ).extension<StackColors>()!.accentColorBlue
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    _tickerLabel(options[index].ticker),
                    textAlign: TextAlign.center,
                    style:
                        (isDesktop
                                ? STextStyles.desktopTextExtraExtraSmall(
                                    context,
                                  )
                                : STextStyles.itemSubtitle12(context))
                            .copyWith(
                              color: isSelected
                                  ? Theme.of(
                                      context,
                                    ).extension<StackColors>()!.accentColorBlue
                                  : null,
                              fontWeight: isSelected ? FontWeight.w600 : null,
                            ),
                  ),
                ),
              ),
            );
          }),
        ),
      );

      details.add(SizedBox(height: isDesktop ? 16 : 12));

      // QR code for the selected payment address.
      if (selected.address.isNotEmpty) {
        details.add(
          Center(
            child: QR(data: selected.address, size: isDesktop ? 200 : 180),
          ),
        );
        details.add(SizedBox(height: isDesktop ? 16 : 12));
      }

      // Selected method details.
      details.add(
        RoundedWhiteContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Amount",
                    style: isDesktop
                        ? STextStyles.desktopTextExtraExtraSmall(context)
                        : STextStyles.itemSubtitle12(context),
                  ),
                  Text(
                    "${selected.amountFrom} $label",
                    style: isDesktop
                        ? STextStyles.desktopTextSmall(context)
                        : STextStyles.titleBold12(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: selected.address));
                  showFloatingFlushBar(
                    type: FlushBarType.info,
                    message: "Copied to clipboard",
                    iconAsset: Assets.svg.copy,
                    context: context,
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "$label address",
                          style: isDesktop
                              ? STextStyles.desktopTextExtraExtraSmall(context)
                              : STextStyles.itemSubtitle12(context),
                        ),
                        const Spacer(),
                        IconCopyButton(data: order.orderId),
                        const SizedBox(width: 4),
                        Text("Copy", style: STextStyles.link2(context)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selected.address,
                      style: isDesktop
                          ? STextStyles.desktopTextExtraExtraSmall(context)
                          : STextStyles.itemSubtitle12(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: hasWallet ? "Pay with $label" : "$label (no wallet)",
                enabled: hasWallet,
                onPressed: hasWallet
                    ? () => _payWithOption(selected, order.orderId)
                    : null,
              ),
            ],
          ),
        ),
      );
      details.add(SizedBox(height: isDesktop ? 8 : 6));
    }

    final scrollable = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: details,
      ),
    );

    final content = RefreshControl(
      onRefresh: () => service.refreshOne(widget.order.orderId),
      child: scrollable,
    );

    return _scaffold(
      isDesktop: isDesktop,
      isRefreshing: isRefreshing,
      onRefresh: () => service.refreshOne(widget.order.orderId),
      child: content,
    );
  }

  Widget _scaffold({
    required bool isDesktop,
    required bool isRefreshing,
    required Future<void> Function() onRefresh,
    required Widget child,
  }) {
    return ConditionalParent(
      condition: isDesktop,
      builder: (child) => SDialog(
        child: SizedBox(
          width: 580,
          child: Column(
            mainAxisSize: .min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Text("Order", style: STextStyles.desktopH3(context)),
                  ),
                  Row(
                    mainAxisSize: .min,
                    children: [
                      RefreshButton(
                        isRefreshing: isRefreshing,
                        onPressed: () => onRefresh(),
                      ),
                      const SizedBox(width: 8),
                      DesktopDialogCloseButton(
                        onPressedOverride: () =>
                            confirmCloseNestedNavigatorDialog(context),
                      ),
                    ],
                  ),
                ],
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 8,
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
      child: ConditionalParent(
        condition: !isDesktop,
        builder: (child) => Background(
          child: Scaffold(
            backgroundColor: Theme.of(
              context,
            ).extension<StackColors>()!.background,
            appBar: AppBar(
              leading: AppBarBackButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text("Order", style: STextStyles.navBarTitle(context)),
            ),
            body: SafeArea(
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}
