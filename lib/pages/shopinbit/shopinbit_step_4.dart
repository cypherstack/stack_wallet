import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dart:async';

import '../../db/isar/main_db.dart';
import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../notifications/show_flush_bar.dart';
import '../../services/shopinbit/shopinbit_service.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/constants.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/stack_dialog.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_text_field.dart';
import '../exchange_view/sub_widgets/step_row.dart';
import 'shopinbit_car_fee_view.dart';
import 'shopinbit_order_created.dart';

class ShopInBitStep4 extends StatefulWidget {
  const ShopInBitStep4({super.key, required this.model});

  static const String routeName = "/shopInBitStep4";

  final ShopInBitOrderModel model;

  @override
  State<ShopInBitStep4> createState() => _ShopInBitStep4State();
}

class _ShopInBitStep4State extends State<ShopInBitStep4> {
  // Generic form controllers.
  late final TextEditingController _descriptionController;
  late final FocusNode _descriptionFocusNode;
  final TextEditingController _countrySearchController =
      TextEditingController();

  // Concierge-specific controllers
  late final TextEditingController _whatToPurchaseController;
  late final FocusNode _whatToPurchaseFocusNode;
  late final TextEditingController _budgetController;
  late final FocusNode _budgetFocusNode;
  String? _selectedCondition;
  bool _noLimit = false;
  bool _whatToPurchaseTouched = false;
  bool _budgetTouched = false;

  // Car Research-specific controllers
  late final TextEditingController _brandController;
  late final FocusNode _brandFocusNode;
  late final TextEditingController _modelController;
  late final FocusNode _modelFocusNode;
  late final TextEditingController _carDescriptionController;
  late final FocusNode _carDescriptionFocusNode;
  late final TextEditingController _carBudgetController;
  late final FocusNode _carBudgetFocusNode;
  String? _selectedCarCondition;
  bool _feeAcknowledged = false;
  bool _brandTouched = false;
  bool _modelTouched = false;
  bool _carDescriptionTouched = false;
  bool _carBudgetTouched = false;

  List<Map<String, dynamic>> _countries = [];
  String? _selectedCountryIso;
  bool _loadingCountries = false;

  bool _submitting = false;
  bool _privacyAccepted = false;

  Future<bool> _showOpenBrowserWarning(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final shouldContinue = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Util.isDesktop
          ? DesktopDialog(
              maxWidth: 550,
              maxHeight: 250,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    Text("Attention", style: STextStyles.desktopH2(context)),
                    const SizedBox(height: 16),
                    Text(
                      "You are about to open "
                      "${uri.scheme}://${uri.host} "
                      "in your browser.",
                      style: STextStyles.desktopTextSmall(context),
                    ),
                    const SizedBox(height: 35),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SecondaryButton(
                          width: 200,
                          buttonHeight: ButtonHeight.l,
                          label: "Cancel",
                          onPressed: () {
                            Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pop(false);
                          },
                        ),
                        const SizedBox(width: 20),
                        PrimaryButton(
                          width: 200,
                          buttonHeight: ButtonHeight.l,
                          label: "Continue",
                          onPressed: () {
                            Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pop(true);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : StackDialog(
              title: "Attention",
              message:
                  "You are about to open "
                  "${uri.scheme}://${uri.host} "
                  "in your browser.",
              leftButton: TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text(
                  "Cancel",
                  style: STextStyles.button(context).copyWith(
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.accentColorDark,
                  ),
                ),
              ),
              rightButton: TextButton(
                style: Theme.of(context)
                    .extension<StackColors>()!
                    .getPrimaryEnabledButtonStyle(context),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text("Continue", style: STextStyles.button(context)),
              ),
            ),
    );
    return shouldContinue ?? false;
  }

  bool get _budgetIsValid {
    final text = _budgetController.text.trim();
    if (text.isEmpty) return false;
    final value = int.tryParse(text);
    return value != null && value >= 1000 && value <= 100000;
  }

  bool get _canContinue {
    final cat = widget.model.category;
    if (cat == ShopInBitCategory.concierge) {
      return !_submitting &&
          _privacyAccepted &&
          _whatToPurchaseController.text.trim().length >= 10 &&
          _selectedCondition != null &&
          (_noLimit || _budgetIsValid) &&
          _selectedCountryIso != null;
    }
    if (cat == ShopInBitCategory.car) {
      final carBudgetVal = int.tryParse(_carBudgetController.text.trim());
      return !_submitting &&
          _privacyAccepted &&
          _feeAcknowledged &&
          _brandController.text.trim().length >= 3 &&
          _modelController.text.trim().length >= 3 &&
          _carDescriptionController.text.trim().length >= 3 &&
          _selectedCarCondition != null &&
          carBudgetVal != null &&
          carBudgetVal >= 20000 &&
          _selectedCountryIso != null;
    }
    // travel: existing logic
    return !_submitting &&
        _privacyAccepted &&
        _descriptionController.text.trim().isNotEmpty &&
        _selectedCountryIso != null;
  }

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.model.requestDescription,
    );
    _descriptionFocusNode = FocusNode();
    _descriptionFocusNode.addListener(() => setState(() {}));

    // Concierge-specific init
    _whatToPurchaseController = TextEditingController();
    _whatToPurchaseFocusNode = FocusNode();
    _whatToPurchaseFocusNode.addListener(() {
      if (!_whatToPurchaseFocusNode.hasFocus) {
        _whatToPurchaseTouched = true;
      }
      setState(() {});
    });
    _budgetController = TextEditingController(text: "1000");
    _budgetFocusNode = FocusNode();
    _budgetFocusNode.addListener(() {
      if (!_budgetFocusNode.hasFocus) {
        _budgetTouched = true;
      }
      setState(() {});
    });

    // Car Research-specific init
    _brandController = TextEditingController();
    _brandFocusNode = FocusNode();
    _brandFocusNode.addListener(() {
      if (!_brandFocusNode.hasFocus) {
        _brandTouched = true;
      }
      setState(() {});
    });
    _modelController = TextEditingController();
    _modelFocusNode = FocusNode();
    _modelFocusNode.addListener(() {
      if (!_modelFocusNode.hasFocus) {
        _modelTouched = true;
      }
      setState(() {});
    });
    _carDescriptionController = TextEditingController();
    _carDescriptionFocusNode = FocusNode();
    _carDescriptionFocusNode.addListener(() {
      if (!_carDescriptionFocusNode.hasFocus) {
        _carDescriptionTouched = true;
      }
      setState(() {});
    });
    _carBudgetController = TextEditingController();
    _carBudgetFocusNode = FocusNode();
    _carBudgetFocusNode.addListener(() {
      if (!_carBudgetFocusNode.hasFocus) {
        _carBudgetTouched = true;
      }
      setState(() {});
    });

    if (widget.model.deliveryCountry.isNotEmpty) {
      _selectedCountryIso = widget.model.deliveryCountry;
    }
    _fetchCountries();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();
    _countrySearchController.dispose();
    _whatToPurchaseController.dispose();
    _whatToPurchaseFocusNode.dispose();
    _budgetController.dispose();
    _budgetFocusNode.dispose();
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

  void _popBack() {
    if (Util.isDesktop) {
      Navigator.of(context, rootNavigator: true).pop();
    } else {
      Navigator.of(context).pop();
    }
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

  Future<void> _submit() async {
    // Format structured comment for Concierge
    if (widget.model.category == ShopInBitCategory.concierge) {
      final budgetText =
          _noLimit ? "No limit" : "${_budgetController.text.trim()} EUR";
      final countryLabel = _countries
              .where((c) => c['iso'] == _selectedCountryIso)
              .map((c) => c['label'] as String)
              .firstOrNull ??
          _selectedCountryIso!;
      widget.model.requestDescription =
          "What to purchase: ${_whatToPurchaseController.text.trim()}\n"
          "Condition: $_selectedCondition\n"
          "Budget: $budgetText\n"
          "Delivery country: $countryLabel";
    } else if (widget.model.category == ShopInBitCategory.car) {
      final countryLabel = _countries
              .where((c) => c['iso'] == _selectedCountryIso)
              .map((c) => c['label'] as String)
              .firstOrNull ??
          _selectedCountryIso!;
      widget.model.requestDescription =
          "Brand: ${_brandController.text.trim()}\n"
          "Model: ${_modelController.text.trim()}\n"
          "Condition: $_selectedCarCondition\n"
          "Description: ${_carDescriptionController.text.trim()}\n"
          "Budget: ${_carBudgetController.text.trim()} EUR\n"
          "Delivery country: $countryLabel";
    } else {
      widget.model.requestDescription = _descriptionController.text.trim();
    }
    widget.model.deliveryCountry = _selectedCountryIso!;

    if (widget.model.category == ShopInBitCategory.car) {
      if (Util.isDesktop) {
        Navigator.of(context, rootNavigator: true).pop();
        unawaited(
          showDialog<void>(
            context: context,
            builder: (_) => ShopInBitCarFeeView(model: widget.model),
          ),
        );
      } else {
        unawaited(
          Navigator.of(
            context,
          ).pushNamed(ShopInBitCarFeeView.routeName, arguments: widget.model),
        );
      }
      return;
    }

    setState(() => _submitting = true);
    try {
      final service = ShopInBitService.instance;
      final customerKey = await service.ensureCustomerKey();

      assert(
        widget.model.category != null,
        'Step 4 reached with null category — Step 2 must set category before reaching Step 4',
      );

      final categoryStr = switch (widget.model.category) {
        ShopInBitCategory.concierge => "concierge",
        ShopInBitCategory.travel => "travel",
        ShopInBitCategory.car => "car",
        null => throw StateError('category must be non-null at Step 4 submit'),
      };

      final resp = await service.client.createRequest(
        customerPseudonym: widget.model.displayName,
        externalCustomerKey: customerKey,
        serviceType: categoryStr,
        comment: widget.model.requestDescription,
        deliveryCountry: widget.model.deliveryCountry,
      );

      if (resp.hasError) {
        if (mounted) {
          unawaited(
            showFloatingFlushBar(
              type: FlushBarType.warning,
              message: resp.exception?.message ?? "Failed to create request",
              context: context,
            ),
          );
        }
        return;
      }

      final ref = resp.value!;
      widget.model.apiTicketId = ref.id;
      widget.model.ticketId = ref.number;
      widget.model.status = ShopInBitOrderStatus.pending;
      await MainDB.instance.putShopInBitTicket(widget.model.toIsarTicket());

      if (!mounted) return;
      if (Util.isDesktop) {
        Navigator.of(context, rootNavigator: true).pop();
        unawaited(
          showDialog<void>(
            context: context,
            builder: (_) => ShopInBitOrderCreated(model: widget.model),
          ),
        );
      } else {
        unawaited(
          Navigator.of(
            context,
          ).pushNamed(ShopInBitOrderCreated.routeName, arguments: widget.model),
        );
      }
    } catch (e) {
      if (mounted) {
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.warning,
            message: "Failed to create request: $e",
            context: context,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // Shared widgets.
  Widget _buildCountryPicker(bool isDesktop) {
    return ClipRRect(
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
            _loadingCountries ? "Loading countries..." : "Delivery country",
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
    );
  }

  Widget _buildPrivacyCheckbox(bool isDesktop) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _privacyAccepted = !_privacyAccepted;
        });
      },
      child: Container(
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: isDesktop
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: isDesktop ? 3 : 0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: IgnorePointer(
                  child: Checkbox(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: _privacyAccepted,
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: isDesktop
                      ? STextStyles.desktopTextSmall(context)
                      : STextStyles.w500_14(context),
                  children: [
                    const TextSpan(
                      text: "I have read and agree to the ShopinBit ",
                    ),
                    TextSpan(
                      text: "Privacy Policy",
                      style: STextStyles.richLink(
                        context,
                      ).copyWith(fontSize: isDesktop ? 18 : 14),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          const url =
                              "https://api.shopinbit.com/static/policy/privacy.html";
                          final shouldOpen = await _showOpenBrowserWarning(
                            context,
                            url,
                          );
                          if (shouldOpen) {
                            await launchUrl(
                              Uri.parse(url),
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                    ),
                    const TextSpan(text: "."),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return PrimaryButton(
      label: _submitting ? "Submitting..." : "Submit request",
      enabled: _canContinue,
      onPressed: _canContinue ? _submit : null,
    );
  }

  // Per-category form builders.

  Widget _buildConciergeContent(bool isDesktop) {
    final whatToPurchaseError = _whatToPurchaseTouched &&
            _whatToPurchaseController.text.trim().length < 10
        ? "Minimum 10 characters"
        : null;

    final budgetError = _budgetTouched && !_noLimit && !_budgetIsValid
        ? "Enter a value between 1,000 and 100,000"
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isDesktop)
          StepRow(
            count: 4,
            current: 3,
            width: MediaQuery.of(context).size.width - 32,
          ),
        if (!isDesktop) const SizedBox(height: 14),
        Text(
          "What would you like to purchase?",
          style: isDesktop
              ? STextStyles.desktopH2(context)
              : STextStyles.pageTitleH1(context),
        ),
        SizedBox(height: isDesktop ? 16 : 8),
        Text(
          "Tell us what you're looking for and we'll find it for you.",
          style: isDesktop
              ? STextStyles.desktopTextSmall(context)
              : STextStyles.itemSubtitle(context),
        ),
        SizedBox(height: isDesktop ? 32 : 24),

        // What to purchase free-text field
        TextField(
          controller: _whatToPurchaseController,
          focusNode: _whatToPurchaseFocusNode,
          autocorrect: false,
          enableSuggestions: false,
          minLines: 3,
          maxLines: 6,
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
                "Describe what you'd like to purchase (e.g., electronics, luxury goods, services...)",
                _whatToPurchaseFocusNode,
                context,
                desktopMed: isDesktop,
              ).copyWith(
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                errorText: whatToPurchaseError,
              ),
        ),
        SizedBox(height: isDesktop ? 24 : 16),

        // Condition picker
        ClipRRect(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              value: _selectedCondition,
              items: ["NEW", "USED"]
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(
                        c,
                        style: isDesktop
                            ? STextStyles.desktopTextExtraSmall(
                                context,
                              ).copyWith(
                                color: Theme.of(
                                  context,
                                )
                                    .extension<StackColors>()!
                                    .textFieldActiveText,
                              )
                            : STextStyles.w500_14(context),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCondition = value;
                });
              },
              hint: Text(
                "Condition",
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
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).extension<StackColors>()!.textFieldDefaultBG,
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ),
        SizedBox(height: isDesktop ? 24 : 16),

        // Budget field
        TextField(
          controller: _budgetController,
          focusNode: _budgetFocusNode,
          autocorrect: false,
          enableSuggestions: false,
          enabled: !_noLimit,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                "Budget (\u20AC)",
                _budgetFocusNode,
                context,
                desktopMed: isDesktop,
              ).copyWith(
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixText: "\u20AC",
                errorText: budgetError,
              ),
        ),
        SizedBox(height: isDesktop ? 12 : 8),

        // No budget limit checkbox
        GestureDetector(
          onTap: () {
            setState(() {
              _noLimit = !_noLimit;
            });
          },
          child: Container(
            color: Colors.transparent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: IgnorePointer(
                    child: Checkbox(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: _noLimit,
                      onChanged: (_) {},
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "No budget limit",
                  style: isDesktop
                      ? STextStyles.desktopTextSmall(context)
                      : STextStyles.w500_14(context),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: isDesktop ? 24 : 16),

        // Country picker (shared)
        _buildCountryPicker(isDesktop),
        SizedBox(height: isDesktop ? 16 : 12),

        // Privacy checkbox (shared)
        _buildPrivacyCheckbox(isDesktop),
        SizedBox(height: isDesktop ? 16 : 12),

        // Submit button (shared)
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildCarContent(bool isDesktop) {
    final brandError =
        _brandTouched && _brandController.text.trim().length < 3
            ? "Minimum 3 characters"
            : null;

    final modelError =
        _modelTouched && _modelController.text.trim().length < 3
            ? "Minimum 3 characters"
            : null;

    final carDescriptionError = _carDescriptionTouched &&
            _carDescriptionController.text.trim().length < 3
        ? "Minimum 3 characters"
        : null;

    final carBudgetText = _carBudgetController.text.trim();
    final carBudgetVal = int.tryParse(carBudgetText);
    final carBudgetError = _carBudgetTouched &&
            (carBudgetText.isEmpty ||
                carBudgetVal == null ||
                carBudgetVal < 20000)
        ? "Minimum budget is 20,000\u20AC"
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isDesktop)
          StepRow(
            count: 4,
            current: 3,
            width: MediaQuery.of(context).size.width - 32,
          ),
        if (!isDesktop) const SizedBox(height: 14),
        Text(
          "Car Research request",
          style: isDesktop
              ? STextStyles.desktopH2(context)
              : STextStyles.pageTitleH1(context),
        ),
        SizedBox(height: isDesktop ? 16 : 8),
        Text(
          "Tell us about the car you're looking for.",
          style: isDesktop
              ? STextStyles.desktopTextSmall(context)
              : STextStyles.itemSubtitle(context),
        ),
        SizedBox(height: isDesktop ? 32 : 24),

        // Country picker (shared)
        _buildCountryPicker(isDesktop),
        SizedBox(height: isDesktop ? 24 : 16),

        // Brand field
        TextField(
          controller: _brandController,
          focusNode: _brandFocusNode,
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
                "Car brand (e.g., BMW, Mercedes, Toyota...)",
                _brandFocusNode,
                context,
                desktopMed: isDesktop,
              ).copyWith(
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                errorText: brandError,
              ),
        ),
        SizedBox(height: isDesktop ? 24 : 16),

        // Model field
        TextField(
          controller: _modelController,
          focusNode: _modelFocusNode,
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
                "Car model (e.g., 3 Series, E-Class, Camry...)",
                _modelFocusNode,
                context,
                desktopMed: isDesktop,
              ).copyWith(
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                errorText: modelError,
              ),
        ),
        SizedBox(height: isDesktop ? 24 : 16),

        // Condition picker
        ClipRRect(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              value: _selectedCarCondition,
              items: ["NEW", "PREOWNED"]
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(
                        c,
                        style: isDesktop
                            ? STextStyles.desktopTextExtraSmall(
                                context,
                              ).copyWith(
                                color: Theme.of(
                                  context,
                                )
                                    .extension<StackColors>()!
                                    .textFieldActiveText,
                              )
                            : STextStyles.w500_14(context),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCarCondition = value;
                });
              },
              hint: Text(
                "Condition",
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
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).extension<StackColors>()!.textFieldDefaultBG,
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ),
        SizedBox(height: isDesktop ? 24 : 16),

        // Description field (multiline)
        TextField(
          controller: _carDescriptionController,
          focusNode: _carDescriptionFocusNode,
          autocorrect: false,
          enableSuggestions: false,
          minLines: 3,
          maxLines: 6,
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
                "Describe your requirements (year, mileage, features...)",
                _carDescriptionFocusNode,
                context,
                desktopMed: isDesktop,
              ).copyWith(
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                errorText: carDescriptionError,
              ),
        ),
        SizedBox(height: isDesktop ? 24 : 16),

        // Budget field
        TextField(
          controller: _carBudgetController,
          focusNode: _carBudgetFocusNode,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                "Budget (\u20AC, minimum 20,000)",
                _carBudgetFocusNode,
                context,
                desktopMed: isDesktop,
              ).copyWith(
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixText: "\u20AC",
                errorText: carBudgetError,
              ),
        ),
        SizedBox(height: isDesktop ? 24 : 16),

        // Research fee info box
        RoundedWhiteContainer(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Theme.of(
                  context,
                ).extension<StackColors>()!.textFieldActiveSearchIconLeft,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: isDesktop
                        ? STextStyles.desktopTextSmall(context)
                        : STextStyles.w500_14(context),
                    children: [
                      TextSpan(
                        text: "Research fee: ",
                        style: isDesktop
                            ? STextStyles.desktopTextSmall(context).copyWith(
                                fontWeight: FontWeight.bold,
                              )
                            : STextStyles.w500_14(context).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      ),
                      const TextSpan(
                        text:
                            "\u20AC223 (incl. VAT): one-time payment, credited toward your purchase.",
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isDesktop ? 16 : 12),

        // Fee acknowledgement checkbox
        GestureDetector(
          onTap: () {
            setState(() {
              _feeAcknowledged = !_feeAcknowledged;
            });
          },
          child: Container(
            color: Colors.transparent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: IgnorePointer(
                    child: Checkbox(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: _feeAcknowledged,
                      onChanged: (_) {},
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "I acknowledge the \u20AC223 research fee",
                    style: isDesktop
                        ? STextStyles.desktopTextSmall(context)
                        : STextStyles.w500_14(context),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: isDesktop ? 16 : 12),

        // Privacy checkbox (shared)
        _buildPrivacyCheckbox(isDesktop),
        SizedBox(height: isDesktop ? 16 : 12),

        // Submit button (shared)
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildGenericContent(bool isDesktop) {
    // Travel uses the generic form; Concierge and Car have dedicated builders.
    const descriptionTitle = "Describe your travel request";
    const descriptionSubtitle = "Provide details about your trip.";
    const descriptionPlaceholder =
        "Describe your travel request (destinations, dates, passengers)";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isDesktop)
          StepRow(
            count: 4,
            current: 3,
            width: MediaQuery.of(context).size.width - 32,
          ),
        if (!isDesktop) const SizedBox(height: 14),
        Text(
          descriptionTitle,
          style: isDesktop
              ? STextStyles.desktopH2(context)
              : STextStyles.pageTitleH1(context),
        ),
        SizedBox(height: isDesktop ? 16 : 8),
        Text(
          descriptionSubtitle,
          style: isDesktop
              ? STextStyles.desktopTextSmall(context)
              : STextStyles.itemSubtitle(context),
        ),
        SizedBox(height: isDesktop ? 32 : 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
          child: TextField(
            controller: _descriptionController,
            focusNode: _descriptionFocusNode,
            autocorrect: false,
            enableSuggestions: false,
            minLines: 3,
            maxLines: 6,
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
                  descriptionPlaceholder,
                  _descriptionFocusNode,
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
        ),
        SizedBox(height: isDesktop ? 24 : 16),

        // Country picker (shared)
        _buildCountryPicker(isDesktop),
        SizedBox(height: isDesktop ? 16 : 12),

        // Privacy checkbox (shared)
        _buildPrivacyCheckbox(isDesktop),
        SizedBox(height: isDesktop ? 16 : 12),

        // Submit button (shared)
        _buildSubmitButton(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    final Widget content;
    switch (widget.model.category) {
      case ShopInBitCategory.concierge:
        content = _buildConciergeContent(isDesktop);
        break;
      case ShopInBitCategory.car:
        content = _buildCarContent(isDesktop);
        break;
      case ShopInBitCategory.travel:
      case null:
        content = _buildGenericContent(isDesktop);
        break;
    }

    if (isDesktop) {
      return DesktopDialog(
        maxWidth: 580,
        maxHeight: 560,
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
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (!didPop) {
            _popBack();
          }
        },
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: AppBarBackButton(
              onPressed: _popBack,
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
      ),
    );
  }
}
