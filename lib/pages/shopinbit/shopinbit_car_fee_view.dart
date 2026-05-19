import 'dart:async';
import 'dart:convert';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../db/isar/main_db.dart';
import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../notifications/show_flush_bar.dart';
import '../../providers/global/shopin_bit_service_provider.dart';
import '../../services/shopinbit/src/models/address.dart';
import '../../services/shopinbit/src/models/car_research.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/constants.dart';
import '../../utilities/logger.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_text_field.dart';
import '../more_view/services_view.dart';
import 'shopinbit_car_research_payment_view.dart';
import 'shopinbit_step_2.dart';

class ShopInBitCarFeeView extends ConsumerStatefulWidget {
  const ShopInBitCarFeeView({super.key, required this.model});

  static const String routeName = "/shopInBitCarFee";

  final ShopInBitOrderModel model;

  @override
  ConsumerState<ShopInBitCarFeeView> createState() =>
      _ShopInBitCarFeeViewState();
}

class _ShopInBitCarFeeViewState extends ConsumerState<ShopInBitCarFeeView> {
  late final TextEditingController _nameController;
  late final TextEditingController _streetController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalCodeController;
  late final FocusNode _nameFocusNode;
  late final FocusNode _streetFocusNode;
  late final FocusNode _cityFocusNode;
  late final FocusNode _postalCodeFocusNode;

  List<Map<String, dynamic>> _countries = [];
  String? _selectedCountryIso;
  bool _loadingCountries = false;
  final TextEditingController _countrySearchController =
      TextEditingController();

  // Billing address (optional, separate from delivery)
  bool _differentBilling = false;
  late final TextEditingController _billingNameController;
  late final TextEditingController _billingStreetController;
  late final TextEditingController _billingCityController;
  late final TextEditingController _billingPostalCodeController;
  late final FocusNode _billingNameFocusNode;
  late final FocusNode _billingStreetFocusNode;
  late final FocusNode _billingCityFocusNode;
  late final FocusNode _billingPostalCodeFocusNode;
  String? _selectedBillingCountryIso;
  final TextEditingController _billingCountrySearchController =
      TextEditingController();

  String _displayedFee = "223.00 EUR";
  bool _submitting = false;

  bool get _canContinue {
    if (_nameController.text.trim().isEmpty ||
        _streetController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _postalCodeController.text.trim().isEmpty ||
        _selectedCountryIso == null) {
      return false;
    }
    if (_differentBilling) {
      if (_billingNameController.text.trim().isEmpty ||
          _billingStreetController.text.trim().isEmpty ||
          _billingCityController.text.trim().isEmpty ||
          _billingPostalCodeController.text.trim().isEmpty ||
          _selectedBillingCountryIso == null) {
        return false;
      }
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.model.shippingName);
    _streetController = TextEditingController(
      text: widget.model.shippingStreet,
    );
    _cityController = TextEditingController(text: widget.model.shippingCity);
    _postalCodeController = TextEditingController(
      text: widget.model.shippingPostalCode,
    );
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

    _fetchCountries();

    // Pre-select country on resume if model already has a shipping country.
    if (widget.model.shippingCountry.isNotEmpty) {
      _selectedCountryIso = widget.model.shippingCountry;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _nameFocusNode.dispose();
    _streetFocusNode.dispose();
    _cityFocusNode.dispose();
    _postalCodeFocusNode.dispose();
    _billingNameController.dispose();
    _billingStreetController.dispose();
    _billingCityController.dispose();
    _billingPostalCodeController.dispose();
    _billingNameFocusNode.dispose();
    _billingStreetFocusNode.dispose();
    _billingCityFocusNode.dispose();
    _billingPostalCodeFocusNode.dispose();
    _billingCountrySearchController.dispose();
    _countrySearchController.dispose();
    super.dispose();
  }

  void _popToStep2() {
    Navigator.of(context).popUntil((route) {
      final name = route.settings.name;
      if (name == ShopInBitStep2.routeName) {
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

  Future<void> _fetchCountries() async {
    setState(() => _loadingCountries = true);
    try {
      final resp = await ref.read(pShopinBitService).client.getCountries();
      if (resp.hasError || resp.value == null) return;
      _countries = resp.value!;
      if (_selectedCountryIso != null &&
          !_countries.any((c) => c['iso'] == _selectedCountryIso)) {
        _selectedCountryIso = null;
      }
    } catch (_) {
      // leave list empty; user will see no items
    } finally {
      if (mounted) setState(() => _loadingCountries = false);
    }
  }

  ({String first, String last}) _splitFullName(String raw) {
    final trimmed = raw.trim();
    final idx = trimmed.lastIndexOf(' ');
    if (idx >= 0) {
      return (
        first: trimmed.substring(0, idx).trim(),
        last: trimmed.substring(idx + 1).trim(),
      );
    }
    return (first: trimmed, last: "");
  }

  Future<void> _createInvoice() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await ref.read(pShopinBitService).ensureCustomerKey();

      // Delivery address (always provided)
      final deliveryName = _splitFullName(_nameController.text);
      widget.model.setShippingAddress(
        name: _nameController.text.trim(),
        street: _streetController.text.trim(),
        city: _cityController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        country: _selectedCountryIso!,
      );

      // Billing address: use separate billing fields if different,
      // else use delivery
      final Address billing;
      if (_differentBilling) {
        final billingName = _splitFullName(_billingNameController.text);
        billing = Address(
          firstName: billingName.first,
          lastName: billingName.last,
          street: _billingStreetController.text.trim(),
          zip: _billingPostalCodeController.text.trim(),
          city: _billingCityController.text.trim(),
          country: _selectedBillingCountryIso!,
        );
      } else {
        billing = Address(
          firstName: deliveryName.first,
          lastName: deliveryName.last,
          street: _streetController.text.trim(),
          zip: _postalCodeController.text.trim(),
          city: _cityController.text.trim(),
          country: _selectedCountryIso!,
        );
      }

      final resp = await ref
          .read(pShopinBitService)
          .client
          .createCarResearchInvoice(billing: billing);

      if (resp.hasError || resp.value == null) {
        if (mounted) {
          setState(() => _submitting = false);
          unawaited(
            showFloatingFlushBar(
              type: FlushBarType.warning,
              message: resp.exception?.message ?? "Failed to create invoice",
              context: context,
            ),
          );
        }
        return;
      }

      final invoice = resp.value!;

      // Persist pending state so the user can resume if they close the dialog.
      // Sentinel ticketId; unique-replace index ensures at most one pending
      // record.
      widget.model.ticketId = "pending-car-research";
      widget.model.carResearchInvoiceId = invoice.btcpayInvoice;
      widget.model.isPendingPayment = true;
      widget.model.carResearchExpiresAt = invoice.expiresAt;
      widget.model.carResearchPaymentLinks = jsonEncode(invoice.paymentLinks);
      await MainDB.instance.putShopInBitTicket(widget.model.toIsarTicket());

      // Best-effort fee fetch; do not block navigation on fee parse failure.
      await _loadFee(invoice);

      if (!mounted) return;

      if (Util.isDesktop) {
        Navigator.of(context, rootNavigator: true).pop();
        unawaited(
          showDialog<void>(
            context: context,
            builder: (_) => ShopInBitCarResearchPaymentView(
              model: widget.model,
              invoice: invoice,
            ),
          ),
        );
      } else {
        unawaited(
          Navigator.of(context).pushNamed(
            ShopInBitCarResearchPaymentView.routeName,
            arguments: (widget.model, invoice),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
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

  Future<void> _loadFee(CarResearchInvoice invoice) async {
    // Keep status call for visibility into any future API changes surfacing
    // a fee field. Today the endpoint returns only {status, additional}, so
    // we source the displayed amount from the BIP21 payment URIs instead.
    try {
      final resp = await ref
          .read(pShopinBitService)
          .client
          .getCarResearchInvoiceStatus(invoice.btcpayInvoice);
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

  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required bool isDesktop,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Constants.size.circularBorderRadius),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: (_) => setState(() {}),
        style: isDesktop
            ? STextStyles.desktopTextExtraSmall(context).copyWith(
                color: Theme.of(
                  context,
                ).extension<StackColors>()!.textFieldActiveText,
                height: 1.8,
              )
            : STextStyles.field(context),
        decoration:
            standardInputDecoration(
              label,
              focusNode,
              context,
              desktopMed: isDesktop,
            ).copyWith(
              filled: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
      ),
    );
  }

  Widget _buildCountryDropdown({
    required String? value,
    required ValueChanged<String?> onChanged,
    required String hint,
    required TextEditingController searchController,
    required bool isDesktop,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Constants.size.circularBorderRadius),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          value: value,
          items: _countries
              .map(
                (c) => DropdownMenuItem<String>(
                  value: c['iso'] as String,
                  child: Text(
                    c['label'] as String,
                    style: isDesktop
                        ? STextStyles.desktopTextExtraSmall(context).copyWith(
                            color: Theme.of(
                              context,
                            ).extension<StackColors>()!.textFieldActiveText,
                          )
                        : STextStyles.w500_14(context),
                  ),
                ),
              )
              .toList(),
          onMenuStateChange: (isOpen) {
            if (!isOpen) {
              searchController.clear();
            }
          },
          onChanged: _loadingCountries ? null : onChanged,
          hint: Text(
            _loadingCountries ? "Loading countries..." : hint,
            style: isDesktop
                ? STextStyles.desktopTextExtraSmall(context).copyWith(
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.textFieldDefaultSearchIconLeft,
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
                colorFilter: ColorFilter.mode(
                  Theme.of(
                    context,
                  ).extension<StackColors>()!.textFieldActiveSearchIconRight,
                  .srcIn,
                ),
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
            searchController: searchController,
            searchInnerWidgetHeight: 48,
            searchInnerWidget: TextFormField(
              controller: searchController,
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
              final label = _countries
                  .where((c) => c['iso'] == item.value)
                  .map((c) => c['label'] as String)
                  .firstOrNull;
              return label?.toLowerCase().contains(searchValue.toLowerCase()) ??
                  false;
            },
          ),
          menuItemStyleData: const MenuItemStyleData(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final spacing = SizedBox(height: isDesktop ? 16 : 12);

    final content = Column(
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
          "Delivery address",
          style: isDesktop
              ? STextStyles.desktopTextSmall(context)
              : STextStyles.titleBold12(context),
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        _buildField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          label: "Full name",
          isDesktop: isDesktop,
        ),
        spacing,
        _buildField(
          controller: _streetController,
          focusNode: _streetFocusNode,
          label: "Street address",
          isDesktop: isDesktop,
        ),
        spacing,
        Row(
          children: [
            Expanded(
              child: _buildField(
                controller: _cityController,
                focusNode: _cityFocusNode,
                label: "City",
                isDesktop: isDesktop,
              ),
            ),
            SizedBox(width: isDesktop ? 16 : 12),
            Expanded(
              child: _buildField(
                controller: _postalCodeController,
                focusNode: _postalCodeFocusNode,
                label: "Postal code",
                isDesktop: isDesktop,
              ),
            ),
          ],
        ),
        spacing,
        _buildCountryDropdown(
          value: _selectedCountryIso,
          onChanged: (v) => setState(() => _selectedCountryIso = v),
          hint: "Country",
          searchController: _countrySearchController,
          isDesktop: isDesktop,
        ),
        spacing,
        GestureDetector(
          onTap: () {
            setState(() {
              _differentBilling = !_differentBilling;
              if (!_differentBilling) {
                _billingNameController.clear();
                _billingStreetController.clear();
                _billingCityController.clear();
                _billingPostalCodeController.clear();
                _selectedBillingCountryIso = null;
              }
            });
          },
          child: Container(
            color: Colors.transparent,
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: IgnorePointer(
                    child: Checkbox(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: _differentBilling,
                      onChanged: (_) {},
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Different billing address?",
                  style: isDesktop
                      ? STextStyles.desktopTextSmall(context)
                      : STextStyles.w500_14(context),
                ),
              ],
            ),
          ),
        ),
        if (_differentBilling) ...[
          spacing,
          Text(
            "Billing address",
            style: isDesktop
                ? STextStyles.desktopTextSmall(context)
                : STextStyles.titleBold12(context),
          ),
          SizedBox(height: isDesktop ? 16 : 12),
          _buildField(
            controller: _billingNameController,
            focusNode: _billingNameFocusNode,
            label: "Full name",
            isDesktop: isDesktop,
          ),
          spacing,
          _buildField(
            controller: _billingStreetController,
            focusNode: _billingStreetFocusNode,
            label: "Street address",
            isDesktop: isDesktop,
          ),
          spacing,
          Row(
            children: [
              Expanded(
                child: _buildField(
                  controller: _billingCityController,
                  focusNode: _billingCityFocusNode,
                  label: "City",
                  isDesktop: isDesktop,
                ),
              ),
              SizedBox(width: isDesktop ? 16 : 12),
              Expanded(
                child: _buildField(
                  controller: _billingPostalCodeController,
                  focusNode: _billingPostalCodeFocusNode,
                  label: "Postal code",
                  isDesktop: isDesktop,
                ),
              ),
            ],
          ),
          spacing,
          _buildCountryDropdown(
            value: _selectedBillingCountryIso,
            onChanged: (v) => setState(() => _selectedBillingCountryIso = v),
            hint: "Billing country",
            searchController: _billingCountrySearchController,
            isDesktop: isDesktop,
          ),
        ],
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
