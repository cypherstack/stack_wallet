import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_config.dart';
import '../../models/shopinbit/shopinbit_order_model.dart';
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
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/dialogs/s_dialog.dart';
import '../../widgets/icon_widgets/copy_icon.dart';
import '../../widgets/qr.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_dialog.dart';
import '../more_view/services_view.dart';
import 'shopinbit_order_created.dart';
import 'shopinbit_payment_shared.dart';
import 'shopinbit_tickets_view.dart';

enum _PaymentFlowState {
  idle,
  polling,
  loggingPayment,
  creatingRequest,
  complete,
  error,
}

class ShopInBitCarResearchPaymentView extends ConsumerStatefulWidget {
  const ShopInBitCarResearchPaymentView({
    super.key,
    required this.model,
    required this.invoice,
  });

  static const String routeName = "/shopInBitCarResearchPayment";

  final ShopInBitOrderModel model;
  final CarResearchInvoice invoice;

  @override
  ConsumerState<ShopInBitCarResearchPaymentView> createState() =>
      _ShopInBitCarResearchPaymentViewState();
}

class _ShopInBitCarResearchPaymentViewState
    extends ConsumerState<ShopInBitCarResearchPaymentView> {
  static const Set<String> _terminalStates = {
    // concierge heritage
    "paid",
    "paid_over",
    "paid_late",
    "payment_processing",
    // BTCPay / car research likely
    "settled",
    "confirmed",
    "complete",
    "completed",
    "finalized",
  };

  Timer? _pollTimer;
  Map<String, dynamic>? _status;
  _PaymentFlowState _flowState = _PaymentFlowState.idle;
  String _statusString = "ready_to_pay";
  List<String> _methods = [];
  List<String> _addresses = [];
  int _selectedMethod = 0;

  String get _currentAddress =>
      _selectedMethod < _addresses.length ? _addresses[_selectedMethod] : "";

  bool get _isTerminal {
    final s = _statusString.toLowerCase().trim();
    return _terminalStates.contains(s);
  }

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
      model: widget.model,
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
      if (!_isTerminal && _flowState != _PaymentFlowState.loggingPayment) {
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
      });
      if (_isTerminal) {
        _pollTimer?.cancel();
        await _processPaymentAndRequest();
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
    }
  }

  Future<void> _processPaymentAndRequest() async {
    // Guard: only one entry allowed
    if (_flowState == _PaymentFlowState.loggingPayment ||
        _flowState == _PaymentFlowState.creatingRequest ||
        _flowState == _PaymentFlowState.complete ||
        _flowState == _PaymentFlowState.error) {
      return;
    }

    // Skip logCarResearchPayment if the fee was already logged.
    final existingFeeTicket = widget.model.feeTicketNumber;
    if (existingFeeTicket != null) {
      if (!widget.model.needsCreateRequest) {
        // Both steps already done: navigate to success directly.
        if (!mounted) return;
        setState(() => _flowState = _PaymentFlowState.complete);

        unawaited(
          Navigator.of(
            context,
          ).pushNamed(ShopInBitOrderCreated.routeName, arguments: widget.model),
        );

        return;
      }
      // Fee logged; skip to createRequest.
      setState(() => _flowState = _PaymentFlowState.creatingRequest);
      _pollTimer?.cancel();
      try {
        final customerKey = await ref
            .read(pShopinBitService)
            .ensureCustomerKey();
        final comment =
            "${widget.model.requestDescription}\n\n"
            "The Client paid the car research fee (#$existingFeeTicket)";
        final reqResp = await ref
            .read(pShopinBitService)
            .client
            .createRequest(
              customerPseudonym: widget.model.displayName,
              externalCustomerKey: customerKey,
              serviceType: "car",
              comment: comment,
              deliveryCountry: widget.model.deliveryCountry,
            );
        if (reqResp.hasError || reqResp.value == null) {
          if (mounted) {
            setState(() => _flowState = _PaymentFlowState.error);
            await showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => StackDialog(
                title: "Request Failed",
                message:
                    "Payment was confirmed but we couldn't submit your car "
                    "research request. You can retry from My Requests.\n\n"
                    "Error: ${reqResp.exception?.message ?? 'Unknown error'}",
                leftButton: SecondaryButton(
                  label: "Retry Now",
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _retryCreateRequest(existingFeeTicket, customerKey);
                  },
                ),
                rightButton: PrimaryButton(
                  label: "My Requests",
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _popToTickets();
                  },
                ),
              ),
            );
          }
          return;
        }
        final requestRef = reqResp.value!;
        final prevTicketId = widget.model.ticketId;
        widget.model.apiTicketId = requestRef.id;
        widget.model.ticketId = requestRef.number;
        widget.model.status = ShopInBitOrderStatus.pending;
        widget.model.isPendingPayment = false;
        widget.model.needsCreateRequest = false;
        final db = ref.read(pSharedDrift);
        await db
            .into(db.shopInBitTickets)
            .insertOnConflictUpdate(widget.model.toCompanion());
        // Remove the sentinel record.
        if (prevTicketId != null && prevTicketId != widget.model.ticketId) {
          await (db.delete(
            db.shopInBitTickets,
          )..where((t) => t.ticketId.equals(prevTicketId))).go();
        }
        if (!mounted) return;
        setState(() => _flowState = _PaymentFlowState.complete);

        unawaited(
          Navigator.of(
            context,
          ).pushNamed(ShopInBitOrderCreated.routeName, arguments: widget.model),
        );
      } catch (e) {
        if (mounted) {
          setState(() => _flowState = _PaymentFlowState.error);
          unawaited(
            showFloatingFlushBar(
              type: FlushBarType.warning,
              message: e.toString(),
              context: context,
            ),
          );
        }
      }
      return;
    }

    setState(() => _flowState = _PaymentFlowState.loggingPayment);
    _pollTimer?.cancel();

    try {
      final logResp = await ref
          .read(pShopinBitService)
          .client
          .logCarResearchPayment(widget.invoice.btcpayInvoice);
      if (logResp.hasError || logResp.value == null) {
        if (mounted) {
          setState(() => _flowState = _PaymentFlowState.error);
          unawaited(
            showFloatingFlushBar(
              type: FlushBarType.warning,
              message: logResp.exception?.message ?? "Failed to log payment",
              context: context,
            ),
          );
        }
        return;
      }

      final feeResult = logResp.value!;

      // Persist feeTicketNumber on the existing model (a new DB row creates a
      // spurious list entry).
      widget.model.feeTicketNumber = feeResult.ticketNumber;
      widget.model.needsCreateRequest = true;
      final db = ref.read(pSharedDrift);
      await db
          .into(db.shopInBitTickets)
          .insertOnConflictUpdate(widget.model.toCompanion());

      if (!mounted) return;
      setState(() => _flowState = _PaymentFlowState.creatingRequest);

      final customerKey = await ref.read(pShopinBitService).ensureCustomerKey();
      final comment =
          "${widget.model.requestDescription}\n\n"
          "The Client paid the car research fee (#${feeResult.ticketNumber})";

      final reqResp = await ref
          .read(pShopinBitService)
          .client
          .createRequest(
            customerPseudonym: widget.model.displayName,
            externalCustomerKey: customerKey,
            serviceType: "car",
            comment: comment,
            deliveryCountry: widget.model.deliveryCountry,
          );

      if (reqResp.hasError || reqResp.value == null) {
        // createRequest failed: fee receipt already persisted, show retry
        if (mounted) {
          setState(() => _flowState = _PaymentFlowState.error);
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => StackDialog(
              title: "Request Failed",
              message:
                  "Payment was confirmed but we couldn't submit your car "
                  "research request. You can retry from My Requests.\n\n"
                  "Error: ${reqResp.exception?.message ?? 'Unknown error'}",
              leftButton: SecondaryButton(
                label: "Retry Now",
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _retryCreateRequest(feeResult.ticketNumber, customerKey);
                },
              ),
              rightButton: PrimaryButton(
                label: "My Requests",
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _popToTickets();
                },
              ),
            ),
          );
        }
        return;
      }

      final requestRef = reqResp.value!;
      final prevTicketId = widget.model.ticketId;
      widget.model.apiTicketId = requestRef.id;
      widget.model.ticketId = requestRef.number;
      widget.model.status = ShopInBitOrderStatus.pending;
      widget.model.isPendingPayment = false;
      widget.model.needsCreateRequest = false;
      await db
          .into(db.shopInBitTickets)
          .insertOnConflictUpdate(widget.model.toCompanion());
      if (prevTicketId != null && prevTicketId != widget.model.ticketId) {
        await (db.delete(
          db.shopInBitTickets,
        )..where((t) => t.ticketId.equals(prevTicketId))).go();
      }

      if (!mounted) return;
      setState(() => _flowState = _PaymentFlowState.complete);

      unawaited(
        Navigator.of(
          context,
        ).pushNamed(ShopInBitOrderCreated.routeName, arguments: widget.model),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _flowState = _PaymentFlowState.error);
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

  Future<void> _retryCreateRequest(
    String feeTicketNumber,
    String customerKey,
  ) async {
    if (_flowState == _PaymentFlowState.creatingRequest) return;
    setState(() => _flowState = _PaymentFlowState.creatingRequest);

    try {
      final comment =
          "${widget.model.requestDescription}\n\n"
          "The Client paid the car research fee (#$feeTicketNumber)";

      final reqResp = await ref
          .read(pShopinBitService)
          .client
          .createRequest(
            customerPseudonym: widget.model.displayName,
            externalCustomerKey: customerKey,
            serviceType: "car",
            comment: comment,
            deliveryCountry: widget.model.deliveryCountry,
          );

      if (reqResp.hasError || reqResp.value == null) {
        if (mounted) {
          setState(() => _flowState = _PaymentFlowState.error);
          unawaited(
            showFloatingFlushBar(
              type: FlushBarType.warning,
              message: reqResp.exception?.message ?? "Retry failed",
              context: context,
            ),
          );
        }
        return;
      }

      final requestRef = reqResp.value!;
      widget.model.apiTicketId = requestRef.id;
      widget.model.ticketId = requestRef.number;
      widget.model.status = ShopInBitOrderStatus.pending;
      // Flow complete: clear the resume flag before saving.
      widget.model.isPendingPayment = false;
      final db = ref.read(pSharedDrift);
      await db
          .into(db.shopInBitTickets)
          .insertOnConflictUpdate(widget.model.toCompanion());

      // Update fee receipt ticket
      final feeTickets = await (db.select(
        db.shopInBitTickets,
      )..where((t) => t.ticketId.equals(feeTicketNumber))).get();
      if (feeTickets.isNotEmpty) {
        final feeTicket = feeTickets.first.copyWith(needsCreateRequest: false);
        await db.into(db.shopInBitTickets).insertOnConflictUpdate(feeTicket);
      }

      if (!mounted) return;
      setState(() => _flowState = _PaymentFlowState.complete);

      unawaited(
        Navigator.of(
          context,
        ).pushNamed(ShopInBitOrderCreated.routeName, arguments: widget.model),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _flowState = _PaymentFlowState.error);
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
              : (_flowState == _PaymentFlowState.loggingPayment ||
                    _flowState == _PaymentFlowState.creatingRequest)
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
