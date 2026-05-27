import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../app_config.dart';
import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../notifications/show_flush_bar.dart';
import '../../providers/global/shopin_bit_service_provider.dart';
import '../../providers/providers.dart';
import '../../services/shopinbit/src/models/payment.dart';
import '../../themes/coin_icon_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/address_utils.dart';
import '../../utilities/assets.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/icon_widgets/copy_icon.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rounded_white_container.dart';
import 'shopinbit_payment_shared.dart';

class ShopInBitPaymentView extends ConsumerStatefulWidget {
  const ShopInBitPaymentView({super.key, required this.model});

  static const String routeName = "/shopInBitPayment";

  final ShopInBitOrderModel model;

  @override
  ConsumerState<ShopInBitPaymentView> createState() =>
      _ShopInBitPaymentViewState();
}

class _ShopInBitPaymentViewState extends ConsumerState<ShopInBitPaymentView> {
  bool _loading = false;
  int _selectedMethod = 0;
  Timer? _pollTimer;

  PaymentInfo? _paymentInfo;

  // Derived from API payment_links keys, fallback to defaults
  List<String> _methods = ["BTC", "XMR", "USDT"];
  List<String> _addresses = ["", "", ""];

  String get _currentAddress =>
      _selectedMethod < _addresses.length ? _addresses[_selectedMethod] : "";

  String get _totalPrice =>
      _paymentInfo?.customerPrice ?? widget.model.offerPrice ?? "0";

  String get _status => _paymentInfo?.status ?? 'ready_to_pay';

  bool get _isExpiredOrInvalid => _status == 'expired' || _status == 'invalid';

  bool get _isTerminal => const {
    'paid',
    'paid_over',
    'paid_late',
    'payment_processing',
  }.contains(_status);

  bool get _payNowEnabled => !_isExpiredOrInvalid && !_isTerminal;

  @override
  void initState() {
    super.initState();
    if (widget.model.apiTicketId != 0) {
      _loadPayment();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _applyPaymentInfo(PaymentInfo info) {
    _paymentInfo = info;
    final links = info.paymentLinks;
    if (links.isNotEmpty) {
      _methods = links.keys.map((k) => k.toUpperCase()).toList();
      _addresses = links.values.toList();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _pollPayment(),
    );
  }

  Future<void> _pollPayment() async {
    try {
      final resp = await ref
          .read(pShopinBitService)
          .client
          .getPayment(widget.model.apiTicketId);
      if (!resp.hasError && resp.value != null && mounted) {
        setState(() => _applyPaymentInfo(resp.value!));
        if (_isTerminal) {
          _pollTimer?.cancel();
        }
      }
    } catch (_) {}
  }

  // The shipping view's PAY NOW button is the only path into this view today,
  // but we still GET first per the 1.0.4 spec's "page reload recovery"
  // guidance: if a live invoice already exists for this ticket, reuse it.  PUT
  // (which regenerates) only when GET shows there isn't one.  An empty
  // paymentLinks map covers all "no live invoice" cases the server returns
  // (fresh ticket, expired, invalid) and a non-empty map covers everything
  // worth preserving (live, paid, paid_late, processing).
  Future<void> _loadPayment() async {
    setState(() => _loading = true);
    try {
      final client = ref.read(pShopinBitService).client;
      final getResp = await client.getPayment(widget.model.apiTicketId);
      PaymentInfo? info;
      if (!getResp.hasError &&
          getResp.value != null &&
          getResp.value!.paymentLinks.isNotEmpty) {
        info = getResp.value!;
      } else {
        final putResp = await client.putPayment(widget.model.apiTicketId);
        if (!putResp.hasError && putResp.value != null) {
          info = putResp.value!;
        }
      }
      if (info != null) {
        _applyPaymentInfo(info);
      }
    } catch (_) {
      // Fall back to local/dummy data
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _startPolling();
      }
    }
  }

  Future<void> _refreshInvoice() async {
    setState(() => _loading = true);
    try {
      final resp = await ref
          .read(pShopinBitService)
          .client
          .putPayment(widget.model.apiTicketId);
      if (!resp.hasError && resp.value != null) {
        _applyPaymentInfo(resp.value!);
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
      _startPolling();
    }
  }

  Future<void> _checkForPayment() async {
    _pollTimer?.cancel();
    setState(() => _loading = true);
    try {
      final resp = await ref
          .read(pShopinBitService)
          .client
          .getPayment(widget.model.apiTicketId);
      if (!resp.hasError && resp.value != null && mounted) {
        setState(() => _applyPaymentInfo(resp.value!));
        final status = resp.value!.status;
        if (const {
          'paid',
          'paid_over',
          'paid_late',
          'payment_processing',
        }.contains(status)) {
          if (mounted) {
            unawaited(
              showFloatingFlushBar(
                type: FlushBarType.success,
                message: "Payment received!",
                context: context,
              ),
            );
          }
        } else if (status == 'underpaid') {
          if (mounted) {
            unawaited(
              showFloatingFlushBar(
                type: FlushBarType.warning,
                message: "Underpaid. Remaining: ${resp.value!.due ?? '?'} EUR.",
                context: context,
              ),
            );
          }
        } else {
          if (mounted) {
            unawaited(
              showFloatingFlushBar(
                type: FlushBarType.info,
                message: "No payment detected yet.",
                context: context,
              ),
            );
          }
        }
      } else if (mounted) {
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.warning,
            message: resp.exception?.message ?? "Failed to check payment.",
            context: context,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.warning,
            message: e.toString(),
            context: context,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        if (!_isTerminal) {
          _startPolling();
        }
      }
    }
  }

  void _confirmPayment() {
    _pollTimer?.cancel();
    final method = _methods[_selectedMethod];
    final ticker = method.toUpperCase();

    final target = parseShopInBitPaymentTarget(
      paymentUri: _currentAddress,
      ticker: ticker,
      coin: AppConfig.getCryptoCurrencyForTicker(ticker),
      amountFallback: _paymentInfo?.due,
    );

    if (tryNavigateToShopInBitWalletSend(
      ref: ref,
      context: context,
      ticker: ticker,
      paymentUri: _currentAddress,
      address: target.address,
      amount: target.amount,
      model: widget.model,
      popDesktopBeforeShow: true,
    )) {
      return;
    }

    widget.model.status = ShopInBitOrderStatus.paymentPending;
    widget.model.paymentMethod = method;

    if (Util.isDesktop) {
      Navigator.of(context, rootNavigator: true).pop();
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _popToTickets() {
    Navigator.of(context).pop();
  }

  void _navigateToTickets() {
    if (Util.isDesktop) {
      Navigator.of(context, rootNavigator: true).pop();
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  String? _parseBip21Amount(String bip21Uri) {
    final parsed = AddressUtils.parsePaymentUri(bip21Uri);
    String? amountStr = parsed?.amount;
    if (amountStr == null || amountStr.isEmpty) {
      final uri = Uri.tryParse(bip21Uri);
      if (uri != null) {
        amountStr = uri.queryParameters['amount'];
      }
    }
    return (amountStr != null && amountStr.isNotEmpty) ? amountStr : null;
  }

  void _onOwnedCoinTap(int methodIndex) {
    if (!_payNowEnabled) return;
    _selectedMethod = methodIndex;
    _confirmPayment();
  }

  void _onUnownedCoinTap(int methodIndex) {
    if (_isExpiredOrInvalid || _isTerminal) return;
    final ticker = _methods[methodIndex].toUpperCase();
    final address = _addresses[methodIndex];

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("$ticker Payment", style: STextStyles.pageTitleH2(context)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: address));
                showFloatingFlushBar(
                  type: FlushBarType.info,
                  message: "Copied to clipboard",
                  iconAsset: Assets.svg.copy,
                  context: context,
                );
              },
              child: RoundedWhiteContainer(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        address,
                        style: STextStyles.itemSubtitle12(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CopyIcon(
                      width: 14,
                      height: 14,
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.accentColorBlue,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: "CHECK FOR PAYMENT",
              onPressed: () {
                Navigator.of(ctx).pop();
                _checkForPayment();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    final wallets = ref.watch(pWallets);
    // Build coin rows from _methods/_addresses
    final coinRows = <Widget>[];
    for (int i = 0; i < _methods.length; i++) {
      final ticker = _methods[i].toUpperCase();
      final coin = AppConfig.getCryptoCurrencyForTicker(ticker);
      final hasWallet = hasShopInBitWalletForTicker(
        wallets: wallets,
        ticker: ticker,
        paymentUri: _addresses[i],
      );
      final amountStr = _addresses[i].isNotEmpty
          ? _parseBip21Amount(_addresses[i])
          : null;

      if (i > 0) {
        coinRows.add(const SizedBox(height: 8));
      }

      coinRows.add(
        RoundedWhiteContainer(
          child: Opacity(
            opacity: hasWallet ? 1.0 : 0.5,
            child: InkWell(
              onTap: hasWallet
                  ? () => _onOwnedCoinTap(i)
                  : () => _onUnownedCoinTap(i),
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
                        if (amountStr != null)
                          Text(
                            "$amountStr $ticker",
                            style: STextStyles.itemSubtitle12(context),
                          ),
                      ],
                    ),
                  ),
                  if (hasWallet)
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

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Payment",
          style: isDesktop
              ? STextStyles.desktopH2(context)
              : STextStyles.pageTitleH1(context),
        ),
        SizedBox(height: isDesktop ? 16 : 8),
        RoundedWhiteContainer(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total",
                style: isDesktop
                    ? STextStyles.desktopTextSmall(context)
                    : STextStyles.titleBold12(context),
              ),
              Text(
                "$_totalPrice EUR",
                style: isDesktop
                    ? STextStyles.desktopTextSmall(context)
                    : STextStyles.titleBold12(context),
              ),
            ],
          ),
        ),
        // Status banner
        if (_status == 'underpaid') ...[
          SizedBox(height: isDesktop ? 16 : 8),
          RoundedWhiteContainer(
            child: Row(
              children: [
                SvgPicture.asset(
                  Assets.svg.alertCircle,
                  width: 20,
                  height: 20,
                  color: Theme.of(
                    context,
                  ).extension<StackColors>()!.accentColorOrange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Payment underpaid. Remaining: "
                    "${_paymentInfo?.due ?? '?'} EUR. "
                    "Please send the remaining amount.",
                    style:
                        (isDesktop
                                ? STextStyles.desktopTextExtraExtraSmall(
                                    context,
                                  )
                                : STextStyles.itemSubtitle12(context))
                            .copyWith(
                              color: Theme.of(
                                context,
                              ).extension<StackColors>()!.accentColorOrange,
                            ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_isExpiredOrInvalid) ...[
          SizedBox(height: isDesktop ? 16 : 8),
          RoundedWhiteContainer(
            child: Column(
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      Assets.svg.alertCircle,
                      width: 20,
                      height: 20,
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.accentColorRed,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Invoice expired.",
                        style:
                            (isDesktop
                                    ? STextStyles.desktopTextExtraExtraSmall(
                                        context,
                                      )
                                    : STextStyles.itemSubtitle12(context))
                                .copyWith(
                                  color: Theme.of(
                                    context,
                                  ).extension<StackColors>()!.accentColorRed,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SecondaryButton(
                  label: "Refresh Invoice",
                  onPressed: _refreshInvoice,
                ),
              ],
            ),
          ),
        ],
        if (_isTerminal) ...[
          SizedBox(height: isDesktop ? 16 : 8),
          RoundedWhiteContainer(
            child: Row(
              children: [
                SvgPicture.asset(
                  Assets.svg.checkCircle,
                  width: 20,
                  height: 20,
                  color: Theme.of(
                    context,
                  ).extension<StackColors>()!.accentColorGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Payment received.",
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
          ),
          SizedBox(height: isDesktop ? 16 : 12),
          PrimaryButton(
            label: "View My Requests",
            onPressed: _navigateToTickets,
          ),
        ],
        SizedBox(height: isDesktop ? 24 : 16),
        // Coin list (replaces tab selector + QR + address + global button)
        if (!_isExpiredOrInvalid) ...coinRows,
      ],
    );

    if (isDesktop) {
      return DesktopDialog(
        maxWidth: 580,
        maxHeight: 750,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    "ShopinBit",
                    style: STextStyles.desktopH3(context),
                  ),
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
                child: Stack(
                  children: [
                    SingleChildScrollView(child: content),
                    if (_loading) const LoadingIndicator(width: 24, height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ShopInBitPaymentMobileScaffold(
      onBack: _popToTickets,
      showLoading: _loading,
      child: content,
    );
  }
}
