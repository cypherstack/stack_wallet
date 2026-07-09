import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../models/shopinbit/shopinbit_request_draft.dart";
import "../../../providers/global/shopin_bit_service_provider.dart";
import "../../../utilities/text_styles.dart";
import "../../../utilities/util.dart";
import "../../../widgets/date_picker/date_picker.dart";
import "../../../widgets/textfields/adaptive_text_field.dart";
import "shopinbit_country_picker.dart";
import "shopinbit_privacy_checkbox.dart";
import "shopinbit_step4_dropdown.dart";
import "shopinbit_step4_header.dart";
import "shopinbit_step4_submit.dart";
import "shopinbit_step4_submit_button.dart";
import "shopinbit_traveler_counter.dart";

const List<String> _arrangements = [
  "Flights Only",
  "Hotels Only",
  "Full Service",
];

const int _minTravelBudget = 1000;
const int _minArrangementDetailsLength = 10;

/// Travel request form. Collects arrangement type, departure / destinations,
/// dates (either exact or flexible), travelers and budget, then submits via
/// the shared submit helper.
class ShopInBitTravelForm extends ConsumerStatefulWidget {
  const ShopInBitTravelForm({super.key});

  @override
  ConsumerState<ShopInBitTravelForm> createState() =>
      _ShopInBitTravelFormState();
}

class _ShopInBitTravelFormState extends ConsumerState<ShopInBitTravelForm> {
  final TextEditingController _arrangementDetailsController =
      TextEditingController();
  final FocusNode _arrangementDetailsFocusNode = FocusNode();
  bool _arrangementDetailsTouched = false;

  final TextEditingController _departureCityController =
      TextEditingController();
  final FocusNode _departureCityFocusNode = FocusNode();
  bool _departureCityTouched = false;

  final TextEditingController _destinationsController = TextEditingController();
  final FocusNode _destinationsFocusNode = FocusNode();
  bool _destinationsTouched = false;

  DateTime? _departureDate;
  DateTime? _returnDate;

  final TextEditingController _travelBudgetController = TextEditingController(
    text: "5000",
  );
  final FocusNode _travelBudgetFocusNode = FocusNode();
  bool _travelBudgetTouched = false;

  String? _selectedArrangement;
  String? _selectedDepartureCountryIso;

  int _adults = 1;
  int _children = 0;
  int _infants = 0;
  int _pets = 0;

  bool _privacyAccepted = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _wireTouchOnBlur(
      _arrangementDetailsFocusNode,
      () => _arrangementDetailsTouched = true,
    );
    _wireTouchOnBlur(
      _departureCityFocusNode,
      () => _departureCityTouched = true,
    );
    _wireTouchOnBlur(_destinationsFocusNode, () => _destinationsTouched = true);
    _wireTouchOnBlur(_travelBudgetFocusNode, () => _travelBudgetTouched = true);
  }

  void _wireTouchOnBlur(FocusNode node, VoidCallback markTouched) {
    node.addListener(() {
      if (!node.hasFocus) markTouched();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _arrangementDetailsController.dispose();
    _arrangementDetailsFocusNode.dispose();
    _departureCityController.dispose();
    _departureCityFocusNode.dispose();
    _destinationsController.dispose();
    _destinationsFocusNode.dispose();
    _travelBudgetController.dispose();
    _travelBudgetFocusNode.dispose();
    super.dispose();
  }

  bool get _hasValidDates => _departureDate != null && _returnDate != null;

  bool get _canContinue {
    final int? travelBudgetValue = int.tryParse(
      _travelBudgetController.text.trim(),
    );
    return !_submitting &&
        _privacyAccepted &&
        _selectedArrangement != null &&
        _arrangementDetailsController.text.trim().length >=
            _minArrangementDetailsLength &&
        _selectedDepartureCountryIso != null &&
        _departureCityController.text.trim().isNotEmpty &&
        _destinationsController.text.trim().isNotEmpty &&
        _hasValidDates &&
        _adults >= 1 &&
        travelBudgetValue != null &&
        travelBudgetValue >= _minTravelBudget;
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, "0");
    final String month = date.month.toString().padLeft(2, "0");
    return "$day/$month/${date.year}";
  }

  String _buildRequestDescription() {
    final List<String> parts = [
      "Arrangement: $_selectedArrangement",
      "Details: ${_arrangementDetailsController.text.trim()}",
      "Departure: ${_departureCityController.text.trim()}, "
          "${_selectedDepartureCountryIso!}",
    ];

    parts.add("Destinations: ${_destinationsController.text.trim()}");

    parts.add(
      "Dates: ${_formatDate(_departureDate!)} - "
      "${_formatDate(_returnDate!)}",
    );

    final List<String> travelers = ["$_adults adult${_adults > 1 ? 's' : ''}"];
    if (_children > 0) {
      travelers.add("$_children child${_children > 1 ? 'ren' : ''}");
    }
    if (_infants > 0) {
      travelers.add("$_infants infant${_infants > 1 ? 's' : ''}");
    }
    if (_pets > 0) {
      travelers.add("$_pets pet${_pets > 1 ? 's' : ''}");
    }
    parts.add("Travelers: ${travelers.join(', ')}");

    parts.add("Budget: ${_travelBudgetController.text.trim()} EUR");

    return parts.join("\n");
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final draft = ShopinbitRequestDraft(
      category: .travel,
      requestDescription: _buildRequestDescription(),
      // Travel doesn't collect a delivery country: default to "DE" since the
      // API requires the field. Travel destinations are captured in the
      // structured comment field.
      deliveryCountryCode: "DE",
      voucherCode: null,
      deliveryCountryName: "Germany",
      deliveryState: null,
    );
    try {
      await submitShopInBitRequest(context, draft, ref.read(pShopinBitService));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Util.isDesktop;

    final String? arrangementDetailsError =
        _arrangementDetailsTouched &&
            _arrangementDetailsController.text.trim().length <
                _minArrangementDetailsLength
        ? "Minimum $_minArrangementDetailsLength characters"
        : null;

    final String? departureCityError =
        _departureCityTouched && _departureCityController.text.trim().isEmpty
        ? "Required"
        : null;

    final String? destinationsError =
        _destinationsTouched && _destinationsController.text.trim().isEmpty
        ? "Required"
        : null;

    final String travelBudgetText = _travelBudgetController.text.trim();
    final int? travelBudgetValue = int.tryParse(travelBudgetText);
    final String? travelBudgetError =
        _travelBudgetTouched &&
            (travelBudgetText.isEmpty ||
                travelBudgetValue == null ||
                travelBudgetValue < _minTravelBudget)
        ? "Minimum budget is 1,000 EUR"
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ShopInBitStep4Header(
          title: "Travel request",
          subtitle: "Tell us about your trip and we'll arrange everything.",
        ),
        SizedBox(height: isDesktop ? 32 : 24),

        _TravelSectionLabel(text: "Trip type", isDesktop: isDesktop),
        SizedBox(height: isDesktop ? 12 : 8),
        ShopInBitStep4Dropdown(
          value: _selectedArrangement,
          items: _arrangements,
          hintText: "Arrangement type",
          onChanged: (value) => setState(() => _selectedArrangement = value),
        ),

        SizedBox(height: isDesktop ? 24 : 16),
        _TravelSectionLabel(text: "Where", isDesktop: isDesktop),
        SizedBox(height: isDesktop ? 12 : 8),
        ShopInBitCountryPicker(
          selectedIso: _selectedDepartureCountryIso,
          onChanged: (data) => setState(() {
            _selectedDepartureCountryIso = data?.code;
          }),
          hintText: "Departure country",
        ),
        SizedBox(height: isDesktop ? 24 : 16),
        AdaptiveTextField(
          controller: _departureCityController,
          focusNode: _departureCityFocusNode,
          labelText: "Departure city",
          autocorrect: false,
          enableSuggestions: false,
          errorText: departureCityError,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: isDesktop ? 24 : 16),
        AdaptiveTextField(
          controller: _destinationsController,
          focusNode: _destinationsFocusNode,
          labelText: "Destination (City, Country, Region)",
          autocorrect: false,
          enableSuggestions: false,
          errorText: destinationsError,
          onChanged: (_) => setState(() {}),
        ),

        SizedBox(height: isDesktop ? 24 : 16),
        _TravelSectionLabel(text: "When", isDesktop: isDesktop),
        SizedBox(height: isDesktop ? 12 : 8),
        StackDateRangePicker(
          fromDate: _departureDate,
          toDate: _returnDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
          onChanged: (from, to) {
            setState(() {
              _departureDate = from;
              _returnDate = to;
            });
          },
        ),

        SizedBox(height: isDesktop ? 24 : 16),
        _TravelSectionLabel(text: "Who", isDesktop: isDesktop),
        SizedBox(height: isDesktop ? 12 : 8),
        ShopInBitTravelerCounter(
          label: "Adults",
          value: _adults,
          min: 1,
          onChanged: (v) => setState(() => _adults = v),
        ),
        SizedBox(height: isDesktop ? 12 : 8),
        ShopInBitTravelerCounter(
          label: "Children",
          value: _children,
          onChanged: (v) => setState(() => _children = v),
        ),
        SizedBox(height: isDesktop ? 12 : 8),
        ShopInBitTravelerCounter(
          label: "Infants",
          value: _infants,
          onChanged: (v) => setState(() => _infants = v),
        ),
        SizedBox(height: isDesktop ? 12 : 8),
        ShopInBitTravelerCounter(
          label: "Pets",
          value: _pets,
          onChanged: (v) => setState(() => _pets = v),
        ),

        SizedBox(height: isDesktop ? 24 : 16),
        _TravelSectionLabel(text: "Budget", isDesktop: isDesktop),
        SizedBox(height: isDesktop ? 12 : 8),
        AdaptiveTextField(
          controller: _travelBudgetController,
          focusNode: _travelBudgetFocusNode,
          labelText: "Minimum 1000 EUR",
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          suffixText: "EUR",
          autocorrect: false,
          enableSuggestions: false,
          errorText: travelBudgetError,
          onChanged: (_) => setState(() {}),
        ),

        SizedBox(height: isDesktop ? 24 : 16),
        AdaptiveTextField(
          controller: _arrangementDetailsController,
          focusNode: _arrangementDetailsFocusNode,
          labelText: "Describe your travel needs or paste a LINK here",
          minLines: 3,
          maxLines: 6,
          autocorrect: false,
          enableSuggestions: false,
          errorText: arrangementDetailsError,
          onChanged: (_) => setState(() {}),
        ),

        // Travel doesn't collect delivery country: destinations are in the
        // form and the API field is set to "DE" on submit.
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

/// Bold-ish section header used inside the travel form ("Trip type", "Where",
/// "When", "Who", "Budget").
class _TravelSectionLabel extends StatelessWidget {
  const _TravelSectionLabel({required this.text, required this.isDesktop});

  final String text;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: isDesktop
          ? STextStyles.desktopTextSmall(context)
          : STextStyles.w500_14(context),
    );
  }
}
