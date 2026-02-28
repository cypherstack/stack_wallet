import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_config.dart';
import '../../models/isar/models/ethereum/eth_contract.dart';
import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../notifications/show_flush_bar.dart';
import '../../providers/providers.dart';
import '../../route_generator.dart';
import '../../services/shopinbit/shopinbit_service.dart';
import '../../services/shopinbit/src/models/payment.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/address_utils.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/assets.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/qr.dart';
import '../../widgets/rounded_white_container.dart';
import 'shopinbit_send_from_view.dart';

class ShopInBitPaymentView extends ConsumerStatefulWidget {
  const ShopInBitPaymentView({super.key, required this.model});

  static const String routeName = "/shopInBitPayment";

  final ShopInBitOrderModel model;

  @override
  ConsumerState<ShopInBitPaymentView> createState() =>
      _ShopInBitPaymentViewState();
}

class _ShopInBitPaymentViewState extends ConsumerState<ShopInBitPaymentView> {
  bool _termsAccepted = false;
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

  bool get _payNowEnabled =>
      _termsAccepted && !_isExpiredOrInvalid && !_isTerminal;

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
      final resp = await ShopInBitService.instance.client.getPayment(
        widget.model.apiTicketId,
      );
      if (!resp.hasError && resp.value != null && mounted) {
        setState(() => _applyPaymentInfo(resp.value!));
        if (_isTerminal) {
          _pollTimer?.cancel();
        }
      }
    } catch (_) {}
  }

  Future<void> _loadPayment() async {
    setState(() => _loading = true);
    try {
      final resp = await ShopInBitService.instance.client.getPayment(
        widget.model.apiTicketId,
      );
      if (!resp.hasError && resp.value != null) {
        _applyPaymentInfo(resp.value!);
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
      final resp = await ShopInBitService.instance.client.getPayment(
        widget.model.apiTicketId,
        retry: true,
      );
      if (!resp.hasError && resp.value != null) {
        _applyPaymentInfo(resp.value!);
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
      _startPolling();
    }
  }

  Future<void> _openTerms() async {
    const url = "https://api.shopinbit.com/static/policy/terms.html";
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _checkForPayment() async {
    _pollTimer?.cancel();
    setState(() => _loading = true);
    try {
      final resp = await ShopInBitService.instance.client.getPayment(
        widget.model.apiTicketId,
      );
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

    final coin = AppConfig.getCryptoCurrencyForTicker(ticker);

    String address = "";
    Amount? amount;
    EthContract? tokenContract;

    if (_currentAddress.isNotEmpty) {
      final parsed = AddressUtils.parsePaymentUri(_currentAddress);

      if (parsed?.address != null && parsed!.address.isNotEmpty) {
        address = parsed.address;
      } else {
        final raw = _currentAddress;
        final colonIdx = raw.indexOf(':');
        if (colonIdx != -1) {
          final afterScheme = raw.substring(colonIdx + 1);
          final qIdx = afterScheme.indexOf('?');
          address = qIdx != -1 ? afterScheme.substring(0, qIdx) : afterScheme;
        } else {
          address = raw;
        }
      }

      String? amountStr = parsed?.amount;
      if (amountStr == null || amountStr.isEmpty) {
        final uri = Uri.tryParse(_currentAddress);
        if (uri != null) {
          amountStr = uri.queryParameters['amount'];
        }
      }
      if (amountStr == null || amountStr.isEmpty) {
        amountStr = _paymentInfo?.due;
      }

      final int fractionDigits;
      if (coin != null) {
        fractionDigits = coin.fractionDigits;
      } else if (ticker == "USDT") {
        fractionDigits = 6;
      } else {
        fractionDigits = 8;
      }

      if (amountStr != null && amountStr.isNotEmpty) {
        try {
          amount = Amount.fromDecimal(
            Decimal.parse(amountStr),
            fractionDigits: fractionDigits,
          );
        } catch (_) {}
      }
    }

    if (coin != null && address.isNotEmpty) {
      _navigateToSendFrom(coin: coin, amount: amount, address: address);
      return;
    }

    if (ticker == "USDT" && address.isNotEmpty) {
      const usdtAddress = "0xdac17f958d2ee523a2206206994597c13d831ec7";
      tokenContract = ref.read(mainDBProvider).getEthContractSync(usdtAddress);
      if (tokenContract != null) {
        final ethCoin = AppConfig.getCryptoCurrencyForTicker("ETH");
        if (ethCoin != null) {
          _navigateToSendFrom(
            coin: ethCoin,
            amount: amount,
            address: address,
            tokenContract: tokenContract,
          );
          return;
        }
      }
    }

    widget.model.status = ShopInBitOrderStatus.paymentPending;
    widget.model.paymentMethod = method;

    if (Util.isDesktop) {
      Navigator.of(context, rootNavigator: true).pop();
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _navigateToSendFrom({
    required CryptoCurrency coin,
    required Amount? amount,
    required String address,
    EthContract? tokenContract,
  }) {
    if (Util.isDesktop) {
      Navigator.of(context, rootNavigator: true).pop();
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => ShopInBitSendFromView(
            coin: coin,
            amount: amount,
            address: address,
            model: widget.model,
            shouldPopRoot: true,
            tokenContract: tokenContract,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        RouteGenerator.getRoute<dynamic>(
          shouldUseMaterialRoute: RouteGenerator.useMaterialPageRoute,
          builder: (_) => ShopInBitSendFromView(
            coin: coin,
            amount: amount,
            address: address,
            model: widget.model,
            tokenContract: tokenContract,
          ),
          settings: const RouteSettings(name: ShopInBitSendFromView.routeName),
        ),
      );
    }
  }

  void _copyAddress(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _currentAddress));
    showFloatingFlushBar(
      type: FlushBarType.info,
      message: "Copied to clipboard",
      iconAsset: Assets.svg.copy,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final ticker = _selectedMethod < _methods.length
        ? _methods[_selectedMethod].toUpperCase()
        : "";

    bool hasWallets = false;
    if (ticker == "USDT") {
      const usdtAddress = "0xdac17f958d2ee523a2206206994597c13d831ec7";
      hasWallets = ref
          .watch(pWallets)
          .wallets
          .any(
            (w) =>
                w.info.coin is Ethereum &&
                w.info.tokenContractAddresses.contains(usdtAddress),
          );
    } else {
      final coin = AppConfig.getCryptoCurrencyForTicker(ticker);
      if (coin != null) {
        hasWallets = ref
            .watch(pWallets)
            .wallets
            .any((e) => e.info.coin == coin);
      }
    }

    const loadingOverlay = Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );

    final methodSelector = Row(
      children: List.generate(_methods.length, (index) {
        final isSelected = _selectedMethod == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedMethod = index),
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
                _methods[index],
                textAlign: TextAlign.center,
                style:
                    (isDesktop
                            ? STextStyles.desktopTextExtraExtraSmall(context)
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
    );

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
        ],
        SizedBox(height: isDesktop ? 24 : 16),
        if (!_isExpiredOrInvalid) ...[
          methodSelector,
          SizedBox(height: isDesktop ? 24 : 16),
          if (_currentAddress.isNotEmpty)
            Center(
              child: QR(data: _currentAddress, size: isDesktop ? 200 : 180),
            ),
          if (_currentAddress.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  "No payment address available",
                  style: isDesktop
                      ? STextStyles.desktopTextSmall(context)
                      : STextStyles.itemSubtitle(context),
                ),
              ),
            ),
          SizedBox(height: isDesktop ? 16 : 12),
          if (_currentAddress.isNotEmpty)
            GestureDetector(
              onTap: () => _copyAddress(context),
              child: RoundedWhiteContainer(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          "${_methods[_selectedMethod]} address",
                          style: isDesktop
                              ? STextStyles.desktopTextExtraExtraSmall(context)
                              : STextStyles.itemSubtitle12(context),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.copy,
                          size: 14,
                          color: Theme.of(
                            context,
                          ).extension<StackColors>()!.accentColorBlue,
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
                            _currentAddress,
                            style: isDesktop
                                ? STextStyles.desktopTextExtraExtraSmall(
                                    context,
                                  )
                                : STextStyles.itemSubtitle12(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
        SizedBox(height: isDesktop ? 16 : 12),
        GestureDetector(
          onTap: () {
            setState(() {
              _termsAccepted = !_termsAccepted;
            });
          },
          child: Container(
            color: Colors.transparent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  height: 26,
                  child: IgnorePointer(
                    child: Checkbox(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: _termsAccepted,
                      onChanged: (_) {},
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: isDesktop
                          ? STextStyles.desktopTextExtraExtraSmall(context)
                          : STextStyles.w500_14(context),
                      children: [
                        const TextSpan(text: "I accept the "),
                        TextSpan(
                          text: "Terms & Conditions",
                          style: STextStyles.richLink(
                            context,
                          ).copyWith(fontSize: isDesktop ? null : 14),
                          recognizer: TapGestureRecognizer()
                            ..onTap = _openTerms,
                        ),
                        const TextSpan(text: "."),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        PrimaryButton(
          label: hasWallets ? "PAY NOW" : "CHECK FOR PAYMENT",
          enabled: _payNowEnabled,
          onPressed: _payNowEnabled
              ? (hasWallets ? _confirmPayment : _checkForPayment)
              : null,
        ),
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
                    "ShopInBit",
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
                    if (_loading) loadingOverlay,
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text("ShopInBit", style: STextStyles.navBarTitle(context)),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 32,
                        ),
                        child: IntrinsicHeight(child: content),
                      ),
                    ),
                  ),
                  if (_loading) loadingOverlay,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
