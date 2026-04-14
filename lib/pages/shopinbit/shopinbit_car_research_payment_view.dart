import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_config.dart';
import '../../db/isar/main_db.dart';
import '../../models/isar/models/ethereum/eth_contract.dart';
import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../notifications/show_flush_bar.dart';
import '../../providers/providers.dart';
import '../../route_generator.dart';
import '../../services/shopinbit/shopinbit_service.dart';
import '../../services/shopinbit/src/models/car_research.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/address_utils.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/assets.dart';
import '../../utilities/logger.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../more_view/services_view.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/qr.dart';
import '../../widgets/rounded_white_container.dart';
import 'shopinbit_order_created.dart';
import 'shopinbit_send_from_view.dart';
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

  bool get _payNowEnabled => !_isTerminal && _flowState == _PaymentFlowState.idle;

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
      // Car research flow has no concierge PaymentInfo.due fallback.

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

    // No compatible wallet coin found — surface an info flushbar and keep
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
                "Payment not yet confirmed. Please wait a moment and try again.",
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
      final resp = await ShopInBitService.instance.client
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
        _flowState == _PaymentFlowState.complete) return;

    setState(() => _flowState = _PaymentFlowState.loggingPayment);
    _pollTimer?.cancel();

    try {
      final logResp = await ShopInBitService.instance.client
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

      // Step 2: Persist fee receipt ticket
      final feeModel = ShopInBitOrderModel()
        ..ticketId = feeResult.ticketNumber
        ..apiTicketId = feeResult.ticketId
        ..category = ShopInBitCategory.car
        ..status = ShopInBitOrderStatus.pending
        ..displayName = widget.model.displayName
        ..requestDescription = "Car research fee receipt"
        ..deliveryCountry = widget.model.deliveryCountry
        ..needsCreateRequest = true
        ..carResearchInvoiceId = widget.invoice.btcpayInvoice
        ..feeTicketNumber = feeResult.ticketNumber;
      await MainDB.instance.putShopInBitTicket(feeModel.toIsarTicket());

      if (!mounted) return;
      setState(() => _flowState = _PaymentFlowState.creatingRequest);

      final customerKey = await ShopInBitService.instance.ensureCustomerKey();
      final comment = "${widget.model.requestDescription}\n\n"
          "The Client paid the car research fee (#${feeResult.ticketNumber})";

      final reqResp = await ShopInBitService.instance.client.createRequest(
        customerPseudonym: widget.model.displayName,
        externalCustomerKey: customerKey,
        serviceType: "car_research",
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
            builder: (ctx) => AlertDialog(
              title: const Text("Request Failed"),
              content: Text(
                "Payment was confirmed but we couldn't submit your car "
                "research request. You can retry from My Requests.\n\n"
                "Error: ${reqResp.exception?.message ?? 'Unknown error'}",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _retryCreateRequest(feeResult.ticketNumber, customerKey);
                  },
                  child: const Text("Retry Now"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _popToTickets();
                  },
                  child: const Text("Go to My Requests"),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Step 4: Persist request ticket
      final requestRef = reqResp.value!;
      widget.model.apiTicketId = requestRef.id;
      widget.model.ticketId = requestRef.number;
      widget.model.status = ShopInBitOrderStatus.pending;
      await MainDB.instance.putShopInBitTicket(widget.model.toIsarTicket());

      // Step 5: Update fee receipt — mark createRequest as done
      feeModel.needsCreateRequest = false;
      await MainDB.instance.putShopInBitTicket(feeModel.toIsarTicket());

      if (!mounted) return;
      setState(() => _flowState = _PaymentFlowState.complete);

      if (Util.isDesktop) {
        Navigator.of(context, rootNavigator: true).pop();
        unawaited(
          showDialog<void>(
            context: context,
            builder: (_) => ShopInBitOrderCreated(model: widget.model),
          ),
        );
      } else {
        unawaited(
          Navigator.of(context).pushNamed(
            ShopInBitOrderCreated.routeName,
            arguments: widget.model,
          ),
        );
      }
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
      final comment = "${widget.model.requestDescription}\n\n"
          "The Client paid the car research fee (#$feeTicketNumber)";

      final reqResp = await ShopInBitService.instance.client.createRequest(
        customerPseudonym: widget.model.displayName,
        externalCustomerKey: customerKey,
        serviceType: "car_research",
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
      await MainDB.instance.putShopInBitTicket(widget.model.toIsarTicket());

      // Update fee receipt ticket
      final feeTickets = MainDB.instance
          .getShopInBitTickets()
          .where((t) => t.ticketId == feeTicketNumber);
      if (feeTickets.isNotEmpty) {
        final feeTicket = feeTickets.first;
        feeTicket.needsCreateRequest = false;
        await MainDB.instance.putShopInBitTicket(feeTicket);
      }

      if (!mounted) return;
      setState(() => _flowState = _PaymentFlowState.complete);

      if (Util.isDesktop) {
        Navigator.of(context, rootNavigator: true).pop();
        unawaited(
          showDialog<void>(
            context: context,
            builder: (_) => ShopInBitOrderCreated(model: widget.model),
          ),
        );
      } else {
        unawaited(
          Navigator.of(context).pushNamed(
            ShopInBitOrderCreated.routeName,
            arguments: widget.model,
          ),
        );
      }
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

    final methodSelector = _methods.length <= 1
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              _methods.isEmpty ? "—" : _methods.first,
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
                              ? Theme.of(context)
                                    .extension<StackColors>()!
                                    .accentColorBlue
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
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : null,
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
                              ? Theme.of(context)
                                    .extension<StackColors>()!
                                    .accentColorGreen
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
                    ? _confirmPayment
                    : () => unawaited(_checkForPayment()))
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
                  vertical: 16,
                ),
                child: SingleChildScrollView(child: content),
              ),
            ),
          ],
        ),
      );
    }

    return Background(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (!didPop) {
            _popToTickets();
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(
            context,
          ).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: AppBarBackButton(
              onPressed: _popToTickets,
            ),
            title: Text("ShopinBit", style: STextStyles.navBarTitle(context)),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32,
                      ),
                      child: IntrinsicHeight(child: content),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
