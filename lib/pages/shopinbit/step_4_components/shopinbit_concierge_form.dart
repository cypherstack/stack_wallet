import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../models/shopinbit/shopinbit_request_draft.dart";
import "../../../providers/global/shopin_bit_service_provider.dart";
import "../../../utilities/util.dart";
import "../../../widgets/conditional_parent.dart";
import "../../../widgets/textfields/adaptive_text_field.dart";
import "shopinbit_country_picker.dart";
import "shopinbit_labeled_checkbox.dart";
import "shopinbit_privacy_checkbox.dart";
import "shopinbit_state_picker.dart";
import "shopinbit_step4_dropdown.dart";
import "shopinbit_step4_header.dart";
import "shopinbit_step4_submit.dart";
import "shopinbit_step4_submit_button.dart";

const List<String> _conciergeConditions = ["NEW", "USED"];

const int _minConciergeBudget = 1000;
const int _maxConciergeBudget = 100000;

class ShopInBitConciergeForm extends ConsumerStatefulWidget {
  const ShopInBitConciergeForm({super.key});

  @override
  ConsumerState<ShopInBitConciergeForm> createState() =>
      _ShopInBitConciergeFormState();
}

class _ShopInBitConciergeFormState
    extends ConsumerState<ShopInBitConciergeForm> {
  final TextEditingController _whatToPurchaseController =
      TextEditingController();
  final FocusNode _whatToPurchaseFocusNode = FocusNode();
  bool _whatToPurchaseTouched = false;

  final TextEditingController _budgetController = TextEditingController(
    text: "1000",
  );
  final FocusNode _budgetFocusNode = FocusNode();
  bool _budgetTouched = false;

  String? _selectedCondition;
  bool _noLimit = false;
  String? _selectedCountryIsoCode;
  String? _selectedCountryName;
  String? _selectedState;
  bool? _requiresState;
  bool _privacyAccepted = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _whatToPurchaseFocusNode.addListener(() {
      if (!_whatToPurchaseFocusNode.hasFocus) _whatToPurchaseTouched = true;
      setState(() {});
    });
    _budgetFocusNode.addListener(() {
      if (!_budgetFocusNode.hasFocus) _budgetTouched = true;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _whatToPurchaseController.dispose();
    _whatToPurchaseFocusNode.dispose();
    _budgetController.dispose();
    _budgetFocusNode.dispose();
    super.dispose();
  }

  bool get _budgetIsValid {
    final String text = _budgetController.text.trim();
    if (text.isEmpty) return false;
    final int? value = int.tryParse(text);
    return value != null &&
        value >= _minConciergeBudget &&
        value <= _maxConciergeBudget;
  }

  bool get _canContinue =>
      !_submitting &&
      _privacyAccepted &&
      _whatToPurchaseController.text.trim().length >= 10 &&
      _selectedCondition != null &&
      (_noLimit || _budgetIsValid) &&
      _selectedCountryIsoCode != null;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final String countryIso = _selectedCountryIsoCode!;
      final String budgetText = _noLimit
          ? "No limit"
          : "${_budgetController.text.trim()} EUR";

      final sb = StringBuffer();
      sb.writeln("What to purchase: ${_whatToPurchaseController.text.trim()}");
      sb.writeln("Condition: $_selectedCondition");
      sb.writeln("Budget: $budgetText");
      if (_requiresState == true) sb.writeln("State: ${_selectedState!}");
      sb.writeln("Delivery country: $countryIso");

      final draft = ShopinbitRequestDraft(
        category: .concierge,
        requestDescription: sb.toString(),
        deliveryCountryCode: countryIso,
        deliveryCountryName: _selectedCountryName!,
        deliveryState: _requiresState == true ? _selectedState! : null,
        voucherCode: null,
      );

      await submitShopInBitRequest(context, draft, ref.read(pShopinBitService));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Util.isDesktop;

    final String? whatToPurchaseError =
        _whatToPurchaseTouched &&
            _whatToPurchaseController.text.trim().length < 10
        ? "Minimum 10 characters"
        : null;

    final String? budgetError = _budgetTouched && !_noLimit && !_budgetIsValid
        ? "Enter a value between 1,000 and 100,000"
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ShopInBitStep4Header(
          title: "What would you like to purchase?",
          subtitle:
              "Tell us what you're looking for and we'll find it "
              "for you.",
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        AdaptiveTextField(
          controller: _whatToPurchaseController,
          focusNode: _whatToPurchaseFocusNode,
          labelText: "Describe what you need or paste a LINK here",
          minLines: 3,
          maxLines: 6,
          autocorrect: false,
          enableSuggestions: false,
          errorText: whatToPurchaseError,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: isDesktop ? 24 : 16),
        ShopInBitStep4Dropdown(
          value: _selectedCondition,
          items: _conciergeConditions,
          hintText: "Condition",
          onChanged: (value) => setState(() => _selectedCondition = value),
        ),
        SizedBox(height: isDesktop ? 24 : 16),
        AdaptiveTextField(
          controller: _budgetController,
          focusNode: _budgetFocusNode,
          labelText: "Budget (\u20AC)",
          enabled: !_noLimit,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          suffixText: "\u20AC",
          autocorrect: false,
          enableSuggestions: false,
          errorText: budgetError,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        ShopInBitLabeledCheckbox(
          value: _noLimit,
          onChanged: (v) => setState(() => _noLimit = v),
          label: "No budget limit",
        ),
        SizedBox(height: isDesktop ? 24 : 20),
        ConditionalParent(
          condition: _requiresState == true,
          builder: (child) => Column(
            mainAxisSize: .min,
            children: [
              child,
              SizedBox(height: isDesktop ? 24 : 16),
              ShopInBitStatePicker(
                countryIso: _selectedCountryIsoCode!,
                selectedState: _selectedState,
                onChanged: (state) {
                  if (state != _selectedState && mounted) {
                    setState(() {
                      _selectedState = state;
                    });
                  }
                },
              ),
            ],
          ),
          child: ShopInBitCountryPicker(
            selectedIso: _selectedCountryIsoCode,
            onChanged: (data) => setState(() {
              _selectedCountryIsoCode = data?.code;
              _selectedCountryName = data?.name;
              _requiresState = data?.requiresState;
            }),
          ),
        ),
        SizedBox(height: isDesktop ? 16 : 24),
        ShopInBitPrivacyCheckbox(
          value: _privacyAccepted,
          onChanged: (v) => setState(() => _privacyAccepted = v),
        ),
        const SizedBox(height: 32),
        ShopInBitStep4SubmitButton(
          submitting: _submitting,
          enabled: _canContinue,
          onPressed: _submit,
        ),
      ],
    );
  }
}
