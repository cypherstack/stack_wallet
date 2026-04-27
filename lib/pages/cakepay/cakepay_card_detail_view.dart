import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/cakepay/cakepay_service.dart';
import '../../services/cakepay/src/models/card.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/constants.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_dialog.dart';
import '../../widgets/stack_text_field.dart';
import 'cakepay_order_view.dart';

class CakePayCardDetailView extends StatefulWidget {
  const CakePayCardDetailView({super.key, required this.card});

  static const String routeName = "/cakePayCardDetail";

  final CakePayCard card;

  @override
  State<CakePayCardDetailView> createState() => _CakePayCardDetailViewState();
}

class _CakePayCardDetailViewState extends State<CakePayCardDetailView> {
  late CakePayCard _card;
  bool _purchasing = false;
  double? _selectedDenomination;
  int _quantity = 1;
  bool _termsAccepted = false;
  final _customAmountController = TextEditingController();
  final _customAmountFocusNode = FocusNode();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _card = widget.card;
    if (_card.isFixedDenomination && _card.denominations.isNotEmpty) {
      _selectedDenomination = _card.denominations.first;
    }
    _emailFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    _customAmountFocusNode.dispose();
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  String get _priceString {
    if (_card.isFixedDenomination && _selectedDenomination != null) {
      return _selectedDenomination!.toStringAsFixed(2);
    }
    return _customAmountController.text.trim();
  }

  bool get _canPurchase {
    if (!_termsAccepted || _purchasing) return false;
    if (_emailController.text.trim().isEmpty) return false;
    final price = _priceString;
    if (price.isEmpty) return false;
    final parsed = double.tryParse(price);
    if (parsed == null || parsed <= 0) return false;
    if (_card.isRangeDenomination) {
      if (_card.minValue != null && parsed < _card.minValue!) return false;
      if (_card.maxValue != null && parsed > _card.maxValue!) return false;
    }
    return true;
  }

  Future<bool> _showOpenBrowserWarning(String url) async {
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

  Future<void> _openTerms() async {
    const url = "https://cakepay.com/terms/";
    if (await _showOpenBrowserWarning(url)) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _purchase() async {
    if (!_canPurchase) return;
    setState(() => _purchasing = true);

    final resp = await CakePayService.instance.client.createOrder(
      cardId: _card.id,
      price: _priceString,
      quantity: _quantity > 1 ? _quantity : null,
      userEmail: _emailController.text.trim(),
      confirmsNoVpn: true,
      confirmsVoidedRefund: true,
      confirmsTermsAgreed: true,
    );

    if (mounted) {
      setState(() => _purchasing = false);
      if (!resp.hasError && resp.value != null) {
        final order = resp.value!;

        // Track order ID locally so the orders list view can fetch it
        // via getOrder() without requiring Knox user auth.
        CakePayService.instance.addOrderId(order.orderId);

        if (Util.isDesktop) {
          Navigator.of(context, rootNavigator: true).pop();
          await showDialog<void>(
            context: context,
            builder: (_) => CakePayOrderView(orderId: order.orderId),
          );
        } else {
          await Navigator.of(context).pushReplacementNamed(
            CakePayOrderView.routeName,
            arguments: order.orderId,
          );
        }
      } else {
        await showDialog<dynamic>(
          context: context,
          useSafeArea: false,
          barrierDismissible: true,
          builder: (context) {
            return StackDialog(
              title: "Purchase failed",
              message: resp.exception?.message ?? "Failed to create order",
              rightButton: TextButton(
                style: Theme.of(context)
                    .extension<StackColors>()!
                    .getSecondaryEnabledButtonStyle(context),
                child: Text(
                  "Ok",
                  style: STextStyles.button(context).copyWith(
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.buttonTextSecondary,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final card = _card;

    final denominationSelector = card.isFixedDenomination
        ? Wrap(
            spacing: 8,
            runSpacing: 8,
            children: card.denominations.map((d) {
              final selected = d == _selectedDenomination;
              return ChoiceChip(
                label: Text(
                  "${d.toStringAsFixed(0)} ${card.currencyCode ?? ''}",
                  style:
                      (isDesktop
                              ? STextStyles.desktopTextExtraExtraSmall(context)
                              : STextStyles.itemSubtitle12(context))
                          .copyWith(
                            color: selected
                                ? Theme.of(
                                    context,
                                  ).extension<StackColors>()!.textDark
                                : null,
                          ),
                ),
                selected: selected,
                onSelected: (val) {
                  if (val) setState(() => _selectedDenomination = d);
                },
              );
            }).toList(),
          )
        : card.isRangeDenomination
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Enter amount (${card.minValue?.toStringAsFixed(0) ?? '?'} - "
                "${card.maxValue?.toStringAsFixed(0) ?? '?'} "
                "${card.currencyCode ?? ''})",
                style: isDesktop
                    ? STextStyles.desktopTextExtraExtraSmall(context)
                    : STextStyles.itemSubtitle12(context),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
                child: TextField(
                  controller: _customAmountController,
                  focusNode: _customAmountFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  style: isDesktop
                      ? STextStyles.desktopTextExtraSmall(context).copyWith(
                          color: Theme.of(
                            context,
                          ).extension<StackColors>()!.textFieldActiveText,
                          height: 1.8,
                        )
                      : STextStyles.field(context).copyWith(
                          color: Theme.of(
                            context,
                          ).extension<StackColors>()!.textFieldActiveText,
                        ),
                  decoration:
                      standardInputDecoration(
                        "Amount",
                        _customAmountFocusNode,
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
            ],
          )
        : const SizedBox.shrink();

    final quantityRow = Row(
      children: [
        Text(
          "Quantity",
          style: isDesktop
              ? STextStyles.desktopTextExtraExtraSmall(context)
              : STextStyles.itemSubtitle12(context),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
        ),
        Text(
          "$_quantity",
          style: isDesktop
              ? STextStyles.desktopTextSmall(context)
              : STextStyles.titleBold12(context),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          onPressed: () => setState(() => _quantity++),
        ),
      ],
    );

    final termsCheckbox = GestureDetector(
      onTap: () => setState(() => _termsAccepted = !_termsAccepted),
      child: Container(
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              height: 26,
              child: IgnorePointer(
                child: Checkbox(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  value: _termsAccepted,
                  onChanged: (_) {},
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: isDesktop
                      ? STextStyles.desktopTextExtraExtraSmall(context)
                      : STextStyles.w500_14(context),
                  children: [
                    const TextSpan(text: "I agree to the "),
                    TextSpan(
                      text: "terms and conditions",
                      style: STextStyles.richLink(
                        context,
                      ).copyWith(fontSize: isDesktop ? null : 14),
                      recognizer: TapGestureRecognizer()..onTap = _openTerms,
                    ),
                    const TextSpan(
                      text:
                          ", confirm I am not using a VPN, "
                          "and understand refunds are voided. "
                          "I understand that the gift card "
                          "will be delivered to the listed "
                          "email.",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final content = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (card.cardImageUrl != null)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  card.cardImageUrl!,
                  width: isDesktop ? 200 : 150,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.card_giftcard, size: isDesktop ? 80 : 60),
                ),
              ),
            ),
          SizedBox(height: isDesktop ? 16 : 12),
          Text(
            card.name,
            style: isDesktop
                ? STextStyles.desktopH2(context)
                : STextStyles.pageTitleH1(context),
          ),
          if (card.description != null && card.description!.isNotEmpty) ...[
            SizedBox(height: isDesktop ? 16 : 12),
            RoundedWhiteContainer(
              child: Text(
                card.description!,
                style: isDesktop
                    ? STextStyles.desktopTextExtraExtraSmall(context)
                    : STextStyles.itemSubtitle12(context),
              ),
            ),
          ],
          if (card.howToUse != null && card.howToUse!.isNotEmpty) ...[
            SizedBox(height: isDesktop ? 16 : 12),
            RoundedWhiteContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "How to use",
                    style: isDesktop
                        ? STextStyles.desktopTextSmall(context)
                        : STextStyles.titleBold12(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.howToUse!,
                    style: isDesktop
                        ? STextStyles.desktopTextExtraExtraSmall(context)
                        : STextStyles.itemSubtitle12(context),
                  ),
                ],
              ),
            ),
          ],
          if (card.termsAndConditions != null &&
              card.termsAndConditions!.isNotEmpty) ...[
            SizedBox(height: isDesktop ? 16 : 12),
            RoundedWhiteContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Terms & conditions",
                    style: isDesktop
                        ? STextStyles.desktopTextSmall(context)
                        : STextStyles.titleBold12(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.termsAndConditions!,
                    style: isDesktop
                        ? STextStyles.desktopTextExtraExtraSmall(context)
                        : STextStyles.itemSubtitle12(context),
                  ),
                ],
              ),
            ),
          ],
          if (card.expiryAndValidity != null &&
              card.expiryAndValidity!.isNotEmpty) ...[
            SizedBox(height: isDesktop ? 16 : 12),
            RoundedWhiteContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Expiry & validity",
                    style: isDesktop
                        ? STextStyles.desktopTextSmall(context)
                        : STextStyles.titleBold12(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.expiryAndValidity!,
                    style: isDesktop
                        ? STextStyles.desktopTextExtraExtraSmall(context)
                        : STextStyles.itemSubtitle12(context),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: isDesktop ? 24 : 16),
          denominationSelector,
          SizedBox(height: isDesktop ? 16 : 12),
          quantityRow,
          SizedBox(height: isDesktop ? 16 : 12),
          termsCheckbox,
          SizedBox(height: isDesktop ? 16 : 12),
          Text(
            "Email for receipt and delivery",
            style: isDesktop
                ? STextStyles.desktopTextExtraExtraSmall(context)
                : STextStyles.itemSubtitle12(context),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
            child: TextField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() {}),
              style: isDesktop
                  ? STextStyles.desktopTextExtraSmall(context).copyWith(
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.textFieldActiveText,
                      height: 1.8,
                    )
                  : STextStyles.field(context).copyWith(
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.textFieldActiveText,
                    ),
              decoration:
                  standardInputDecoration(
                    "Email",
                    _emailFocusNode,
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
          PrimaryButton(
            label: _purchasing ? "Processing..." : "Purchase",
            enabled: _canPurchase,
            onPressed: _canPurchase ? _purchase : null,
          ),
        ],
      ),
    );

    return _scaffold(isDesktop: isDesktop, child: content);
  }

  Widget _scaffold({required bool isDesktop, required Widget child}) {
    return ConditionalParent(
      condition: isDesktop,
      builder: (child) => DesktopDialog(
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
                    "Gift Card",
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
                  vertical: 8,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
      child: ConditionalParent(
        condition: !isDesktop,
        builder: (child) => Background(
          child: Scaffold(
            backgroundColor: Theme.of(
              context,
            ).extension<StackColors>()!.background,
            appBar: AppBar(
              leading: AppBarBackButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text("Gift Card", style: STextStyles.navBarTitle(context)),
            ),
            body: SafeArea(
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}
