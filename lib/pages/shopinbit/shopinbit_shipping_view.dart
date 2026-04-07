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

  List<Map<String, dynamic>> _countries = [];
  String? _selectedCountryIso;
  bool _loadingCountries = false;

  bool _submitting = false;

  bool get _canContinue =>
      !_submitting &&
      _nameController.text.trim().isNotEmpty &&
      _streetController.text.trim().isNotEmpty &&
      _cityController.text.trim().isNotEmpty &&
      _postalCodeController.text.trim().isNotEmpty &&
      _selectedCountryIso != null;

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

    for (final node in [
      _nameFocusNode,
      _streetFocusNode,
      _cityFocusNode,
      _postalCodeFocusNode,
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
        );

        if (resp.hasError) {
          // Address submission may fail in sandbox (pricing not calculated).
          // Log but proceed to payment.
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
              onChanged: _loadingCountries
                  ? null
                  : (value) {
                      setState(() {
                        _selectedCountryIso = value;
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
        const Spacer(),
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
        maxHeight: 600,
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
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
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
