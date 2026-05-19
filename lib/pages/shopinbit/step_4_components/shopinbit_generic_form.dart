import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../models/shopinbit/shopinbit_order_model.dart";
import "../../../providers/global/shopin_bit_service_provider.dart";
import "../../../utilities/util.dart";
import "shopinbit_country_picker.dart";
import "shopinbit_privacy_checkbox.dart";
import "shopinbit_step4_header.dart";
import "shopinbit_step4_submit.dart";
import "shopinbit_step4_submit_button.dart";
import "shopinbit_step4_text_field.dart";

/// Fallback Step 4 form used when no category was selected. Collects a free
/// text description and a delivery country.
///
/// Note: the original code used the travel copy for this fallback; that
/// behaviour is preserved here.
class ShopInBitGenericForm extends ConsumerStatefulWidget {
  const ShopInBitGenericForm({super.key, required this.model});

  final ShopInBitOrderModel model;

  @override
  ConsumerState<ShopInBitGenericForm> createState() =>
      _ShopInBitGenericFormState();
}

class _ShopInBitGenericFormState extends ConsumerState<ShopInBitGenericForm> {
  late final TextEditingController _descriptionController;
  final FocusNode _descriptionFocusNode = FocusNode();

  String? _selectedCountryIso;
  bool _privacyAccepted = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.model.requestDescription,
    );
    _descriptionFocusNode.addListener(() => setState(() {}));

    if (widget.model.deliveryCountry.isNotEmpty) {
      _selectedCountryIso = widget.model.deliveryCountry;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      !_submitting &&
      _privacyAccepted &&
      _descriptionController.text.trim().isNotEmpty &&
      _selectedCountryIso != null;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    widget.model
      ..requestDescription = _descriptionController.text.trim()
      ..deliveryCountry = _selectedCountryIso!;
    try {
      await submitShopInBitRequest(
        context,
        widget.model,
        ref.read(pShopinBitService),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Util.isDesktop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ShopInBitStep4Header(
          title: "Describe your travel request",
          subtitle: "Provide details about your trip.",
        ),
        SizedBox(height: isDesktop ? 32 : 24),
        ShopInBitStep4TextField(
          controller: _descriptionController,
          focusNode: _descriptionFocusNode,
          hintText:
              "Describe your travel request (destinations, dates, passengers)",
          minLines: 3,
          maxLines: 6,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: isDesktop ? 24 : 16),
        ShopInBitCountryPicker(
          selectedIso: _selectedCountryIso,
          onChanged: (iso) => setState(() => _selectedCountryIso = iso),
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        ShopInBitPrivacyCheckbox(
          value: _privacyAccepted,
          onChanged: (v) => setState(() => _privacyAccepted = v),
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        ShopInBitStep4SubmitButton(
          submitting: _submitting,
          enabled: _canContinue,
          onPressed: _submit,
        ),
      ],
    );
  }
}
