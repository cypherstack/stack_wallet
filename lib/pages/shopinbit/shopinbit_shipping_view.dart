import 'dart:async';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../notifications/show_flush_bar.dart';
import '../../services/shopinbit/shopinbit_service.dart';
import '../../services/shopinbit/src/models/address.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/constants.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/stack_text_field.dart';
import 'shopinbit_payment_view.dart';

class ShopInBitShippingView extends StatefulWidget {
  const ShopInBitShippingView({super.key, required this.model});

  static const String routeName = "/shopInBitShipping";

  final ShopInBitOrderModel model;

  @override
  State<ShopInBitShippingView> createState() => _ShopInBitShippingViewState();
}

class _ShopInBitShippingViewState extends State<ShopInBitShippingView> {
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

  List<Map<String, dynamic>> _countries = [];
  String? _selectedCountryIso;
  bool _loadingCountries = false;

  bool _submitting = false;

  bool get _canContinue {
    if (_submitting) return false;
    final shippingValid =
        _nameController.text.trim().isNotEmpty &&
        _streetController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty &&
        _postalCodeController.text.trim().isNotEmpty &&
        _selectedCountryIso != null;
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

    _selectedCountryIso = widget.model.deliveryCountry.isNotEmpty
        ? widget.model.deliveryCountry
        : null;

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

  Future<void> _fetchCountries() async {
    setState(() => _loadingCountries = true);
    try {
      final resp = await ShopInBitService.instance.client.getCountries();
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

  Future<void> _continue() async {
    final name = _nameController.text.trim();
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final postalCode = _postalCodeController.text.trim();
    final country = _selectedCountryIso!;

    widget.model.setShippingAddress(
      name: name,
      street: street,
      city: city,
      postalCode: postalCode,
      country: country,
    );

    if (widget.model.apiTicketId != 0) {
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

        final resp = await ShopInBitService.instance.client.submitAddress(
          widget.model.apiTicketId,
          shipping: Address(
            firstName: firstName,
            lastName: lastName,
            street: street,
            zip: postalCode,
            city: city,
            country: country,
          ),
          billing: billingAddress,
        );

        if (resp.hasError) {
          // Sandbox may fail here; continue anyway.
          debugPrint("submitAddress failed: ${resp.exception?.message}");
        }
      } catch (e) {
        debugPrint("submitAddress threw: $e");
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    }

    if (!mounted) return;
    if (Util.isDesktop) {
      Navigator.of(context, rootNavigator: true).pop();
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => ShopInBitPaymentView(model: widget.model),
        ),
      );
    } else {
      unawaited(
        Navigator.of(
          context,
        ).pushNamed(ShopInBitPaymentView.routeName, arguments: widget.model),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final spacing = SizedBox(height: isDesktop ? 16 : 12);

    final content = Column(
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
        ClipRRect(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              value: _selectedCountryIso,
              items: _countries
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c['iso'] as String,
                      child: Text(
                        c['label'] as String,
                        style: isDesktop
                            ? STextStyles.desktopTextExtraSmall(
                                context,
                              ).copyWith(
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
                  _countrySearchController.clear();
                }
              },
              onChanged: null,
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
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.textFieldActiveSearchIconRight,
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
                searchController: _countrySearchController,
                searchInnerWidgetHeight: 48,
                searchInnerWidget: TextFormField(
                  controller: _countrySearchController,
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
          // Billing country dropdown.
          ClipRRect(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton2<String>(
                value: _billingSelectedCountryIso,
                items: _countries
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
                onChanged: _loadingCountries
                    ? null
                    : (value) {
                        setState(() {
                          _billingSelectedCountryIso = value;
                        });
                      },
                hint: Text(
                  _loadingCountries ? "Loading countries..." : "Country",
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
                    final label = _countries
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
      return DesktopDialog(
        maxWidth: 580,
        maxHeight: 700,
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
