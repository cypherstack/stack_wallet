import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../app_config.dart';
import '../../notifications/show_flush_bar.dart';
import '../../providers/global/shopin_bit_service_provider.dart';
import '../../providers/providers.dart';
import '../../services/shopinbit/src/client.dart';
import '../../services/shopinbit/src/models/payment.dart';
import '../../themes/coin_icon_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/address_utils.dart';
import '../../utilities/assets.dart';
import '../../utilities/logger.dart';
import '../../utilities/show_loading.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/dialogs/s_dialog.dart';
import '../../widgets/dialogs/simple_mobile_dialog.dart';
import '../../widgets/icon_widgets/copy_icon.dart';
import '../../widgets/qr.dart';
import '../../widgets/rounded_container.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_dialog.dart';
import '../more_view/services_view.dart';
import 'shopinbit_payment_shared.dart';
import 'shopinbit_ticket_detail.dart';
import 'shopinbit_tickets_view.dart';

class ShopInBitPaymentView extends ConsumerStatefulWidget {
  const ShopInBitPaymentView({
    super.key,
    required this.apiTicketId,
    required this.paymentInfo,
  });

  static const String routeName = "/shopInBitPayment";

  final int apiTicketId;

  // Caller loads this before pushing, so we always open with usable addresses.
  final PaymentInfo paymentInfo;

  @override
  ConsumerState<ShopInBitPaymentView> createState() =>
      _ShopInBitPaymentViewState();
}

class _ShopInBitPaymentViewState extends ConsumerState<ShopInBitPaymentView>
    with WidgetsBindingObserver {
  int _selectedMethod = 0;
  Timer? _pollTimer;

  static const Duration _kBasePollInterval = Duration(seconds: 15);
  static const Duration _kMaxPollInterval = Duration(seconds: 120);
  Duration _pollInterval = _kBasePollInterval;

  PaymentInfo? _paymentInfo;

  // Derived from API payment_links keys, fallback to defaults
  List<String> _methods = ["BTC", "XMR", "USDT"];
  List<String> _addresses = ["", "", ""];

  String get _currentAddress =>
      _selectedMethod < _addresses.length ? _addresses[_selectedMethod] : "";

  String get _totalPrice => _paymentInfo?.customerPrice ?? "0";

  String get _status => _paymentInfo?.status ?? 'ready_to_pay';

  bool get _isExpiredOrInvalid => _status == 'expired' || _status == 'invalid';

  // Voucher/credit fully covers the amount: no wallet options, nothing to pay.
  bool get _isNoPaymentRequired => _status == 'no_payment_required';

  bool get _isTerminal => const {
    'paid',
    'paid_over',
    'paid_late',
    'payment_processing',
  }.contains(_status);

  bool get _payNowEnabled =>
      !_isExpiredOrInvalid && !_isTerminal && !_isNoPaymentRequired;

  String? _customerKeyCache;

  Future<String> get _customerKey async {
    _customerKeyCache ??=
        (await ref
                .read(pSharedDrift)
                .shopInBitTicketsDao
                .getByApiId(widget.apiTicketId))!
            .customerKey;
    return _customerKeyCache!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyPaymentInfo(widget.paymentInfo);
    if (widget.apiTicketId != 0) {
      _startPolling();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.apiTicketId == 0) return;
    // Don't poll while backgrounded; resume fresh when we come back.
    if (state == AppLifecycleState.resumed) {
      if (!_isTerminal) _startPolling();
    } else {
      _pollTimer?.cancel();
    }
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
    _pollInterval = _kBasePollInterval;
    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer(_pollInterval, _pollPayment);
  }

  Future<void> _pollPayment() async {
    bool ok = false;
    try {
      final resp = await ref
          .read(pShopinBitService)
          .client
          .getPayment(widget.apiTicketId, customerKey: await _customerKey);
      if (!resp.hasError && resp.value != null) {
        ok = true;
        if (mounted) {
          setState(() => _applyPaymentInfo(resp.value!));
        }
      }
    } catch (e, s) {
      Logging.instance.w(
        "ShopInBit payment poll failed",
        error: e,
        stackTrace: s,
      );
    }
    if (!mounted) return;
    if (_isTerminal) {
      _pollTimer?.cancel();
      return;
    }
    // Back off on failure (e.g. a 429), reset to base on success, so a rate
    // limit slows us down instead of getting hammered every 15s.
    _pollInterval = ok
        ? _kBasePollInterval
        : ShopInBitClient.nextPollBackoff(_pollInterval, _kMaxPollInterval);
    _scheduleNextPoll();
  }

  Future<void> _refreshInvoice() async {
    _pollTimer?.cancel();

    final customerKey = await _customerKey;
    if (!mounted) return;

    final resp = await showLoading(
      whileFuture: ref
          .read(pShopinBitService)
          .client
          .putPayment(
            widget.apiTicketId,
            customerKey: customerKey,
            retry: true,
          ),
      context: context,
      message: "Refreshing invoice",
      rootNavigator: true,
    );
    if (!mounted) return;
    if (resp != null && !resp.hasError && resp.value != null) {
      setState(() => _applyPaymentInfo(resp.value!));
    }
    _startPolling();
  }

  Future<void> _checkForPayment() async {
    _pollTimer?.cancel();

    final customerKey = await _customerKey;
    if (!mounted) return;

    final resp = await showLoading(
      whileFuture: ref
          .read(pShopinBitService)
          .client
          .getPayment(widget.apiTicketId, customerKey: customerKey),
      context: context,
      message: "Checking for payment",
      rootNavigator: true,
    );
    if (!mounted) return;

    if (resp != null && !resp.hasError && resp.value != null) {
      setState(() => _applyPaymentInfo(resp.value!));
      final status = resp.value!.status;
      if (const {
        'paid',
        'paid_over',
        'paid_late',
        'payment_processing',
      }.contains(status)) {
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.success,
            message: "Payment received!",
            context: context,
          ),
        );
      } else if (status == 'underpaid') {
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.warning,
            message: "Underpaid. Remaining: ${resp.value!.due ?? '?'} EUR.",
            context: context,
          ),
        );
      } else {
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.info,
            message: "No payment detected yet.",
            context: context,
          ),
        );
      }
    } else {
      await showDialog<void>(
        context: context,
        useRootNavigator: Util.isDesktop,
        builder: (context) => StackOkDialog(
          title: "Failed to check payment",
          maxWidth: Util.isDesktop ? 500 : null,
          message: resp?.exception?.message,
          desktopPopRootNavigator: Util.isDesktop,
        ),
      );
      if (!mounted) return;
    }

    if (!_isTerminal) {
      _startPolling();
    }
  }

  Future<void> _confirmPayment() async {
    _pollTimer?.cancel();
    final method = _methods[_selectedMethod];
    final ticker = method.toUpperCase();

    final target = parseShopInBitPaymentTarget(
      paymentUri: _currentAddress,
      ticker: ticker,
      coin: AppConfig.getCryptoCurrencyForTicker(ticker),
      amountFallback: _paymentInfo?.due,
    );

    if (await tryNavigateToShopInBitWalletSend(
      ref: ref,
      context: context,
      ticker: ticker,
      paymentUri: _currentAddress,
      address: target.address,
      amount: target.amount,
      apiTicketId: widget.apiTicketId,
    )) {
      return;
    }
    if (!mounted) return;

    // Couldn't launch the in-wallet send.
    unawaited(
      showFloatingFlushBar(
        type: FlushBarType.warning,
        message:
            "Payment details for $ticker aren't ready yet. "
            "Please wait a moment or refresh the invoice.",
        context: context,
      ),
    );
    if (!_isTerminal) {
      _startPolling();
    }
  }

  void _popToTickets() {
    Navigator.of(context).pop();
  }

  bool get _canReturnToRequest => widget.apiTicketId != 0;
  void _backToRequest() {
    final navigator = Navigator.of(context);
    bool landedOnRequest = false;
    navigator.popUntil((route) {
      final name = route.settings.name;
      if (name == ShopInBitTicketDetail.routeName) {
        landedOnRequest = true;
        return true;
      }
      return name == ShopInBitTicketsView.routeName ||
          name == ServicesView.routeName ||
          route.isFirst;
    });
    if (!landedOnRequest) {
      unawaited(
        navigator.pushNamed(
          ShopInBitTicketDetail.routeName,
          arguments: widget.apiTicketId,
        ),
      );
    }
  }

  void _goToMyRequests() {
    final navigator = Navigator.of(context);
    bool landedOnTickets = false;
    navigator.popUntil((route) {
      final name = route.settings.name;
      if (name == ShopInBitTicketsView.routeName) {
        landedOnTickets = true;
        return true;
      }
      return name == ServicesView.routeName || route.isFirst;
    });
    if (!landedOnTickets) {
      unawaited(navigator.pushNamed(ShopInBitTicketsView.routeName));
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
    if (_addresses[methodIndex].isEmpty) return;
    _selectedMethod = methodIndex;
    unawaited(_confirmPayment());
  }

  void _onUnownedCoinTap(int methodIndex) {
    if (!_payNowEnabled) return;
    final ticker = _methods[methodIndex].toUpperCase();
    final address = _addresses[methodIndex];
    if (address.isEmpty) return;

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => _UnownedCoinPaymentDialog(
        ticker: ticker,
        address: address,
        onCheckForPayment: () {
          Navigator.of(ctx).pop();
          _checkForPayment();
        },
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
      final hasAddress = _addresses[i].isNotEmpty;
      final hasWallet = hasShopInBitWalletForTicker(
        wallets: wallets,
        ticker: ticker,
        paymentUri: _addresses[i],
      );
      final canPayNow = hasWallet && hasAddress;
      final amountStr = hasAddress ? _parseBip21Amount(_addresses[i]) : null;

      if (i > 0) {
        coinRows.add(const SizedBox(height: 8));
      }

      coinRows.add(
        RoundedWhiteContainer(
          child: Opacity(
            opacity: canPayNow ? 1.0 : 0.5,
            child: InkWell(
              onTap: !hasAddress
                  ? null
                  : (hasWallet
                        ? () => _onOwnedCoinTap(i)
                        : () => _onUnownedCoinTap(i)),
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
            label: _canReturnToRequest ? "Back to Request" : "View My Requests",
            onPressed: _canReturnToRequest ? _backToRequest : _goToMyRequests,
          ),
        ],
        if (_isNoPaymentRequired) ...[
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
                    "No payment required. Your order is fully covered.",
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
            label: _canReturnToRequest ? "Back to Request" : "View My Requests",
            onPressed: _canReturnToRequest ? _backToRequest : _goToMyRequests,
          ),
        ],
        SizedBox(height: isDesktop ? 24 : 16),
        // Coin list (replaces tab selector + QR + address + global button)
        if (!_isExpiredOrInvalid && !_isNoPaymentRequired) ...coinRows,
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
                child: SingleChildScrollView(child: content),
              ),
            ),
          ],
        ),
      );
    }

    return ShopInBitPaymentMobileScaffold(
      onBack: _popToTickets,
      child: content,
    );
  }
}

class _UnownedCoinPaymentDialog extends StatelessWidget {
  const _UnownedCoinPaymentDialog({
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

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: QR(data: address, size: isDesktop ? 200 : 180),
        ),
        if (ticker == "USDT") SizedBox(height: isDesktop ? 24 : 16),
        if (ticker == "USDT")
          RoundedContainer(
            color: Theme.of(
              context,
            ).extension<StackColors>()!.warningBackground,
            child: Center(
              child: Text(
                "IMPORTANT: Only send USDT (TRX20) to this address, not TRX",
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
