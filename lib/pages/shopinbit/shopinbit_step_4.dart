import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
  late final TextEditingController _descriptionController;
  late final FocusNode _descriptionFocusNode;
  final TextEditingController _countrySearchController =
      TextEditingController();

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

  bool get _canContinue =>
      !_submitting &&
      _privacyAccepted &&
      _descriptionController.text.trim().isNotEmpty &&
      _selectedCountryIso != null;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.model.requestDescription,
    );
    _descriptionFocusNode = FocusNode();
    _descriptionFocusNode.addListener(() => setState(() {}));
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
    widget.model.requestDescription = _descriptionController.text.trim();
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    final String descriptionPlaceholder =
        widget.model.category == ShopInBitCategory.car
            ? "Describe the car (make, model, year, requirements)"
            : "What would you like to purchase?";

    final content = Column(
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
          "Describe your request",
          style: isDesktop
              ? STextStyles.desktopH2(context)
              : STextStyles.pageTitleH1(context),
        ),
        SizedBox(height: isDesktop ? 16 : 8),
        Text(
          "Provide details about what you'd like to purchase.",
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
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        GestureDetector(
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
                          text: "I have read and agree to the ShopInBit ",
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
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        PrimaryButton(
          label: _submitting ? "Submitting..." : "Submit request",
          enabled: _canContinue,
          onPressed: _canContinue ? _submit : null,
        ),
      ],
    );

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
      ),
    );
  }
}
