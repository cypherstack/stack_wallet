import 'dart:async';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../notifications/show_flush_bar.dart';
import '../../services/shopinbit/shopinbit_service.dart';
import '../../services/shopinbit/src/models/address.dart';
import '../../services/shopinbit/src/models/car_research.dart';
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
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_text_field.dart';
import 'shopinbit_car_research_payment_view.dart';

class ShopInBitCarFeeView extends StatefulWidget {
  const ShopInBitCarFeeView({super.key, required this.model});

  static const String routeName = "/shopInBitCarFee";

  final ShopInBitOrderModel model;

  @override
  State<ShopInBitCarFeeView> createState() => _ShopInBitCarFeeViewState();
}

class _ShopInBitCarFeeViewState extends State<ShopInBitCarFeeView> {
  late final TextEditingController _nameController;
  late final TextEditingController _streetController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalCodeController;
  late final FocusNode _nameFocusNode;
  late final FocusNode _streetFocusNode;
  late final FocusNode _cityFocusNode;
  late final FocusNode _postalCodeFocusNode;

  List<Map<String, dynamic>> _countries = [];
  String? _selectedBillingCountryIso;
  bool _loadingBillingCountries = false;
  final TextEditingController _billingCountrySearchController =
      TextEditingController();

  String _displayedFee = "50.00 EUR";
  bool _submitting = false;

  bool get _canContinue =>
      _nameController.text.trim().isNotEmpty &&
      _streetController.text.trim().isNotEmpty &&
      _cityController.text.trim().isNotEmpty &&
      _postalCodeController.text.trim().isNotEmpty &&
      _selectedBillingCountryIso != null;

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
    _nameFocusNode.dispose();
    _streetFocusNode.dispose();
    _cityFocusNode.dispose();
    _postalCodeFocusNode.dispose();
    _billingCountrySearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCountries() async {
    setState(() => _loadingBillingCountries = true);
    try {
      final resp =
          await ShopInBitService.instance.client.getCountries();
      if (resp.hasError || resp.value == null) return;
      _countries = resp.value!;
      if (_selectedBillingCountryIso != null &&
          !_countries.any(
            (c) => c['iso'] == _selectedBillingCountryIso,
          )) {
        _selectedBillingCountryIso = null;
      }
    } catch (_) {
      // leave list empty; user will see no items
    } finally {
      if (mounted) setState(() => _loadingBillingCountries = false);
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
      await ShopInBitService.instance.ensureCustomerKey();

      final name = _splitFullName(_nameController.text);
      final billing = Address(
        firstName: name.first,
        lastName: name.last,
        street: _streetController.text.trim(),
        zip: _postalCodeController.text.trim(),
        city: _cityController.text.trim(),
        country: _selectedBillingCountryIso!,
      );

      final resp = await ShopInBitService.instance.client
          .createCarResearchInvoice(billing: billing);

      if (resp.hasError || resp.value == null) {
        if (mounted) {
          setState(() => _submitting = false);
          unawaited(
            showFloatingFlushBar(
              type: FlushBarType.warning,
              message:
                  resp.exception?.message ?? "Failed to create invoice",
              context: context,
            ),
          );
        }
        return;
      }

      final invoice = resp.value!;

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

  Future<void> _loadFee(CarResearchInvoice invoice) async {
    try {
      final resp = await ShopInBitService.instance.client
          .getCarResearchInvoiceStatus(invoice.btcpayInvoice);
      if (resp.hasError || resp.value == null) {
        if (mounted) setState(() => _displayedFee = "—");
        return;
      }
      final data = resp.value!;
      final parsed = (data["fee"] ??
              data["amount"] ??
              data["total"] ??
              data["customer_price"])
          ?.toString();
      if (mounted) {
        setState(() => _displayedFee = parsed ?? "—");
      }
    } catch (_) {
      if (mounted) setState(() => _displayedFee = "—");
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
          "Billing address",
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
        ClipRRect(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              value: _selectedBillingCountryIso,
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
              onChanged: _loadingBillingCountries
                  ? null
                  : (value) {
                      setState(() {
                        _selectedBillingCountryIso = value;
                      });
                    },
              hint: Text(
                _loadingBillingCountries
                    ? "Loading countries..."
                    : "Billing country",
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
        const Spacer(),
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
