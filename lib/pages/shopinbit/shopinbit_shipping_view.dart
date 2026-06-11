import 'dart:async';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../providers/db/drift_provider.dart';
import '../../providers/global/shopin_bit_service_provider.dart';
import '../../services/shopinbit/src/models/address.dart';
import '../../services/shopinbit/src/models/payment.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/constants.dart';
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

class ShopInBitShippingView extends ConsumerStatefulWidget {
  const ShopInBitShippingView({
    super.key,
    required this.apiTicketId,
    required this.deliveryCountry,
    required this.countries,
  });

  static const String routeName = "/shopInBitShipping";

  final int apiTicketId;
  final String deliveryCountry;
  final List<Map<String, dynamic>> countries;

  @override
  ConsumerState<ShopInBitShippingView> createState() =>
      _ShopInBitShippingViewState();
}

class _ShopInBitShippingViewState extends ConsumerState<ShopInBitShippingView> {
  late final TextEditingController _nameController;
  late final TextEditingController _streetController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalCodeController;
  final TextEditingController _countrySearchController =
      TextEditingController();
  late final FocusNode _nameFocusNode;
  late final FocusNode _streetFocusNode;
  late final FocusNode _cityFocusNode;
  late final FocusNode _postalCodeFocusNode;

  // Billing address controllers
  late final TextEditingController _billingNameController;
  late final TextEditingController _billingStreetController;
  late final TextEditingController _billingCityController;
  late final TextEditingController _billingPostalCodeController;
  final TextEditingController _billingCountrySearchController =
      TextEditingController();
  late final FocusNode _billingNameFocusNode;
  late final FocusNode _billingStreetFocusNode;
  late final FocusNode _billingCityFocusNode;
  late final FocusNode _billingPostalCodeFocusNode;

  String? _billingSelectedCountryIso;
  bool _differentBilling = false;

  late final String _selectedCountryIso;
  late final String _deliveryCountryLabel;

  bool _submitting = false;

  bool get _canContinue {
    if (_submitting) return false;
    final shippingValid =
        _nameController.text.trim().isNotEmpty &&
        _streetController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty &&
        _postalCodeController.text.trim().isNotEmpty;
    if (!shippingValid) return false;
    if (_differentBilling) {
      return _billingNameController.text.trim().isNotEmpty &&
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
    _nameController = TextEditingController();
    _streetController = TextEditingController();
    _cityController = TextEditingController();
    _postalCodeController = TextEditingController();
    _nameFocusNode = FocusNode();
    _streetFocusNode = FocusNode();
    _cityFocusNode = FocusNode();
    _postalCodeFocusNode = FocusNode();

    _billingNameController = TextEditingController();
    _billingStreetController = TextEditingController();
    _billingCityController = TextEditingController();
    _billingPostalCodeController = TextEditingController();
    _billingNameFocusNode = FocusNode();
    _billingStreetFocusNode = FocusNode();
    _billingCityFocusNode = FocusNode();
    _billingPostalCodeFocusNode = FocusNode();

    _selectedCountryIso = widget.deliveryCountry;

    // firstWhere should never fail here as the caller of this widget must
    // check that countries contains the expected value. Failure here should be
    // considered unrecoverable/fatal as it indicates a bug elsewhere
    _deliveryCountryLabel =
        widget.countries.firstWhere(
              (e) => e["iso"] == _selectedCountryIso,
            )["label"]
            as String;

    for (final node in [
      _nameFocusNode,
      _streetFocusNode,
      _cityFocusNode,
      _postalCodeFocusNode,
      _billingNameFocusNode,
      _billingStreetFocusNode,
      _billingCityFocusNode,
      _billingPostalCodeFocusNode,
    ]) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countrySearchController.dispose();
    _nameFocusNode.dispose();
    _streetFocusNode.dispose();
    _cityFocusNode.dispose();
    _postalCodeFocusNode.dispose();
    _billingNameController.dispose();
    _billingStreetController.dispose();
    _billingCityController.dispose();
    _billingPostalCodeController.dispose();
    _billingCountrySearchController.dispose();
    _billingNameFocusNode.dispose();
    _billingStreetFocusNode.dispose();
    _billingCityFocusNode.dispose();
    _billingPostalCodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _nameController.text.trim();
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final postalCode = _postalCodeController.text.trim();
    final country = _selectedCountryIso;

    PaymentInfo? paymentInfo;
    setState(() => _submitting = true);
    try {
      // Split name into first/last
      final parts = name.split(' ');
      final firstName = parts.first;
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      Address? billingAddress;
      if (_differentBilling) {
        final billingName = _billingNameController.text.trim();
        final billingParts = billingName.split(' ');
        final billingFirst = billingParts.first;
        final billingLast = billingParts.length > 1
            ? billingParts.sublist(1).join(' ')
            : '';
        billingAddress = Address(
          firstName: billingFirst,
          lastName: billingLast,
          street: _billingStreetController.text.trim(),
          zip: _billingPostalCodeController.text.trim(),
          city: _billingCityController.text.trim(),
          country: _billingSelectedCountryIso!,
        );
      }

      final thisTicket = await ref
          .read(pSharedDrift)
          .shopInBitTicketsDao
          .getByApiId(widget.apiTicketId);

      final resp = await ref
          .read(pShopinBitService)
          .client
          .submitAddress(
            widget.apiTicketId,
            shipping: Address(
              firstName: firstName,
              lastName: lastName,
              street: street,
              zip: postalCode,
              city: city,
              country: country,
            ),
            billing: billingAddress,
            customerKey: thisTicket!.customerKey,
          );

      if (resp.hasError) {
        // Sandbox may fail here; continue anyway.
        Logging.instance.w("submitAddress failed", error: resp.exception);
      }

      paymentInfo = await fetchShopInBitPaymentInfo(
        ref.read(pShopinBitService).client,
        widget.apiTicketId,
        thisTicket.customerKey,
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
      arguments: (apiTicketId: widget.apiTicketId, paymentInfo: paymentInfo),
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
          controller: _nameController,
          focusNode: _nameFocusNode,
          labelText: "Full name",
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
        spacing,
        DetailItem(
          title: "Country",
          detail: _deliveryCountryLabel,
          disableSelectableText: true,
        ),
        spacing,
        // Billing address toggle.
        GestureDetector(
          onTap: () {
            setState(() {
              _differentBilling = !_differentBilling;
              if (!_differentBilling) {
                // Clear billing fields.
                _billingNameController.clear();
                _billingStreetController.clear();
                _billingCityController.clear();
                _billingPostalCodeController.clear();
                _billingSelectedCountryIso = null;
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
                        _billingNameController.clear();
                        _billingStreetController.clear();
                        _billingCityController.clear();
                        _billingPostalCodeController.clear();
                        _billingSelectedCountryIso = null;
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
            controller: _billingNameController,
            focusNode: _billingNameFocusNode,
            labelText: "Full name",
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
          // Billing country dropdown.
          ClipRRect(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton2<String>(
                value: _billingSelectedCountryIso,
                items: widget.countries
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: c['iso'] as String,
                        child: Text(
                          c['label'] as String,
                          style: isDesktop
                              ? STextStyles.desktopTextExtraSmall(
                                  context,
                                ).copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textFieldActiveText,
                                )
                              : STextStyles.w500_14(context),
                        ),
                      ),
                    )
                    .toList(),
                onMenuStateChange: (isOpen) {
                  if (!isOpen) {
                    _billingCountrySearchController.clear();
                  }
                },
                onChanged: (value) {
                  setState(() {
                    _billingSelectedCountryIso = value;
                  });
                },
                hint: Text(
                  "Country",
                  style: isDesktop
                      ? STextStyles.desktopTextExtraSmall(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textFieldDefaultSearchIconLeft,
                        )
                      : STextStyles.fieldLabel(context),
                ),
                isExpanded: true,
                buttonStyleData: ButtonStyleData(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.textFieldDefaultBG,
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                  ),
                ),
                iconStyleData: IconStyleData(
                  icon: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SvgPicture.asset(
                      Assets.svg.chevronDown,
                      width: 12,
                      height: 6,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textFieldActiveSearchIconRight,
                    ),
                  ),
                ),
                dropdownStyleData: DropdownStyleData(
                  offset: const Offset(0, 0),
                  elevation: 0,
                  maxHeight: 300,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.textFieldDefaultBG,
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                  ),
                ),
                dropdownSearchData: DropdownSearchData<String>(
                  searchController: _billingCountrySearchController,
                  searchInnerWidgetHeight: 48,
                  searchInnerWidget: TextFormField(
                    controller: _billingCountrySearchController,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      hintText: "Search...",
                      hintStyle: STextStyles.fieldLabel(context),
                      border: InputBorder.none,
                    ),
                  ),
                  searchMatchFn: (item, searchValue) {
                    final label = widget.countries
                        .where((c) => c['iso'] == item.value)
                        .map((c) => c['label'] as String)
                        .firstOrNull;
                    return label?.toLowerCase().contains(
                          searchValue.toLowerCase(),
                        ) ??
                        false;
                  },
                ),
                menuItemStyleData: const MenuItemStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ),
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
