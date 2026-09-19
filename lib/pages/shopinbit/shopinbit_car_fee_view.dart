import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/shopinbit/shopinbit_request_draft.dart';
import '../../providers/global/shopin_bit_service_provider.dart';
import '../../services/shopinbit/shopinbit_service.dart';
import '../../services/shopinbit/src/models/address.dart';
import '../../services/shopinbit/src/models/car_research.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/logger.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/detail_item.dart';
import '../../widgets/dialogs/nested_navigator_dialog/nested_navigator_dialog.dart';
import '../../widgets/dialogs/s_dialog.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_dialog.dart';
import '../../widgets/textfields/adaptive_text_field.dart';
import '../home_view/home_view.dart';
import 'shopinbit_car_research_payment_view.dart';
import 'shopinbit_step_2.dart';

class ShopInBitCarFeeView extends ConsumerStatefulWidget {
  const ShopInBitCarFeeView({super.key, required this.draft});

  static const String routeName = "/shopInBitCarFee";

  final ShopinbitRequestDraft draft;

  @override
  ConsumerState<ShopInBitCarFeeView> createState() =>
      _ShopInBitCarFeeViewState();
}

class _ShopInBitCarFeeViewState extends ConsumerState<ShopInBitCarFeeView> {
  late final TextEditingController _billingFirstNameController;
  late final TextEditingController _billingLastNameController;
  late final TextEditingController _billingStreetController;
  late final TextEditingController _billingCityController;
  late final TextEditingController _billingPostalCodeController;

  String _displayedFee = "223.00 EUR";
  bool _submitting = false;

  bool _canContinue = false;

  void _validate() {
    final valid =
        _billingFirstNameController.text.trim().isNotEmpty &&
        _billingLastNameController.text.trim().isNotEmpty &&
        _billingStreetController.text.trim().isNotEmpty &&
        _billingCityController.text.trim().isNotEmpty &&
        _billingPostalCodeController.text.trim().isNotEmpty &&
        widget.draft.deliveryCountryCode.isNotEmpty;

    if (_canContinue != valid && mounted) {
      setState(() {
        _canContinue = valid;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _billingFirstNameController = TextEditingController();
    _billingLastNameController = TextEditingController();
    _billingStreetController = TextEditingController();
    _billingCityController = TextEditingController();
    _billingPostalCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _billingFirstNameController.dispose();
    _billingLastNameController.dispose();
    _billingStreetController.dispose();
    _billingCityController.dispose();
    _billingPostalCodeController.dispose();
    super.dispose();
  }

  void _popToStep2() {
    Navigator.of(context).popUntil((route) {
      final name = route.settings.name;
      if (name == ShopInBitStep2.routeName) {
        return true;
      }
      if (route.isFirst || name == HomeView.routeName) {
        return true;
      }
      return false;
    });
  }

  Future<void> _createInvoice() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final customerKey = await ref.read(pShopinBitService).ensureCustomerKey();

      final billing = Address(
        firstName: _billingFirstNameController.text.trim(),
        lastName: _billingLastNameController.text.trim(),
        street: _billingStreetController.text.trim(),
        zip: _billingPostalCodeController.text.trim(),
        city: _billingCityController.text.trim(),
        country: widget.draft.deliveryCountryCode,
        state: widget.draft.requiresState ? widget.draft.deliveryState! : null,
      );

      // Cache the car request alongside billing so the backend failsafe can
      // create the real car research ticket once the fee is paid.
      final request = CarResearchRequest(
        customerPseudonym: kShopInBitCustomerPseudonym,
        comment: widget.draft.requestDescription,
        deliveryCountry: widget.draft.deliveryCountryCode,
        deliveryState: billing.state,
      );

      final resp = await ref
          .read(pShopinBitService)
          .client
          .createCarResearchInvoice(
            billing: billing,
            request: request,
            customerKey: customerKey,
          );

      if (resp.hasError || resp.value == null) {
        Logging.instance.e(
          "Failed to create invoice",
          error: resp.exception,
          stackTrace: StackTrace.current,
        );

        if (mounted) {
          setState(() => _submitting = false);
          await showDialog<void>(
            context: context,
            useRootNavigator: Util.isDesktop,
            builder: (context) => StackOkDialog(
              title: "Failed to create invoice",
              maxWidth: Util.isDesktop ? 500 : null,
              message: resp.exception?.message,
              desktopPopRootNavigator: Util.isDesktop,
            ),
          );
        }
        return;
      }

      final invoice = resp.value!;

      // No local persistence: an unfinished fee is recovered server-side via
      // `GET /car-research/invoices/current` (see the requests list).

      // Best-effort fee fetch; do not block navigation on fee parse failure.
      await _loadFee(invoice, customerKey);

      if (!mounted) return;

      unawaited(
        Navigator.of(context).pushNamed(
          ShopInBitCarResearchPaymentView.routeName,
          arguments: (invoice: invoice, customerKey: customerKey),
        ),
      );
    } catch (e, s) {
      Logging.instance.e("Create invoice failed", error: e, stackTrace: s);
      if (mounted) {
        setState(() => _submitting = false);
        await showDialog<void>(
          context: context,
          useRootNavigator: Util.isDesktop,
          builder: (context) => StackOkDialog(
            title: "Failed to create invoice",
            maxWidth: Util.isDesktop ? 500 : null,
            message: e.toString(),
            desktopPopRootNavigator: Util.isDesktop,
          ),
        );
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

  Future<void> _loadFee(CarResearchInvoice invoice, String customerKey) async {
    // Still hit status for logging; it has no fee field, so the amount comes
    // from the BIP21 payment URIs.
    try {
      final resp = await ref
          .read(pShopinBitService)
          .client
          .getCarResearchInvoiceStatus(
            invoice.btcpayInvoice,
            customerKey: customerKey,
          );
      if (resp.hasError || resp.value == null) {
        Logging.instance.i(
          "CarResearch status response (car_fee_view): error "
          "${resp.exception?.message}",
        );
      } else {
        Logging.instance.i(
          "CarResearch status response (car_fee_view): ${resp.value}",
        );
      }
    } catch (e) {
      Logging.instance.i(
        "CarResearch status response (car_fee_view): threw $e",
      );
    }

    // Primary fee source: parse BIP21 `amount` query param from paymentLinks.
    Logging.instance.i(
      "CarResearch paymentLinks (car_fee_view): ${invoice.paymentLinks}",
    );
    try {
      for (final entry in invoice.paymentLinks.entries) {
        final parsed = _parseBip21Amount(entry.value);
        if (parsed != null && parsed.isNotEmpty) {
          if (mounted) {
            setState(
              () => _displayedFee = "$parsed ${entry.key.toUpperCase()}",
            );
          }
          return;
        }
      }
    } catch (_) {
      // Leave placeholder in place.
    }
    // No parse succeeded: leave the existing "223.00 EUR" business-rule
    // placeholder in place rather than showing "--".
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final spacing = SizedBox(height: isDesktop ? 16 : 12);

    final content = Column(
      mainAxisSize: .min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Car research fee",
          style: isDesktop
              ? STextStyles.desktopH2(context)
              : STextStyles.pageTitleH1(context),
        ),
        SizedBox(height: isDesktop ? 16 : 8),
        RoundedWhiteContainer(
          borderColor: isDesktop
              ? Theme.of(context).extension<StackColors>()!.textFieldDefaultBG
              : null,
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
        SizedBox(height: isDesktop ? 24 : 16),
        Text(
          "Billing address",
          style: isDesktop
              ? STextStyles.desktopTextSmall(context)
              : STextStyles.titleBold12(context),
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        AdaptiveTextField(
          controller: _billingFirstNameController,
          labelText: "First name",
          autocorrect: false,
          enableSuggestions: false,
          onChangedComprehensive: (_) => _validate(),
        ),
        spacing,
        AdaptiveTextField(
          controller: _billingLastNameController,
          labelText: "Last name",
          autocorrect: false,
          enableSuggestions: false,
          onChangedComprehensive: (_) => _validate(),
        ),
        spacing,
        AdaptiveTextField(
          controller: _billingStreetController,
          labelText: "Street address",
          autocorrect: false,
          enableSuggestions: false,
          onChangedComprehensive: (_) => _validate(),
        ),
        spacing,
        Row(
          children: [
            Expanded(
              child: AdaptiveTextField(
                controller: _billingCityController,
                labelText: "City",
                autocorrect: false,
                enableSuggestions: false,
                onChangedComprehensive: (_) => _validate(),
              ),
            ),
            SizedBox(width: isDesktop ? 16 : 12),
            Expanded(
              child: AdaptiveTextField(
                controller: _billingPostalCodeController,
                labelText: "Postal code",
                autocorrect: false,
                enableSuggestions: false,
                onChangedComprehensive: (_) => _validate(),
              ),
            ),
          ],
        ),

        spacing,
        DetailItem(
          title: "Country",
          detail:
              "${widget.draft.deliveryCountryName} "
              "(${widget.draft.deliveryCountryCode})",
          disableSelectableText: true,
        ),
        if (widget.draft.requiresState) spacing,
        if (widget.draft.requiresState)
          DetailItem(title: "State", detail: widget.draft.deliveryState!),
        if (!isDesktop) const Spacer(),
        if (isDesktop) const SizedBox(height: 24),
        PrimaryButton(
          label: "Pay research fee",
          enabled: _canContinue && !_submitting,
          onPressed: (_canContinue && !_submitting)
              ? () => unawaited(_createInvoice())
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
                  DesktopDialogCloseButton(
                    onPressedOverride: () =>
                        NestedNavigatorDialog.of(context).close(),
                  ),
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

    return Background(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (!didPop) {
            _popToStep2();
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(
            context,
          ).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: AppBarBackButton(onPressed: _popToStep2),
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
