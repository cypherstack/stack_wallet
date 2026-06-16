import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";

import "../../../models/shopinbit/shopinbit_order_model.dart";
import "../../../providers/db/drift_provider.dart";
import "../../../themes/stack_colors.dart";
import "../../../utilities/assets.dart";
import "../../../utilities/text_styles.dart";
import "../../../utilities/util.dart";
import "../../../widgets/desktop/primary_button.dart";
import "../../../widgets/desktop/secondary_button.dart";
import "../../../widgets/rounded_white_container.dart";
import "../../../widgets/stack_dialog.dart";
import "../../../widgets/textfields/adaptive_text_field.dart";
import "../shopinbit_car_fee_view.dart";
import "../shopinbit_tickets_view.dart";
import "shopinbit_country_picker.dart";
import "shopinbit_labeled_checkbox.dart";
import "shopinbit_privacy_checkbox.dart";
import "shopinbit_step4_dropdown.dart";
import "shopinbit_step4_header.dart";
import "shopinbit_step4_submit_button.dart";

const List<String> _carConditions = ["NEW", "PREOWNED"];

const int _minCarBudget = 20000;
const int _minCarFieldLength = 3;

class ShopInBitCarResearchForm extends ConsumerStatefulWidget {
  const ShopInBitCarResearchForm({super.key, required this.model});

  final ShopInBitOrderModel model;

  @override
  ConsumerState<ShopInBitCarResearchForm> createState() =>
      _ShopInBitCarResearchFormState();
}

class _ShopInBitCarResearchFormState
    extends ConsumerState<ShopInBitCarResearchForm> {
  final TextEditingController _brandController = TextEditingController();
  final FocusNode _brandFocusNode = FocusNode();
  bool _brandTouched = false;

  final TextEditingController _modelController = TextEditingController();
  final FocusNode _modelFocusNode = FocusNode();
  bool _modelTouched = false;

  final TextEditingController _carDescriptionController =
      TextEditingController();
  final FocusNode _carDescriptionFocusNode = FocusNode();
  bool _carDescriptionTouched = false;

  final TextEditingController _carBudgetController = TextEditingController();
  final FocusNode _carBudgetFocusNode = FocusNode();
  bool _carBudgetTouched = false;

  String? _selectedCarCondition;
  bool _feeAcknowledged = false;
  String? _selectedCountryIso;
  bool _privacyAccepted = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _wireTouchOnBlur(_brandFocusNode, () => _brandTouched = true);
    _wireTouchOnBlur(_modelFocusNode, () => _modelTouched = true);
    _wireTouchOnBlur(
      _carDescriptionFocusNode,
      () => _carDescriptionTouched = true,
    );
    _wireTouchOnBlur(_carBudgetFocusNode, () => _carBudgetTouched = true);
    if (widget.model.deliveryCountry.isNotEmpty) {
      _selectedCountryIso = widget.model.deliveryCountry;
    }
  }

  void _wireTouchOnBlur(FocusNode node, VoidCallback markTouched) {
    node.addListener(() {
      if (!node.hasFocus) markTouched();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _brandController.dispose();
    _brandFocusNode.dispose();
    _modelController.dispose();
    _modelFocusNode.dispose();
    _carDescriptionController.dispose();
    _carDescriptionFocusNode.dispose();
    _carBudgetController.dispose();
    _carBudgetFocusNode.dispose();
    super.dispose();
  }

  bool get _canContinue {
    final int? carBudgetValue = int.tryParse(_carBudgetController.text.trim());
    return !_submitting &&
        _privacyAccepted &&
        _feeAcknowledged &&
        _brandController.text.trim().length >= _minCarFieldLength &&
        _modelController.text.trim().length >= _minCarFieldLength &&
        _carDescriptionController.text.trim().length >= _minCarFieldLength &&
        _selectedCarCondition != null &&
        carBudgetValue != null &&
        carBudgetValue >= _minCarBudget &&
        _selectedCountryIso != null;
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final String countryIso = _selectedCountryIso!;

      widget.model
        ..requestDescription =
            "Brand: ${_brandController.text.trim()}\n"
            "Model: ${_modelController.text.trim()}\n"
            "Condition: $_selectedCarCondition\n"
            "Description: ${_carDescriptionController.text.trim()}\n"
            "Budget: ${_carBudgetController.text.trim()} EUR\n"
            "Delivery country: $countryIso"
        ..deliveryCountry = countryIso;

      // Block if another car research flow is already in progress.
      final db = ref.read(pSharedDrift);
      final existingPending = await (db.select(
        db.shopInBitTickets,
      )..where((t) => t.isPendingPayment.equals(true))).get();

      if (existingPending.isNotEmpty && mounted) {
        final bool? resumePrevious = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => StackDialog(
            width: Util.isDesktop ? 500 : null,
            title: "In-Progress Car Research",
            message:
                "You have an unfinished car research payment. "
                "Would you like to resume it or start a new search?",
            leftButton: SecondaryButton(
              label: "New",
              buttonHeight: Util.isDesktop ? .l : null,
              onPressed: Navigator.of(context).pop,
            ),
            rightButton: PrimaryButton(
              label: "Resume",
              buttonHeight: Util.isDesktop ? .l : null,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ),
        );

        if (resumePrevious == true && mounted) {
          unawaited(
            Navigator.of(context).pushNamedAndRemoveUntil(
              ShopInBitTicketsView.routeName,
              (route) => route.isFirst,
            ),
          );
          return;
        }
      }

      if (!mounted) return;

      unawaited(
        Navigator.of(
          context,
        ).pushNamed(ShopInBitCarFeeView.routeName, arguments: widget.model),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Util.isDesktop;

    final String? brandError =
        _brandTouched &&
            _brandController.text.trim().length < _minCarFieldLength
        ? "Minimum $_minCarFieldLength characters"
        : null;

    final String? modelError =
        _modelTouched &&
            _modelController.text.trim().length < _minCarFieldLength
        ? "Minimum $_minCarFieldLength characters"
        : null;

    final String? carDescriptionError =
        _carDescriptionTouched &&
            _carDescriptionController.text.trim().length < _minCarFieldLength
        ? "Minimum $_minCarFieldLength characters"
        : null;

    final String carBudgetText = _carBudgetController.text.trim();
    final int? carBudgetValue = int.tryParse(carBudgetText);
    final String? carBudgetError =
        _carBudgetTouched &&
            (carBudgetText.isEmpty ||
                carBudgetValue == null ||
                carBudgetValue < _minCarBudget)
        ? "Minimum budget is 20,000\u20AC"
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ShopInBitStep4Header(
          title: "Car Research request",
          subtitle: "Tell us about the car you're looking for.",
        ),
        SizedBox(height: isDesktop ? 32 : 24),
        ShopInBitCountryPicker(
          selectedIso: _selectedCountryIso,
          onChanged: (iso) => setState(() => _selectedCountryIso = iso),
        ),
        SizedBox(height: isDesktop ? 24 : 16),
        AdaptiveTextField(
          controller: _brandController,
          focusNode: _brandFocusNode,
          labelText: "Car brand (e.g., BMW, Mercedes, Toyota...)",
          autocorrect: false,
          enableSuggestions: false,
          errorText: brandError,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: isDesktop ? 24 : 16),
        AdaptiveTextField(
          controller: _modelController,
          focusNode: _modelFocusNode,
          labelText: "Car model (e.g., 3 Series, E-Class, Camry...)",
          autocorrect: false,
          enableSuggestions: false,
          errorText: modelError,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: isDesktop ? 24 : 16),
        ShopInBitStep4Dropdown(
          value: _selectedCarCondition,
          items: _carConditions,
          hintText: "Condition",
          onChanged: (value) => setState(() => _selectedCarCondition = value),
        ),
        SizedBox(height: isDesktop ? 24 : 16),
        AdaptiveTextField(
          controller: _carDescriptionController,
          focusNode: _carDescriptionFocusNode,
          labelText:
              "Describe your requirements "
              "(year, mileage, features...)",
          minLines: 3,
          maxLines: 6,
          autocorrect: false,
          enableSuggestions: false,
          errorText: carDescriptionError,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: isDesktop ? 24 : 16),
        AdaptiveTextField(
          controller: _carBudgetController,
          focusNode: _carBudgetFocusNode,
          labelText: "Budget (\u20AC, minimum 20,000)",
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          suffixText: "\u20AC",
          autocorrect: false,
          enableSuggestions: false,
          errorText: carBudgetError,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: isDesktop ? 24 : 16),
        _CarResearchFeeInfo(isDesktop: isDesktop),
        SizedBox(height: isDesktop ? 16 : 12),
        ShopInBitLabeledCheckbox(
          value: _feeAcknowledged,
          onChanged: (v) => setState(() => _feeAcknowledged = v),
          label: "I acknowledge the \u20AC223 research fee",
        ),
        const SizedBox(height: 24),
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

/// Info box showing the €223 (incl. VAT) research fee disclosure.
class _CarResearchFeeInfo extends StatelessWidget {
  const _CarResearchFeeInfo({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = isDesktop
        ? STextStyles.desktopTextSmall(context)
        : STextStyles.w500_14(context);

    return RoundedWhiteContainer(
      borderColor: isDesktop
          ? Theme.of(context).extension<StackColors>()!.textFieldDefaultBG
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            Assets.svg.circleInfo,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              Theme.of(
                context,
              ).extension<StackColors>()!.textFieldActiveSearchIconLeft,
              .srcIn,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: baseStyle,
                children: [
                  TextSpan(
                    text: "Research fee: ",
                    style: baseStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                    text:
                        "\u20AC223 (incl. VAT): one-time payment, "
                        "credited toward your purchase.",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
