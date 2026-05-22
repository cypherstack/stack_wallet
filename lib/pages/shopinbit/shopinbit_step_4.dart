import "package:flutter/material.dart";

import "../../models/shopinbit/shopinbit_order_model.dart";
import "../../themes/stack_colors.dart";
import "../../utilities/text_styles.dart";
import "../../utilities/util.dart";
import "../../widgets/background.dart";
import "../../widgets/conditional_parent.dart";
import "../../widgets/custom_buttons/app_bar_icon_button.dart";
import "../../widgets/desktop/desktop_dialog.dart";
import "../../widgets/desktop/desktop_dialog_close_button.dart";
import "../../widgets/dialogs/nested_navigator_dialog/nested_navigator_dialog.dart";
import "step_4_components/shopinbit_car_research_form.dart";
import "step_4_components/shopinbit_concierge_form.dart";
import "step_4_components/shopinbit_generic_form.dart";
import "step_4_components/shopinbit_travel_form.dart";

class ShopInBitStep4 extends StatelessWidget {
  const ShopInBitStep4({super.key, required this.model});

  static const String routeName = "/shopInBitStep4";

  final ShopInBitOrderModel model;

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: Util.isDesktop,
      builder: (child) => _ShopInBitStep4DesktopShell(content: child),
      child: ConditionalParent(
        condition: !Util.isDesktop,
        builder: (child) => _ShopInBitStep4MobileShell(content: child),
        child: switch (model.category) {
          ShopInBitCategory.concierge => ShopInBitConciergeForm(model: model),
          ShopInBitCategory.car => ShopInBitCarResearchForm(model: model),
          ShopInBitCategory.travel => ShopInBitTravelForm(model: model),
          null => ShopInBitGenericForm(model: model),
        },
      ),
    );
  }
}

class _ShopInBitStep4DesktopShell extends StatelessWidget {
  const _ShopInBitStep4DesktopShell({required this.content});

  final Widget content;

  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      maxWidth: 580,
      maxHeight: 750,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const AppBarBackButton(isCompact: true, iconSize: 23),
                  Text("ShopinBit", style: STextStyles.desktopH3(context)),
                ],
              ),
              DesktopDialogCloseButton(
                onPressedOverride: () =>
                    confirmCloseNestedNavigatorDialog(context),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: SingleChildScrollView(child: content),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopInBitStep4MobileShell extends StatelessWidget {
  const _ShopInBitStep4MobileShell({required this.content});

  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: const AppBarBackButton(),
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
