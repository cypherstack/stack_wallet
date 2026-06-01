import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_config.dart';
import '../../notifications/show_flush_bar.dart';
import '../../providers/global/shopin_bit_service_provider.dart';
import '../../providers/providers.dart';
import '../../services/shopinbit/src/models/car_research.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/logger.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/dialogs/s_dialog.dart';
import '../../widgets/icon_widgets/copy_icon.dart';
import '../../widgets/qr.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_dialog.dart';
import '../more_view/services_view.dart';
import 'shopinbit_order_created.dart';
import 'shopinbit_payment_shared.dart';
import 'shopinbit_tickets_view.dart';

enum _PaymentFlowState { idle, polling, finalizing, complete, error }

class ShopInBitCarResearchPaymentView extends ConsumerStatefulWidget {
  const ShopInBitCarResearchPaymentView({super.key, required this.invoice});

  static const String routeName = "/shopInBitCarResearchPayment";

  final CarResearchInvoice invoice;

  @override
  ConsumerState<ShopInBitCarResearchPaymentView> createState() =>
      _ShopInBitCarResearchPaymentViewState();
}

class _ShopInBitCarResearchPaymentViewState
    extends ConsumerState<ShopInBitCarResearchPaymentView> {
  Timer? _pollTimer;
  Map<String, dynamic>? _status;
  _PaymentFlowState _flowState = _PaymentFlowState.idle;
  String _statusString = "ready_to_pay";
  String? _additional;
  List<String> _methods = [];
  List<String> _addresses = [];
  int _selectedMethod = 0;

  String get _currentAddress =>
      _selectedMethod < _addresses.length ? _addresses[_selectedMethod] : "";

  bool get _isTerminal => carResearchIsFinalized(_statusString, _additional);

  bool get _payNowEnabled =>
      !_isTerminal && _flowState == _PaymentFlowState.idle;

  Future<void> _confirmPayment() async {
    // Keep polling while the user is in the send flow.
    final method = _methods[_selectedMethod];
    final ticker = method.toUpperCase();

    final target = parseShopInBitPaymentTarget(
      paymentUri: _currentAddress,
      ticker: ticker,
      coin: AppConfig.getCryptoCurrencyForTicker(ticker),
    );

    final navigated = await tryNavigateToShopInBitWalletSend(
      ref: ref,
      context: context,
      ticker: ticker,
      paymentUri: _currentAddress,
      address: target.address,
      amount: target.amount,
      // The car research fee is paid before any ticket exists.
      apiTicketId: 0,
      // After the wallet send, pop back here so polling can continue.
      routeOnSuccessName: ShopInBitCarResearchPaymentView.routeName,
    );

    if (navigated) return;
    if (!mounted) return;

    // No compatible wallet coin found: surface an info flushbar and keep
    // the user on this screen so they can pay externally and then use the
    // "CHECK FOR PAYMENT" button.
    unawaited(
      showFloatingFlushBar(
        type: FlushBarType.info,
        message:
            "No compatible wallet for $method. "
            "Pay externally, then tap CHECK FOR PAYMENT.",
        context: context,
      ),
    );
  }

  Future<void> _checkForPayment() async {
    if (_flowState != _PaymentFlowState.idle) return;
    setState(() => _flowState = _PaymentFlowState.polling);
    try {
      await _pollStatus();
      if (!mounted) return;
      if (!_isTerminal && _flowState != _PaymentFlowState.finalizing) {
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.info,
            message:
                "Payment not yet confirmed. "
                "Please wait a moment and try again.",
            context: context,
          ),
        );
      }
    } finally {
      if (mounted && _flowState == _PaymentFlowState.polling) {
        setState(() => _flowState = _PaymentFlowState.idle);
      }
    }
  }

  String? _parseBip21Amount(String uri) {
    try {
      // Parse amount from payment URI query params.
      final qIdx = uri.indexOf('?');
      if (qIdx < 0) return null;
      final query = uri.substring(qIdx + 1);
      final params = Uri.splitQueryString(query);
      return params['amount'] ?? params['tx_amount'];
    } catch (_) {
      return null;
    }
  }

  String get _displayedFee {
    // API status endpoint does not expose a fee field (confirmed: returns
    // only {status, additional}). Parse the amount from the BIP21 payment
    // URI for the currently-selected method, fall back to the 223.00 EUR
    // business-rule value if no parse succeeds.
    final links = widget.invoice.paymentLinks;
    if (_selectedMethod < _methods.length) {
      final methodKey = _methods[_selectedMethod];
      // _methods holds upper-cased keys; links map may be case-sensitive.
      String? uri = links[methodKey];
      if (uri == null) {
        for (final entry in links.entries) {
          if (entry.key.toUpperCase() == methodKey) {
            uri = entry.value;
            break;
          }
        }
      }
      if (uri != null) {
        final parsed = _parseBip21Amount(uri);
        if (parsed != null && parsed.isNotEmpty) {
          return "$parsed $methodKey";
        }
      }
    }
    return "223.00 EUR";
  }

  String get _statusLabel {
    switch (_statusString) {
      case "payment_processing":
        return "Confirming...";
      case "paid":
      case "paid_over":
      case "paid_late":
        return "Paid ✓";
      case "ready_to_pay":
      default:
        return "Waiting for payment";
    }
  }

  @override
  void initState() {
    super.initState();
    final links = widget.invoice.paymentLinks;
    _methods = links.keys.map((k) => k.toUpperCase()).toList();
    _addresses = links.values.toList();
    // Kick off an immediate poll then start periodic polling.
    unawaited(_pollStatus());
    _pollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(_pollStatus()),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _popToTickets() {
    Navigator.of(context).popUntil((route) {
      final name = route.settings.name;
      if (name == ShopInBitTicketsView.routeName) {
        return true;
      }
      if (name == ServicesView.routeName) {
        return true;
      }
      if (route.isFirst) {
        return true;
      }
      return false;
    });
  }

  Future<void> _pollStatus() async {
    try {
      final resp = await ref
          .read(pShopinBitService)
          .client
          .getCarResearchInvoiceStatus(widget.invoice.btcpayInvoice);
      if (resp.hasError || resp.value == null) {
        if (mounted) {
          unawaited(
            showFloatingFlushBar(
              type: FlushBarType.warning,
              message:
                  resp.exception?.message ?? "Failed to fetch invoice status",
              context: context,
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      Logging.instance.i(
        "CarResearch status response (payment_view): ${resp.value}",
      );
      Logging.instance.i(
        "CarResearch paymentLinks (payment_view): "
        "${widget.invoice.paymentLinks}",
      );
      setState(() {
        _status = resp.value!;
        _statusString = _status!["status"]?.toString() ?? _statusString;
        _additional = _status!["additional"]?.toString();
      });
      if (_isTerminal) {
        _pollTimer?.cancel();
        await _finalizePayment();
      }
    } catch (e, s) {
      Logging.instance.e(
        "ticket status polling issue",
        error: e,
        stackTrace: s,
      );
      if (mounted) {
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.warning,
            message: e.toString(),
            context: context,
          ),
        );
      }
    }
  }

  Future<void> _finalizePayment() async {
    if (_flowState == _PaymentFlowState.finalizing ||
        _flowState == _PaymentFlowState.complete ||
        _flowState == _PaymentFlowState.error) {
      return;
    }

    setState(() => _flowState = _PaymentFlowState.finalizing);
    _pollTimer?.cancel();

    final service = ref.read(pShopinBitService);
    final client = service.client;

    try {
      // Best-effort: the BTCPay webhook is the failsafe that finalizes the fee
      // and creates the receipt and real car ticket even if this call fails.
      final logResp = await client.logCarResearchPayment(
        widget.invoice.btcpayInvoice,
      );

      if (logResp.hasError || logResp.value == null) {
        // Payment is confirmed but we could not log it. The webhook will
        // finalize it server side, so send the user to their requests where
        // the finalized ticket will appear.
        if (mounted) {
          await showDialog<void>(
            context: context,
            useRootNavigator: Util.isDesktop,
            builder: (context) => StackOkDialog(
              title: "Payment received",
              maxWidth: Util.isDesktop ? 500 : null,
              message:
                  "We're finalizing your car research request. It will "
                  "appear in My Requests shortly.",
              desktopPopRootNavigator: Util.isDesktop,
            ),
          );
        }
        if (mounted) _popToTickets();
        return;
      }

      final result = logResp.value!;

      // log-payment gives us the fee receipt id, which the customer key can't
      // poll; the real car ticket is a separate id. Find and open it, retrying
      // since it can take a beat to show up in by-customer.
      int? realId;
      for (int attempt = 0; attempt < 5 && realId == null; attempt++) {
        realId = await service.adoptRealCarTicket(result.ticketId);
        if (realId == null && attempt < 4) {
          await Future<void>.delayed(const Duration(milliseconds: 1500));
        }
      }

      if (!mounted) return;
      setState(() => _flowState = _PaymentFlowState.complete);

      if (realId != null) {
        unawaited(
          Navigator.of(
            context,
          ).pushNamed(ShopInBitOrderCreated.routeName, arguments: realId),
        );
      } else {
        // The real ticket hasn't surfaced yet; the requests list will pick it
        // up on its next refresh.
        await showDialog<void>(
          context: context,
          useRootNavigator: Util.isDesktop,
          builder: (context) => StackOkDialog(
            title: "Payment received",
            maxWidth: Util.isDesktop ? 500 : null,
            message:
                "We're finalizing your car research request. It will appear "
                "in My Requests shortly.",
            desktopPopRootNavigator: Util.isDesktop,
          ),
        );
        if (mounted) _popToTickets();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _flowState = _PaymentFlowState.error);
        await showDialog<void>(
          context: context,
          useRootNavigator: Util.isDesktop,
          builder: (context) => StackOkDialog(
            title: "Failed to process car research payment",
            maxWidth: Util.isDesktop ? 500 : null,
            message: e.toString(),
            desktopPopRootNavigator: Util.isDesktop,
          ),
        );
      }
    }
  }

  void _copyAddress(BuildContext context) {
    final addr = _currentAddress;
    if (addr.isEmpty) return;
    Clipboard.setData(ClipboardData(text: addr));
    unawaited(
      showFloatingFlushBar(
        type: FlushBarType.info,
        message: "Copied to clipboard",
        iconAsset: Assets.svg.copy,
        context: context,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    final ticker = _selectedMethod < _methods.length
        ? _methods[_selectedMethod].toUpperCase()
        : "";

    final hasWallets = hasShopInBitWalletForTicker(
      wallets: ref.watch(pWallets),
      ticker: ticker,
      paymentUri: _currentAddress,
    );

    final methodSelector = _methods.length <= 1
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              _methods.isEmpty ? "" : _methods.first,
              textAlign: TextAlign.center,
              style: isDesktop
                  ? STextStyles.desktopTextExtraExtraSmall(context)
                  : STextStyles.itemSubtitle12(context),
            ),
          )
        : Row(
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
                                  ? STextStyles.desktopTextExtraExtraSmall(
                                      context,
                                    )
                                  : STextStyles.itemSubtitle12(context))
                              .copyWith(
                                color: isSelected
                                    ? Theme.of(context)
                                          .extension<StackColors>()!
                                          .accentColorBlue
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
      mainAxisSize: .min,
      children: [
        Text(
          "Car research payment",
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
                "Research fee",
                style: isDesktop
                    ? STextStyles.desktopTextSmall(context)
                    : STextStyles.itemSubtitle(context),
              ),
              Text(
                _displayedFee,
                style: isDesktop
                    ? STextStyles.desktopTextSmall(context)
                    : STextStyles.itemSubtitle(context),
              ),
            ],
          ),
        ),
        SizedBox(height: isDesktop ? 16 : 8),
        RoundedWhiteContainer(
          child: Row(
            children: [
              Text(
                "Status:",
                style: isDesktop
                    ? STextStyles.desktopTextExtraExtraSmall(context)
                    : STextStyles.itemSubtitle12(context),
              ),
              const SizedBox(width: 8),
              Text(
                _statusLabel,
                style:
                    (isDesktop
                            ? STextStyles.desktopTextExtraExtraSmall(context)
                            : STextStyles.itemSubtitle12(context))
                        .copyWith(
                          color: _isTerminal
                              ? Theme.of(
                                  context,
                                ).extension<StackColors>()!.accentColorGreen
                              : null,
                          fontWeight: _isTerminal ? FontWeight.w600 : null,
                        ),
              ),
            ],
          ),
        ),
        SizedBox(height: isDesktop ? 24 : 16),
        methodSelector,
        SizedBox(height: isDesktop ? 24 : 16),
        if (_currentAddress.isNotEmpty)
          Center(
            child: QR(data: _currentAddress, size: isDesktop ? 200 : 180),
          )
        else
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
                      CopyIcon(
                        width: 14,
                        height: 14,
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
        if (!isDesktop) const Spacer(),
        if (isDesktop) const SizedBox(height: 24),
        PrimaryButton(
          label: _flowState == _PaymentFlowState.polling
              ? "Checking..."
              : _flowState == _PaymentFlowState.finalizing
              ? "Processing..."
              : (hasWallets ? "PAY NOW" : "CHECK FOR PAYMENT"),
          enabled: _payNowEnabled,
          onPressed: _payNowEnabled
              ? (hasWallets
                    ? () => unawaited(_confirmPayment())
                    : () => unawaited(_checkForPayment()))
              : null,
        ),
      ],
    );

    if (isDesktop) {
      return SDialog(
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
                    child: Text(
                      "ShopinBit",
                      style: STextStyles.desktopH3(context),
                    ),
                  ),
                  const DesktopDialogCloseButton(),
                ],
              ),
              Flexible(
                child: Padding(
                  padding: const .only(
                    left: 32,
                    right: 32,
                    bottom: 32,
                    top: 16,
                  ),
                  child: content,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ShopInBitPaymentMobileScaffold(
      onBack: _popToTickets,
      child: content,
    );
  }
}
