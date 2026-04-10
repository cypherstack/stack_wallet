import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_config.dart';
import '../../notifications/show_flush_bar.dart';
import '../../providers/providers.dart';
import '../../route_generator.dart';
import '../../services/cakepay/cakepay_service.dart';
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
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/qr.dart';
import '../../widgets/rounded_white_container.dart';
import 'cakepay_send_from_view.dart';

class CakePayOrderView extends ConsumerStatefulWidget {
  const CakePayOrderView({super.key, required this.orderId});

  static const String routeName = "/cakePayOrder";

  final String orderId;

  @override
  ConsumerState<CakePayOrderView> createState() => _CakePayOrderViewState();
}

class _CakePayOrderViewState extends ConsumerState<CakePayOrderView> {
  CakePayOrder? _order;
  bool _loading = true;
  Timer? _pollTimer;
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;
  int _selectedPaymentMethod = 0;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadOrder(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _updateTimeRemaining();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTimeRemaining(),
    );
  }

  void _updateTimeRemaining() {
    if (_order?.expirationTime == null) return;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      _order!.expirationTime!,
    );
    final remaining = expiresAt.difference(DateTime.now());
    if (mounted) {
      setState(() {
        _timeRemaining = remaining.isNegative ? Duration.zero : remaining;
      });
    }
    if (remaining.isNegative) {
      _countdownTimer?.cancel();
    }
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
      Navigator.of(context, rootNavigator: true).pop();
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
    if (coin == null &&
        ticker.contains('_') &&
        !ticker.endsWith('_LN')) {
      coin = AppConfig.getCryptoCurrencyForTicker(
        ticker.split('_').first,
      );
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

  Future<void> _loadOrder() async {
    final resp = await CakePayService.instance.client.getOrder(widget.orderId);
    if (mounted) {
      setState(() {
        _loading = false;
        if (!resp.hasError && resp.value != null) {
          var order = resp.value!;
          final override =
              CakePayService.devStatusOverrides[order.orderId];
          if (override != null) {
            order = order.copyWith(status: override);
          }
          _order = order;
          if (_isTerminal(_order!.status)) {
            _pollTimer?.cancel();
            _countdownTimer?.cancel();
          } else if (_order!.expirationTime != null) {
            _startCountdown();
          }
        }
      });
    }
  }

  bool _isTerminal(CakePayOrderStatus status) {
    return status == CakePayOrderStatus.complete ||
        status == CakePayOrderStatus.expired ||
        status == CakePayOrderStatus.failed ||
        status == CakePayOrderStatus.refunded;
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
        child: GestureDetector(
          onTap: () {
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
              Icon(
                Icons.copy,
                size: 14,
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .accentColorBlue,
              ),
            ],
          ),
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

  String _statusLabel(CakePayOrderStatus status) {
    switch (status) {
      case CakePayOrderStatus.new_:
        return "New";
      case CakePayOrderStatus.expiredButStillPending:
        return "Expired (pending)";
      case CakePayOrderStatus.expired:
        return "Expired";
      case CakePayOrderStatus.failed:
        return "Failed";
      case CakePayOrderStatus.paid:
        return "Paid";
      case CakePayOrderStatus.paidPartial:
        return "Partially paid";
      case CakePayOrderStatus.pendingPurchase:
        return "Pending purchase";
      case CakePayOrderStatus.purchaseProcessing:
        return "Processing";
      case CakePayOrderStatus.purchased:
        return "Purchased";
      case CakePayOrderStatus.pendingEmail:
        return "Pending email";
      case CakePayOrderStatus.complete:
        return "Complete";
      case CakePayOrderStatus.pendingRefund:
        return "Pending refund";
      case CakePayOrderStatus.refunded:
        return "Refunded";
    }
  }

  Color _statusColor(BuildContext context, CakePayOrderStatus status) {
    final colors = Theme.of(context).extension<StackColors>()!;
    switch (status) {
      case CakePayOrderStatus.complete:
      case CakePayOrderStatus.purchased:
        return colors.accentColorGreen;
      case CakePayOrderStatus.new_:
      case CakePayOrderStatus.paid:
      case CakePayOrderStatus.paidPartial:
        return colors.accentColorBlue;
      case CakePayOrderStatus.pendingPurchase:
      case CakePayOrderStatus.purchaseProcessing:
      case CakePayOrderStatus.pendingEmail:
      case CakePayOrderStatus.expiredButStillPending:
        return colors.accentColorYellow;
      case CakePayOrderStatus.expired:
      case CakePayOrderStatus.failed:
      case CakePayOrderStatus.pendingRefund:
      case CakePayOrderStatus.refunded:
        return colors.textSubtitle1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    if (_loading) {
      return _scaffold(
        isDesktop: isDesktop,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_order == null) {
      return _scaffold(
        isDesktop: isDesktop,
        child: Center(
          child: Text(
            "Failed to load order",
            style: isDesktop
                ? STextStyles.desktopTextSmall(context)
                : STextStyles.itemSubtitle(context),
          ),
        ),
      );
    }

    final order = _order!;
    final paymentOptions = order.paymentOptions;

    final statusBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _statusColor(context, order.status).withValues(alpha: 0.2),
      ),
      child: Text(
        _statusLabel(order.status),
        style:
            (isDesktop
                    ? STextStyles.desktopTextExtraExtraSmall(context)
                    : STextStyles.itemSubtitle12(context))
                .copyWith(color: _statusColor(context, order.status)),
      ),
    );

    final details = <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          statusBadge,
        ],
      ),
      SizedBox(height: isDesktop ? 8 : 6),
      RoundedWhiteContainer(
        child: GestureDetector(
          onTap: () {
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
            children: [
              Text(
                "Order ID",
                style: isDesktop
                    ? STextStyles.desktopTextExtraExtraSmall(context)
                    : STextStyles.itemSubtitle12(context),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectableText(
                    order.orderId,
                    style: isDesktop
                        ? STextStyles.desktopTextSmall(context)
                        : STextStyles.titleBold12(context),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.copy,
                    size: 14,
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .accentColorBlue,
                  ),
                ],
              ),
            ],
          ),
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
      final isExpired = _timeRemaining == Duration.zero;
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
                _formatDuration(_timeRemaining),
                style:
                    (isDesktop
                            ? STextStyles.desktopTextExtraExtraSmall(context)
                            : STextStyles.itemSubtitle12(context))
                        .copyWith(
                          color: isExpired
                              ? Theme.of(
                                  context,
                                ).extension<StackColors>()!.accentColorRed
                              : _timeRemaining.inMinutes < 5
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
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .accentColorGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status == CakePayOrderStatus.complete
                          ? "Order complete."
                          : "Payment received.",
                      style: (isDesktop
                              ? STextStyles
                                  .desktopTextExtraExtraSmall(
                                    context,
                                  )
                              : STextStyles.itemSubtitle12(
                                  context,
                                ))
                          .copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorGreen,
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
                    ? STextStyles.desktopTextExtraExtraSmall(
                        context,
                      )
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
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textSubtitle1,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _statusLabel(status),
                  style: (isDesktop
                          ? STextStyles
                              .desktopTextExtraExtraSmall(
                                context,
                              )
                          : STextStyles.itemSubtitle12(
                              context,
                            ))
                      .copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textSubtitle1,
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
          ref.watch(pWallets).wallets.any(
            (w) => w.info.coin == coin,
          );

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
            final isSelected =
                _selectedPaymentMethod == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(
                  () => _selectedPaymentMethod = index,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected
                            ? Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorBlue
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    _tickerLabel(options[index].ticker),
                    textAlign: TextAlign.center,
                    style: (isDesktop
                            ? STextStyles
                                .desktopTextExtraExtraSmall(
                                  context,
                                )
                            : STextStyles.itemSubtitle12(
                                context,
                              ))
                        .copyWith(
                      color: isSelected
                          ? Theme.of(context)
                              .extension<StackColors>()!
                              .accentColorBlue
                          : null,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : null,
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
            child: QR(
              data: selected.address,
              size: isDesktop ? 200 : 180,
            ),
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
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Amount",
                    style: isDesktop
                        ? STextStyles
                            .desktopTextExtraExtraSmall(
                              context,
                            )
                        : STextStyles.itemSubtitle12(
                            context,
                          ),
                  ),
                  Text(
                    "${selected.amountFrom} $label",
                    style: isDesktop
                        ? STextStyles.desktopTextSmall(
                            context,
                          )
                        : STextStyles.titleBold12(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: selected.address),
                  );
                  showFloatingFlushBar(
                    type: FlushBarType.info,
                    message: "Copied to clipboard",
                    iconAsset: Assets.svg.copy,
                    context: context,
                  );
                },
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "$label address",
                          style: isDesktop
                              ? STextStyles
                                  .desktopTextExtraExtraSmall(
                                    context,
                                  )
                              : STextStyles
                                  .itemSubtitle12(
                                    context,
                                  ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.copy,
                          size: 14,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .accentColorBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Copy",
                          style:
                              STextStyles.link2(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selected.address,
                      style: isDesktop
                          ? STextStyles
                              .desktopTextExtraExtraSmall(
                                context,
                              )
                          : STextStyles.itemSubtitle12(
                              context,
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: hasWallet
                    ? "Pay with $label"
                    : "$label (no wallet)",
                enabled: hasWallet,
                onPressed: hasWallet
                    ? () => _payWithOption(
                          selected,
                          order.orderId,
                        )
                    : null,
              ),
            ],
          ),
        ),
      );
      details.add(SizedBox(height: isDesktop ? 8 : 6));
    }

    final content = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: details,
      ),
    );

    return _scaffold(isDesktop: isDesktop, child: content);
  }

  Widget _scaffold({required bool isDesktop, required Widget child}) {
    return ConditionalParent(
      condition: isDesktop,
      builder: (child) => DesktopDialog(
        maxWidth: 580,
        maxHeight: 650,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text("Order", style: STextStyles.desktopH3(context)),
                ),
                const DesktopDialogCloseButton(),
              ],
            ),
            Expanded(
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
