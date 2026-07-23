import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_config.dart';
import '../../db/drift/shared_db/shared_database.dart';
import '../../models/shopinbit/shopinbit_enums.dart';
import '../../notifications/show_flush_bar.dart';
import '../../providers/global/shopin_bit_service_provider.dart';
import '../../services/shopinbit/shopinbit_api.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/logger.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/dialogs/s_dialog.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_dialog.dart';
import '../home_view/home_view.dart';
import 'shopinbit_order_created.dart';
import 'shopinbit_payment_method_list.dart';
import 'shopinbit_payment_shared.dart';
import 'shopinbit_tickets_view.dart';

enum _PaymentFlowState { idle, polling, finalizing, complete }

class ShopInBitCarResearchPaymentView extends ConsumerStatefulWidget {
  const ShopInBitCarResearchPaymentView({
    super.key,
    required this.invoice,
    required this.customerKey,
  });

  static const String routeName = "/shopInBitCarResearchPayment";

  final CarResearchInvoice invoice;
  final String customerKey;

  @override
  ConsumerState<ShopInBitCarResearchPaymentView> createState() =>
      _ShopInBitCarResearchPaymentViewState();
}

class _ShopInBitCarResearchPaymentViewState
    extends ConsumerState<ShopInBitCarResearchPaymentView>
    with WidgetsBindingObserver {
  Timer? _pollTimer;

  static const Duration _kBasePollInterval = Duration(seconds: 15);
  static const Duration _kMaxPollInterval = Duration(seconds: 120);
  Duration _pollInterval = _kBasePollInterval;

  CarResearchInvoiceStatus? _status;
  _PaymentFlowState _flowState = _PaymentFlowState.idle;
  String _statusString = "ready_to_pay";
  String? _additional;
  bool _finalized = false;
  // The real car ticket id (the customer chat) from the finalized status.
  int? _realTicketId;
  List<String> _methods = [];
  List<String> _addresses = [];
  int _selectedMethod = 0;

  String get _currentAddress =>
      _selectedMethod < _addresses.length ? _addresses[_selectedMethod] : "";

  // Trust the `finalized` flag; fall back to the status/additional heuristic.
  bool get _isTerminal =>
      _finalized || carResearchIsFinalized(_statusString, _additional);

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
    // The status endpoint has no fee field, so parse the amount from the
    // selected method's BIP21 URI, falling back to the 223.00 EUR business
    // rule.
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
    WidgetsBinding.instance.addObserver(this);
    final links = widget.invoice.paymentLinks;
    _methods = links.keys.map((k) => k.toUpperCase()).toList();
    _addresses = links.values.toList();
    // Kick off an immediate poll then start periodic polling.
    unawaited(_pollStatus());
    _scheduleNextPoll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Don't poll while backgrounded; resume fresh when we come back.
    if (state == AppLifecycleState.resumed) {
      if (!_isTerminal && _flowState != _PaymentFlowState.finalizing) {
        _pollInterval = _kBasePollInterval;
        _scheduleNextPoll();
      }
    } else {
      _pollTimer?.cancel();
    }
  }

  void _scheduleNextPoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer(_pollInterval, _pollTick);
  }

  /// Periodic driver: poll once, then reschedule with backoff on failure and
  /// reset on success. Stops once the flow is terminal or finalizing.
  Future<void> _pollTick() async {
    final bool ok = await _pollStatus();
    if (!mounted) return;
    if (_isTerminal ||
        _flowState == _PaymentFlowState.finalizing ||
        _flowState == _PaymentFlowState.complete) {
      return;
    }
    _pollInterval = ok
        ? _kBasePollInterval
        : ShopInBitClient.nextPollBackoff(_pollInterval, _kMaxPollInterval);
    _scheduleNextPoll();
  }

  void _popToTickets() {
    Navigator.of(context).popUntil((route) {
      final name = route.settings.name;
      if (name == ShopInBitTicketsView.routeName) {
        return true;
      }
      if (route.isFirst || name == HomeView.routeName) {
        return true;
      }
      return false;
    });
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
      return route.isFirst || name == HomeView.routeName;
    });
    if (!landedOnTickets) {
      unawaited(navigator.pushNamed(ShopInBitTicketsView.routeName));
    }
  }

  Future<void> _showFinalizingFallback() async {
    final goToRequests = await showDialog<bool>(
      context: context,
      useRootNavigator: Util.isDesktop,
      builder: (context) => StackDialog(
        title: "Payment received",
        message:
            "We're finalizing your car research request. It will appear in "
            "My Requests shortly.",
        width: Util.isDesktop ? 580 : null,
        leftButton: SecondaryButton(
          label: "Close",
          buttonHeight: Util.isDesktop ? .l : null,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        rightButton: PrimaryButton(
          label: "My Requests",
          buttonHeight: Util.isDesktop ? .l : null,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ),
    );
    if (!mounted) return;
    if (goToRequests == true) {
      _goToMyRequests();
    } else {
      _popToTickets();
    }
  }

  /// Fetch invoice status once and apply it. Returns false on any failure so
  /// the periodic driver can back off instead of polling at full rate.
  Future<bool> _pollStatus() async {
    try {
      final service = ref.read(pShopinBitService);

      final resp = await service.client.getCarResearchInvoiceStatus(
        widget.invoice.btcpayInvoice,
        customerKey: widget.customerKey,
      );
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
        return false;
      }

      final apiTicketId = resp.value!.realTicketId;
      if (apiTicketId != null) {
        // we may not have the ticket in the db yet. Lets check
        final ticket = await service.db.shopInBitTicketsDao.getByApiId(
          apiTicketId,
        );

        // not found, so lets fix that
        if (ticket == null) {
          final invoiceStatus = resp.value!;

          final response = await service.client.getTicketFull(
            apiTicketId,
            customerKey: invoiceStatus.externalCustomerKey,
          );

          if (response.hasError || response.value == null) {
            Logging.instance.e(
              "$runtimeType get full ticket for car failed",
              error: response.exception,
              stackTrace: .current,
            );
          } else {
            final fullTicket = response.value!;

            // TODO: clean this up a bit some day but for now...
            await service.db.transaction(() async {
              // get ticket again to ensure this is an atomic insert operation
              // in the db transaction
              final ticket = await service.db.shopInBitTicketsDao.getByApiId(
                apiTicketId,
              );

              if (ticket == null) {
                const ticketState = TicketState.newTicket;
                // insert bare minimum - will be updated automatically later
                await service.db.shopInBitTicketsDao.insertTicket(
                  ShopInBitTicketsCompanion.insert(
                    apiTicketId: apiTicketId,
                    customerKey: invoiceStatus.externalCustomerKey,
                    ticketNumber: invoiceStatus.realTicketNumber!,
                    category: .car,
                    requestDescription: fullTicket.productName ?? "",
                    deliveryCountry: fullTicket.deliveryCountry,
                    status: ShopInBitOrderStatus.fromTicketState(ticketState)!,
                    statusRaw: ticketState.value,
                  ),
                );
              }
            });
          }
        }
      }

      if (!mounted) return true;
      Logging.instance.i(
        "CarResearch status response (payment_view): ${resp.value}",
      );
      Logging.instance.i(
        "CarResearch paymentLinks (payment_view): "
        "${widget.invoice.paymentLinks}",
      );
      setState(() {
        _status = resp.value!;
        _statusString = _status!.status.isNotEmpty
            ? _status!.status
            : _statusString;
        _additional = _status!.additional;
        _finalized = _status!.finalized;
        _realTicketId = _status!.realTicketId;
      });
      if (_isTerminal) {
        _pollTimer?.cancel();
        await _finalizePayment();
      }
      return true;
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
      return false;
    }
  }

  Future<void> _finalizePayment() async {
    if (_flowState == _PaymentFlowState.finalizing ||
        _flowState == _PaymentFlowState.complete) {
      return;
    }

    final int? realId = _realTicketId;
    if (realId == null) {
      setState(() => _flowState = _PaymentFlowState.finalizing);
      await _showFinalizingFallback();
      return;
    }

    setState(() => _flowState = _PaymentFlowState.complete);
    unawaited(
      Navigator.of(
        context,
      ).pushNamed(ShopInBitOrderCreated.routeName, arguments: realId),
    );
  }

  void _onOwnedCoinTap(int methodIndex) {
    if (!_payNowEnabled) return;
    setState(() => _selectedMethod = methodIndex);
    unawaited(_confirmPayment());
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

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
        ShopInBitPaymentMethodList(
          methods: _methods,
          addresses: _addresses,
          enabled: _payNowEnabled,
          onPayFromWallet: _onOwnedCoinTap,
          onCheckForPayment: (methodIndex) {
            _selectedMethod = methodIndex;
            unawaited(_checkForPayment());
          },
        ),
        if (_flowState == _PaymentFlowState.polling ||
            _flowState == _PaymentFlowState.finalizing) ...[
          SizedBox(height: isDesktop ? 24 : 16),
          PrimaryButton(
            label: _flowState == _PaymentFlowState.polling
                ? "Checking..."
                : "Processing...",
            enabled: false,
            onPressed: null,
          ),
        ],
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
