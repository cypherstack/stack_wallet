import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/drift/shared_db/shared_database.dart';
import '../../providers/global/shopin_bit_service_provider.dart';
import '../../services/shopinbit/src/models/address.dart';
import '../../services/shopinbit/src/models/payment.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/logger.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/detail_item.dart';
import '../../widgets/dialogs/s_dialog.dart';
import '../../widgets/stack_dialog.dart';
import '../../widgets/textfields/adaptive_text_field.dart';
import 'shopinbit_payment_shared.dart';
import 'shopinbit_payment_view.dart';
import 'step_4_components/shopinbit_country_picker.dart';
import 'step_4_components/shopinbit_state_picker.dart';

class ShopInBitShippingView extends ConsumerStatefulWidget {
  const ShopInBitShippingView({
    super.key,
    required this.ticket,
    required this.countries,
  });

  static const String routeName = "/shopInBitShipping";

  final ShopInBitTicket ticket;
  final List<Map<String, dynamic>> countries;

  @override
  ConsumerState<ShopInBitShippingView> createState() =>
      _ShopInBitShippingViewState();
}

class _ShopInBitShippingViewState extends ConsumerState<ShopInBitShippingView> {
  late final TextEditingController _nameFirstController;
  late final TextEditingController _nameLastController;
  late final TextEditingController _streetController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalCodeController;
  late final FocusNode _nameFirstFocusNode;
  late final FocusNode _nameLastFocusNode;
  late final FocusNode _streetFocusNode;
  late final FocusNode _cityFocusNode;
  late final FocusNode _postalCodeFocusNode;

  // Billing address controllers
  late final TextEditingController _billingFirstNameController;
  late final TextEditingController _billingLastNameController;
  late final TextEditingController _billingStreetController;
  late final TextEditingController _billingCityController;
  late final TextEditingController _billingPostalCodeController;
  late final FocusNode _billingFirstNameFocusNode;
  late final FocusNode _billingLastNameFocusNode;
  late final FocusNode _billingStreetFocusNode;
  late final FocusNode _billingCityFocusNode;
  late final FocusNode _billingPostalCodeFocusNode;

  String? _billingSelectedCountryIso;
  bool _differentBilling = false;

  late final String _selectedCountryIso;
  late final String _deliveryCountryLabel;

  late final String? _selectedState;

  String? _selectedBillingState;

  late bool _requiresState;

  bool _submitting = false;

  bool get _canContinue {
    if (_submitting) return false;
    final shippingValid =
        _nameFirstController.text.trim().isNotEmpty &&
        _nameLastController.text.trim().isNotEmpty &&
        _streetController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty &&
        _postalCodeController.text.trim().isNotEmpty;
    if (!shippingValid) return false;
    if (_differentBilling) {
      return _billingFirstNameController.text.trim().isNotEmpty &&
          _billingLastNameController.text.trim().isNotEmpty &&
          _billingStreetController.text.trim().isNotEmpty &&
          _billingCityController.text.trim().isNotEmpty &&
          _billingPostalCodeController.text.trim().isNotEmpty &&
          _billingSelectedCountryIso != null;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _nameFirstController = TextEditingController();
    _nameLastController = TextEditingController();
    _streetController = TextEditingController();
    _cityController = TextEditingController();
    _postalCodeController = TextEditingController();
    _nameFirstFocusNode = FocusNode();
    _nameLastFocusNode = FocusNode();
    _streetFocusNode = FocusNode();
    _cityFocusNode = FocusNode();
    _postalCodeFocusNode = FocusNode();

    _billingFirstNameController = TextEditingController();
    _billingLastNameController = TextEditingController();
    _billingStreetController = TextEditingController();
    _billingCityController = TextEditingController();
    _billingPostalCodeController = TextEditingController();
    _billingFirstNameFocusNode = FocusNode();
    _billingLastNameFocusNode = FocusNode();
    _billingStreetFocusNode = FocusNode();
    _billingCityFocusNode = FocusNode();
    _billingPostalCodeFocusNode = FocusNode();

    _selectedCountryIso = widget.ticket.deliveryCountry;

    _requiresState = switch (_selectedCountryIso) {
      "US" || "CA" => widget.ticket.category != .travel,
      _ => false,
    };

    if (_requiresState) {
      final parts = widget.ticket.messages.firstOrNull?.content.split("\n");
      if (parts == null) {
        Logging.instance.f("Missing state/province where required!");
        throw ArgumentError("Missing first ticket message");
      }

      final line = parts
          .where(
            (e) => e.startsWith("Delivery state:") || e.startsWith("State:"),
          )
          .firstOrNull;
      if (line == null) {
        Logging.instance.f("Missing state/province in first message!");
        throw ArgumentError("Missing state/province in first ticket message");
      }

      _selectedState = line
          .replaceFirst("Delivery state:", "")
          .replaceFirst("State:", "")
          .trim();
    } else {
      _selectedState = null;
    }

    // firstWhere should never fail here as the caller of this widget must
    // check that countries contains the expected value. Failure here should be
    // considered unrecoverable/fatal as it indicates a bug elsewhere
    _deliveryCountryLabel =
        widget.countries.firstWhere(
              (e) => e["iso"] == _selectedCountryIso,
            )["label"]
            as String;

    for (final node in [
      _nameFirstFocusNode,
      _nameLastFocusNode,
      _streetFocusNode,
      _cityFocusNode,
      _postalCodeFocusNode,
      _billingFirstNameFocusNode,
      _billingLastNameFocusNode,
      _billingStreetFocusNode,
      _billingCityFocusNode,
      _billingPostalCodeFocusNode,
    ]) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameFirstController.dispose();
    _nameLastController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _nameFirstFocusNode.dispose();
    _nameLastFocusNode.dispose();
    _streetFocusNode.dispose();
    _cityFocusNode.dispose();
    _postalCodeFocusNode.dispose();
    _billingFirstNameController.dispose();
    _billingLastNameController.dispose();
    _billingStreetController.dispose();
    _billingCityController.dispose();
    _billingPostalCodeController.dispose();
    _billingFirstNameFocusNode.dispose();
    _billingLastNameFocusNode.dispose();
    _billingStreetFocusNode.dispose();
    _billingCityFocusNode.dispose();
    _billingPostalCodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final nameFirst = _nameFirstController.text.trim();
    final nameLast = _nameLastController.text.trim();
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final postalCode = _postalCodeController.text.trim();
    final country = _selectedCountryIso;

    PaymentInfo? paymentInfo;
    setState(() => _submitting = true);
    try {
      Address? billingAddress;
      if (_differentBilling) {
        billingAddress = Address(
          firstName: _billingFirstNameController.text.trim(),
          lastName: _billingLastNameController.text.trim(),
          street: _billingStreetController.text.trim(),
          zip: _billingPostalCodeController.text.trim(),
          city: _billingCityController.text.trim(),
          country: _requiresState ? country : _billingSelectedCountryIso!,
          state: _requiresState ? _selectedState : _selectedBillingState,
        );
      }

      final resp = await ref
          .read(pShopinBitService)
          .client
          .submitAddress(
            widget.ticket.apiTicketId,
            shipping: Address(
              firstName: nameFirst,
              lastName: nameLast,
              street: street,
              zip: postalCode,
              city: city,
              country: country,
              state: _requiresState ? _selectedState! : null,
            ),
            billing: billingAddress,
            customerKey: widget.ticket.customerKey,
          );

      if (resp.hasError) {
        // Sandbox may fail here; continue anyway.
        Logging.instance.w("submitAddress failed", error: resp.exception);
      }

      paymentInfo = await fetchShopInBitPaymentInfo(
        ref.read(pShopinBitService).client,
        widget.ticket.apiTicketId,
        widget.ticket.customerKey,
      );
    } catch (e, s) {
      Logging.instance.e("submitAddress threw", error: e, stackTrace: s);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }

    if (!mounted) return;

    // no_payment_required legitimately has empty payment_links (voucher/credit
    // covers it): open the payment view, which shows a "covered" state.
    if (paymentInfo == null ||
        (paymentInfo.paymentLinks.isEmpty &&
            paymentInfo.status != 'no_payment_required')) {
      // No live invoice; don't open a payment view with empty addresses.
      await _showPaymentLoadError(
        "We couldn't load the payment details for this order. "
        "Please try again in a moment.",
      );
      return;
    }

    await Navigator.of(context).pushNamed(
      ShopInBitPaymentView.routeName,
      arguments: (
        apiTicketId: widget.ticket.apiTicketId,
        paymentInfo: paymentInfo,
      ),
    );
  }

  Future<void> _showPaymentLoadError(String message) async {
    await showDialog<void>(
      context: context,
      useRootNavigator: Util.isDesktop,
      builder: (context) => StackOkDialog(
        title: "Couldn't load payment details",
        maxWidth: Util.isDesktop ? 500 : null,
        message: message,
        desktopPopRootNavigator: Util.isDesktop,
      ),
    );
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
          "Shipping address",
          style: isDesktop
              ? STextStyles.desktopH2(context)
              : STextStyles.pageTitleH1(context),
        ),
        SizedBox(height: isDesktop ? 16 : 8),
        Text(
          "Where should we deliver your order?",
          style: isDesktop
              ? STextStyles.desktopTextSmall(context)
              : STextStyles.itemSubtitle(context),
        ),
        SizedBox(height: isDesktop ? 32 : 24),
        AdaptiveTextField(
          controller: _nameFirstController,
          focusNode: _nameFirstFocusNode,
          labelText: "First name",
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) => setState(() {}),
        ),
        spacing,
        AdaptiveTextField(
          controller: _nameLastController,
          focusNode: _nameLastFocusNode,
          labelText: "Last name",
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) => setState(() {}),
        ),
        spacing,
        AdaptiveTextField(
          controller: _streetController,
          focusNode: _streetFocusNode,
          labelText: "Street address",
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) => setState(() {}),
        ),
        spacing,
        Row(
          children: [
            Expanded(
              child: AdaptiveTextField(
                controller: _cityController,
                focusNode: _cityFocusNode,
                labelText: "City",
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (_) => setState(() {}),
              ),
            ),
            SizedBox(width: isDesktop ? 16 : 12),
            Expanded(
              child: AdaptiveTextField(
                controller: _postalCodeController,
                focusNode: _postalCodeFocusNode,
                labelText: "Postal code",
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        if (_requiresState) spacing,
        if (_requiresState) DetailItem(title: "State", detail: _selectedState!),
        spacing,
        DetailItem(title: "Country", detail: _deliveryCountryLabel),
        spacing,
        // Billing address toggle.
        GestureDetector(
          onTap: () {
            setState(() {
              _differentBilling = !_differentBilling;
              if (!_differentBilling) {
                // Clear billing fields.
                _billingFirstNameController.clear();
                _billingLastNameController.clear();
                _billingStreetController.clear();
                _billingCityController.clear();
                _billingPostalCodeController.clear();
                _billingSelectedCountryIso = null;
                _selectedBillingState = null;
              }
            });
          },
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _differentBilling,
                  onChanged: (v) {
                    setState(() {
                      _differentBilling = v ?? false;
                      if (!_differentBilling) {
                        _billingFirstNameController.clear();
                        _billingLastNameController.clear();
                        _billingStreetController.clear();
                        _billingCityController.clear();
                        _billingPostalCodeController.clear();
                        _billingSelectedCountryIso = null;
                        _selectedBillingState = null;
                      }
                    });
                  },
                  activeColor: Theme.of(
                    context,
                  ).extension<StackColors>()!.accentColorBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Different billing address?",
                  style: isDesktop
                      ? STextStyles.desktopTextSmall(context)
                      : STextStyles.itemSubtitle(context),
                ),
              ),
            ],
          ),
        ),
        // Billing fields (expanded).
        if (_differentBilling) ...[
          SizedBox(height: isDesktop ? 24 : 16),
          Text(
            "Billing address",
            style: isDesktop
                ? STextStyles.desktopTextMedium(context)
                : STextStyles.titleBold12(context),
          ),
          spacing,
          AdaptiveTextField(
            controller: _billingFirstNameController,
            labelText: "First name",
            focusNode: _billingFirstNameFocusNode,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) => setState(() {}),
          ),
          spacing,
          AdaptiveTextField(
            controller: _billingLastNameController,
            labelText: "Last name",
            focusNode: _billingLastNameFocusNode,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) => setState(() {}),
          ),
          spacing,
          AdaptiveTextField(
            controller: _billingStreetController,
            focusNode: _billingStreetFocusNode,
            labelText: "Street address",
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) => setState(() {}),
          ),
          spacing,
          Row(
            children: [
              Expanded(
                child: AdaptiveTextField(
                  controller: _billingCityController,
                  focusNode: _billingCityFocusNode,
                  labelText: "City",
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(width: isDesktop ? 16 : 12),
              Expanded(
                child: AdaptiveTextField(
                  controller: _billingPostalCodeController,
                  focusNode: _billingPostalCodeFocusNode,
                  labelText: "Postal code",
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          spacing,

          if (_requiresState) ...[
            DetailItem(title: "Billing state", detail: _selectedState!),
            spacing,
            DetailItem(title: "Billing country", detail: _deliveryCountryLabel),
          ],

          if (!_requiresState) ...[
            ShopInBitStatePicker(
              countryIso: _billingSelectedCountryIso!,
              selectedState: _selectedBillingState,
              onChanged: (state) {
                if (state != _selectedBillingState && mounted) {
                  setState(() {
                    _selectedBillingState = state;
                  });
                }
              },
            ),
            spacing,
            ShopInBitCountryPicker(
              hintText: "Billing country",
              selectedIso: _billingSelectedCountryIso,
              onChanged: (data) => setState(() {
                _billingSelectedCountryIso = data?.code;
                _requiresState = data?.requiresState ?? false;
              }),
            ),
          ],
        ],
        const SizedBox(height: 24),
        PrimaryButton(
          label: _submitting ? "Submitting..." : "Continue to payment",
          enabled: _canContinue,
          onPressed: _canContinue ? _continue : null,
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
                  child: SingleChildScrollView(child: content),
                ),
              ),
            ],
          ),
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
    );
  }
}
