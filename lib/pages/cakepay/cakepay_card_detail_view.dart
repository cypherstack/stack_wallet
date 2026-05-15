import 'package:decimal/decimal.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/cakepay/cakepay_service.dart';
import '../../services/cakepay/src/models/card.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/dialogs/s_dialog.dart';
import '../../widgets/icon_widgets/credit_card_icon.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_dialog.dart';
import '../../widgets/textfields/adaptive_text_field.dart';
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
  Decimal? _selectedDenomination;
  int _quantity = 1;
  bool _termsAccepted = false;
  final _customAmountController = TextEditingController();
  final _emailController = TextEditingController();

  bool _canPurchase = false;

  void _updateCanPurchase() {
    if (mounted) {
      final check = _checkCanPurchase();
      if (check != _canPurchase) {
        setState(() => _canPurchase = check);
      }
    }
  }

  String get _priceString {
    if (_card.isFixedDenomination && _selectedDenomination != null) {
      return _selectedDenomination!.toStringAsFixed(2);
    }
    return _customAmountController.text.trim();
  }

  bool _checkCanPurchase() {
    if (!_termsAccepted || _purchasing) return false;
    if (_emailController.text.trim().isEmpty) return false;
    final price = _priceString;
    if (price.isEmpty) return false;
    final parsed = Decimal.tryParse(price);
    if (parsed == null || parsed <= Decimal.zero) return false;
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
    if (!_checkCanPurchase()) return;
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

        await CakePayService.instance.addOrderId(order.orderId);

        if (mounted) {
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
        }
      } else {
        final String errorMessage;
        if (resp.exception != null) {
          final ex = resp.exception!;
          final body = ex.responseBody;
          errorMessage = "${ex.message}${body != null ? "\n$body" : ""}";
        } else {
          errorMessage = "Failed to create order";
        }
        await showDialog<dynamic>(
          context: context,
          useSafeArea: false,
          barrierDismissible: true,
          builder: (context) {
            return StackOkDialog(
              title: "Purchase failed",
              message: errorMessage,
              maxWidth: Util.isDesktop ? 580 : null,
              desktopPopRootNavigator: Util.isDesktop,
            );
          },
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _card = widget.card;
    if (_card.isFixedDenomination && _card.denominations.isNotEmpty) {
      _selectedDenomination = _card.denominations.first;
    }
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final card = _card;

    return ConditionalParent(
      condition: isDesktop,
      builder: (child) => SDialog(
        child: SizedBox(
          width: 580,
          child: Column(
            mainAxisSize: .min,
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
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: child,
                ),
              ),
            ],
          ),
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
              child: Padding(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                child: SingleChildScrollView(child: child),
              ),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: .min,
          children: [
            if (card.cardImageUrl != null)
              _CardImage(imageUrl: card.cardImageUrl!, isDesktop: isDesktop),
            SizedBox(height: isDesktop ? 24 : 16),
            Text(
              card.name,
              style: isDesktop
                  ? STextStyles.desktopH2(context)
                  : STextStyles.pageTitleH1(context),
            ),
            if (card.description != null && card.description!.isNotEmpty) ...[
              SizedBox(height: isDesktop ? 16 : 12),
              _PlainInfoBlock(text: card.description!, isDesktop: isDesktop),
            ],
            if (card.howToUse != null && card.howToUse!.isNotEmpty) ...[
              SizedBox(height: isDesktop ? 16 : 12),
              _TitledInfoBlock(
                title: "How to use",
                body: card.howToUse!,
                isDesktop: isDesktop,
              ),
            ],
            if (card.termsAndConditions != null &&
                card.termsAndConditions!.isNotEmpty) ...[
              SizedBox(height: isDesktop ? 16 : 12),
              _TitledInfoBlock(
                title: "Terms & conditions",
                body: card.termsAndConditions!,
                isDesktop: isDesktop,
              ),
            ],
            if (card.expiryAndValidity != null &&
                card.expiryAndValidity!.isNotEmpty) ...[
              SizedBox(height: isDesktop ? 16 : 12),
              _TitledInfoBlock(
                title: "Expiry & validity",
                body: card.expiryAndValidity!,
                isDesktop: isDesktop,
              ),
            ],
            SizedBox(height: isDesktop ? 24 : 16),
            _DenominationSelector(
              card: card,
              isDesktop: isDesktop,
              selectedDenomination: _selectedDenomination,
              customAmountController: _customAmountController,
              onDenominationSelected: (Decimal d) {
                setState(() => _selectedDenomination = d);
                _updateCanPurchase();
              },
              onCustomAmountChanged: _updateCanPurchase,
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            _QuantityRow(
              isDesktop: isDesktop,
              quantity: _quantity,
              onDecrement: _quantity > 1
                  ? () => setState(() => _quantity--)
                  : null,
              onIncrement: () => setState(() => _quantity++),
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            _TermsCheckbox(
              isDesktop: isDesktop,
              accepted: _termsAccepted,
              onToggle: () {
                setState(() => _termsAccepted = !_termsAccepted);
                _updateCanPurchase();
              },
              onOpenTerms: _openTerms,
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            Text(
              "Email for receipt and delivery",
              style: isDesktop
                  ? STextStyles.desktopTextExtraExtraSmall(context)
                  : STextStyles.itemSubtitle12(context),
            ),
            const SizedBox(height: 8),
            AdaptiveTextField(
              labelText: "Email",
              controller: _emailController,
              showPasteClearButton: true,
              keyboardType: .emailAddress,
              onChangedComprehensive: (_) => _updateCanPurchase(),
            ),
            SizedBox(height: isDesktop ? 24 : 16),
            PrimaryButton(
              label: _purchasing ? "Processing..." : "Purchase",
              enabled: _canPurchase,
              onPressed: _canPurchase ? _purchase : null,
            ),
            SizedBox(height: isDesktop ? 32 : 16),
          ],
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  const _CardImage({required this.imageUrl, required this.isDesktop});

  final String imageUrl;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: isDesktop ? 200 : 150,
          fit: BoxFit.contain,
          errorBuilder: (BuildContext _, Object __, StackTrace? ___) =>
              CreditCardIcon(
                width: isDesktop ? 80 : 60,
                height: isDesktop ? 80 : 60,
              ),
        ),
      ),
    );
  }
}

class _PlainInfoBlock extends StatelessWidget {
  const _PlainInfoBlock({required this.text, required this.isDesktop});

  final String text;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      child: Text(
        text,
        style: isDesktop
            ? STextStyles.desktopTextExtraExtraSmall(context)
            : STextStyles.itemSubtitle12(context),
      ),
    );
  }
}

class _TitledInfoBlock extends StatelessWidget {
  const _TitledInfoBlock({
    required this.title,
    required this.body,
    required this.isDesktop,
  });

  final String title;
  final String body;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: isDesktop
                ? STextStyles.desktopTextSmall(context)
                : STextStyles.titleBold12(context),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: isDesktop
                ? STextStyles.desktopTextExtraExtraSmall(context)
                : STextStyles.itemSubtitle12(context),
          ),
        ],
      ),
    );
  }
}

class _DenominationSelector extends StatelessWidget {
  const _DenominationSelector({
    required this.card,
    required this.isDesktop,
    required this.selectedDenomination,
    required this.customAmountController,
    required this.onDenominationSelected,
    required this.onCustomAmountChanged,
  });

  final CakePayCard card;
  final bool isDesktop;
  final Decimal? selectedDenomination;
  final TextEditingController customAmountController;
  final ValueChanged<Decimal> onDenominationSelected;
  final VoidCallback onCustomAmountChanged;

  @override
  Widget build(BuildContext context) {
    if (card.isFixedDenomination) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: card.denominations.map((d) {
          final bool selected = d == selectedDenomination;
          return ChoiceChip(
            label: Text(
              "${d.toStringAsFixed(2)} ${card.currencyCode ?? ''}",
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
            onSelected: (bool val) {
              if (val) onDenominationSelected(d);
            },
          );
        }).toList(),
      );
    }

    if (card.isRangeDenomination) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: .min,
        children: [
          Text(
            "Enter amount (${card.minValue?.toStringAsFixed(2) ?? '?'} - "
            "${card.maxValue?.toStringAsFixed(2) ?? '?'} "
            "${card.currencyCode ?? ''})",
            style: isDesktop
                ? STextStyles.desktopTextExtraExtraSmall(context)
                : STextStyles.itemSubtitle12(context),
          ),
          const SizedBox(height: 8),
          AdaptiveTextField(
            labelText: "Amount",
            controller: customAmountController,
            keyboardType: const .numberWithOptions(decimal: true),
            onChangedComprehensive: (_) => onCustomAmountChanged(),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _QuantityRow extends StatelessWidget {
  const _QuantityRow({
    required this.isDesktop,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final bool isDesktop;
  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
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
          onPressed: onDecrement,
        ),
        Text(
          "$quantity",
          style: isDesktop
              ? STextStyles.desktopTextSmall(context)
              : STextStyles.titleBold12(context),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          onPressed: onIncrement,
        ),
      ],
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.isDesktop,
    required this.accepted,
    required this.onToggle,
    required this.onOpenTerms,
  });

  final bool isDesktop;
  final bool accepted;
  final VoidCallback onToggle;
  final VoidCallback onOpenTerms;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
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
                  value: accepted,
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
                      recognizer: TapGestureRecognizer()..onTap = onOpenTerms,
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
  }
}
