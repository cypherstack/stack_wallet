import 'package:flutter/material.dart';

import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../services/shopinbit/shopinbit_service.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/rounded_white_container.dart';
import '../exchange_view/sub_widgets/step_row.dart';
import 'shopinbit_step_2.dart';
import 'shopinbit_step_4.dart';

class ShopInBitStep3 extends StatefulWidget {
  const ShopInBitStep3({super.key, required this.model});

  static const String routeName = "/shopInBitStep3";

  final ShopInBitOrderModel model;

  @override
  State<ShopInBitStep3> createState() => _ShopInBitStep3State();
}

class _ShopInBitStep3State extends State<ShopInBitStep3> {
  bool _agreed = false;

  String _guidelinesText() {
    switch (widget.model.category) {
      case ShopInBitCategory.concierge:
        return "Concierge Service Guidelines:\n\n"
            "\u2022 Minimum: fee of 100 EUR or minimum order "
            "value of 1,000 EUR.\n\n"
            "\u2022 Service Fee: 10% of the order total.\n\n"
            "\u2022 Only legal products and services are allowed.\n\n"
            "\u2022 Prohibited: precious metals, prescription "
            "medicine, live animals, weapons, adult "
            "entertainment, EU real estate.\n\n"
            "\u2022 Provide a clear and detailed description of the "
            "product or service you want to purchase.\n\n"
            "\u2022 Include links to the exact item when possible.";
      case ShopInBitCategory.travel:
        return "Travel Service Guidelines:\n\n"
            "\u2022 Recommended budget: 2,500 EUR and above "
            "for custom trips.\n\n"
            "\u2022 Minimum: fee of 100 EUR or booking value "
            "of 1,000 EUR.\n\n"
            "\u2022 Service Fee: 10% of the booking amount.\n\n"
            "\u2022 Only legal travel services are allowed.\n\n"
            "\u2022 Prohibited: sanctioned destinations, illegal "
            "bookings, adult entertainment, real estate "
            "disguised as travel.\n\n"
            "\u2022 Provide full details of your travel request "
            "including dates, destinations, and preferences.";
      case ShopInBitCategory.car:
        return "Car Service Guidelines:\n\n"
            "\u2022 Minimum Order: \u20AC20,000.\n\n"
            "\u2022 Research Fee: \u20AC223 (incl. VAT) \u2014 "
            "one-time, credited toward purchase.\n\n"
            "\u2022 Service Fee: 10% of the vehicle value.\n\n"
            "\u2022 Only legal vehicle transactions are allowed.\n\n"
            "\u2022 Prohibited: export to sanctioned regions, "
            "armored/military vehicles without licensing, "
            "weapons/tactical accessories, real estate "
            "disguised as vehicle purchases.\n\n"
            "\u2022 Provide details about the make, model, year, "
            "and any specific requirements.";
      case null:
        return "";
    }
  }

  void _popBack() {
    if (Util.isDesktop) {
      Navigator.of(context, rootNavigator: true).pop();
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ShopInBitStep2(model: widget.model),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _continue() {
    widget.model.guidelinesAccepted = true;
    // Persist acceptance.
    ShopInBitService.instance.setGuidelinesAccepted(true);
    if (Util.isDesktop) {
      Navigator.of(context, rootNavigator: true).pop();
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ShopInBitStep4(model: widget.model),
      );
    } else {
      Navigator.of(
        context,
      ).pushNamed(ShopInBitStep4.routeName, arguments: widget.model);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isDesktop)
          StepRow(
            count: 4,
            current: 2,
            width: MediaQuery.of(context).size.width - 32,
          ),
        if (!isDesktop) const SizedBox(height: 14),
        Text(
          "Service guidelines",
          style: isDesktop
              ? STextStyles.desktopH2(context)
              : STextStyles.pageTitleH1(context),
        ),
        SizedBox(height: isDesktop ? 16 : 8),
        Text(
          "Please read the following carefully before continuing.",
          style: isDesktop
              ? STextStyles.desktopTextSmall(context)
              : STextStyles.itemSubtitle(context),
        ),
        SizedBox(height: isDesktop ? 24 : 16),
        Flexible(
          child: RoundedWhiteContainer(
            child: SingleChildScrollView(
              child: Text(
                _guidelinesText(),
                style: isDesktop
                    ? STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                        color: Theme.of(
                          context,
                        ).extension<StackColors>()!.textDark,
                      )
                    : STextStyles.itemSubtitle12(context),
              ),
            ),
          ),
        ),
        CheckboxListTile(
          value: _agreed,
          onChanged: (v) => setState(() => _agreed = v ?? false),
          title: Text(
            "I have read and agree to the Service Guidelines",
            style: isDesktop
                ? STextStyles.desktopTextExtraExtraSmall(context)
                : STextStyles.itemSubtitle12(context),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: Theme.of(
            context,
          ).extension<StackColors>()!.accentColorBlue,
        ),
        SizedBox(height: isDesktop ? 24 : 16),
        PrimaryButton(
          label: "Next",
          enabled: _agreed,
          onPressed: _agreed ? _continue : null,
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
                Row(
                  children: [
                    AppBarBackButton(
                      isCompact: true,
                      iconSize: 23,
                      onPressed: _popBack,
                    ),
                    Text("ShopinBit", style: STextStyles.desktopH3(context)),
                  ],
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
    );
  }
}
