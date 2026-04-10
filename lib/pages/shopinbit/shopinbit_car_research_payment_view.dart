import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/isar/main_db.dart';
import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../notifications/show_flush_bar.dart';
import '../../services/shopinbit/shopinbit_service.dart';
import '../../services/shopinbit/src/models/car_research.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/qr.dart';
import '../../widgets/rounded_white_container.dart';
import 'shopinbit_order_created.dart';

class ShopInBitCarResearchPaymentView extends StatefulWidget {
  const ShopInBitCarResearchPaymentView({
    super.key,
    required this.model,
    required this.invoice,
  });

  static const String routeName = "/shopInBitCarResearchPayment";

  final ShopInBitOrderModel model;
  final CarResearchInvoice invoice;

  @override
  State<ShopInBitCarResearchPaymentView> createState() =>
      _ShopInBitCarResearchPaymentViewState();
}

class _ShopInBitCarResearchPaymentViewState
    extends State<ShopInBitCarResearchPaymentView> {
  static const Set<String> _terminalStates = {
    "paid",
    "paid_over",
    "paid_late",
    "payment_processing",
  };

  Timer? _pollTimer;
  Map<String, dynamic>? _status;
  bool _logging = false;
  String _statusString = "ready_to_pay";
  List<String> _methods = [];
  List<String> _addresses = [];
  int _selectedMethod = 0;

  String get _currentAddress =>
      _selectedMethod < _addresses.length ? _addresses[_selectedMethod] : "";

  bool get _isTerminal => _terminalStates.contains(_statusString);

  String get _displayedFee {
    final s = _status;
    if (s == null) return "—";
    return (s["fee"] ??
            s["amount"] ??
            s["total"] ??
            s["customer_price"] ??
            "—")
        .toString();
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
      setState(() {
        _status = resp.value!;
        _statusString = _status!["status"]?.toString() ?? _statusString;
      });
      if (_isTerminal) {
        _pollTimer?.cancel();
        await _logPayment();
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

  Future<void> _logPayment() async {
    if (_logging) return;
    setState(() => _logging = true);
    try {
      final resp = await ShopInBitService.instance.client
          .logCarResearchPayment(widget.invoice.btcpayInvoice);
      if (resp.hasError || resp.value == null) {
        if (mounted) {
          setState(() => _logging = false);
          unawaited(
            showFloatingFlushBar(
              type: FlushBarType.warning,
              message: resp.exception?.message ?? "Failed to log payment",
              context: context,
            ),
          );
        }
        return;
      }

      final result = resp.value!;
      widget.model.apiTicketId = result.ticketId;
      widget.model.ticketId = result.ticketNumber;
      widget.model.status = ShopInBitOrderStatus.pending;
      await MainDB.instance.putShopInBitTicket(widget.model.toIsarTicket());

      if (!mounted) return;
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
        setState(() => _logging = false);
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
        const Spacer(),
        PrimaryButton(
          label: "I've paid",
          enabled: !_logging,
          onPressed: _logging ? null : () => unawaited(_logPayment()),
        ),
      ],
    );

    if (isDesktop) {
      return DesktopDialog(
        maxWidth: 580,
        maxHeight: 650,
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
                  vertical: 16,
                ),
                child: content,
              ),
            ),
          ],
        ),
      );
    }

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(
          context,
        ).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text("ShopInBit", style: STextStyles.navBarTitle(context)),
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
    );
  }
}
