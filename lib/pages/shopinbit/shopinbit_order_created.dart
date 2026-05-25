import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/dialogs/nested_navigator_dialog/nested_navigator_dialog.dart';
import '../../widgets/dialogs/s_dialog.dart';
import '../../widgets/rounded_white_container.dart';
import '../more_view/services_view.dart';
import 'shopinbit_ticket_detail.dart';

class ShopInBitOrderCreated extends StatelessWidget {
  const ShopInBitOrderCreated({super.key, required this.model});

  static const String routeName = "/shopInBitOrderCreated";

  final ShopInBitOrderModel model;

  static void _popToServices(BuildContext context) {
    Navigator.of(context).popUntil((route) {
      if (route.settings.name == ServicesView.routeName) {
        return true;
      }
      if (route.isFirst) {
        return true;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

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
                      "ShopinBit",
                      style: STextStyles.desktopH3(context),
                    ),
                  ),
                  DesktopDialogCloseButton(
                    onPressedOverride: () => NestedNavigatorDialog.of(
                      context,
                    ).close(args: const .noWarning()),
                  ),
                ],
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 32,
                    right: 32,
                    bottom: 32,
                    top: 16,
                  ),
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
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (bool didPop, dynamic result) {
              if (!didPop) {
                _popToServices(context);
              }
            },
            child: Scaffold(
              backgroundColor: Theme.of(
                context,
              ).extension<StackColors>()!.background,
              appBar: AppBar(
                leading: AppBarBackButton(
                  onPressed: () => _popToServices(context),
                ),
                title: Text(
                  "ShopinBit",
                  style: STextStyles.navBarTitle(context),
                ),
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
                          child: IntrinsicHeight(child: child),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isDesktop) const Spacer(),
            SvgPicture.asset(
              Assets.svg.checkCircle,
              width: isDesktop ? 64 : 48,
              height: isDesktop ? 64 : 48,
              color: Theme.of(
                context,
              ).extension<StackColors>()!.accentColorGreen,
            ),
            SizedBox(height: isDesktop ? 24 : 16),
            Text(
              "Request created!",
              style: isDesktop
                  ? STextStyles.desktopH2(context)
                  : STextStyles.pageTitleH1(context),
            ),
            SizedBox(height: isDesktop ? 16 : 8),
            Text(
              "Your request has been submitted.",
              style: isDesktop
                  ? STextStyles.desktopTextSmall(context)
                  : STextStyles.itemSubtitle(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isDesktop ? 32 : 24),
            RoundedWhiteContainer(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Request ID",
                        style: isDesktop
                            ? STextStyles.desktopTextExtraExtraSmall(context)
                            : STextStyles.itemSubtitle12(context),
                      ),
                      Text(
                        model.ticketId ?? "N/A",
                        style: isDesktop
                            ? STextStyles.desktopTextSmall(context)
                            : STextStyles.titleBold12(context),
                      ),
                    ],
                  ),
                  SizedBox(height: isDesktop ? 12 : 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Status",
                        style: isDesktop
                            ? STextStyles.desktopTextExtraExtraSmall(context)
                            : STextStyles.itemSubtitle12(context),
                      ),
                      Text(
                        "Pending review",
                        style: isDesktop
                            ? STextStyles.desktopTextSmall(context)
                            : STextStyles.titleBold12(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            isDesktop ? const SizedBox(height: 40) : const Spacer(),
            BranchedParent(
              condition: isDesktop,
              conditionBranchBuilder: (children) => Row(
                children: [
                  Expanded(child: children[2]),
                  children[1],
                  Expanded(child: children[0]),
                ],
              ),
              otherBranchBuilder: (children) => Column(
                crossAxisAlignment: .stretch,
                mainAxisSize: .min,
                children: children,
              ),
              children: [
                PrimaryButton(
                  label: "View request",
                  buttonHeight: isDesktop ? .l : null,
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      ShopInBitTicketDetail.routeName,
                      arguments: model,
                    );
                  },
                ),
                const SizedBox(height: 16, width: 24),
                SecondaryButton(
                  label: "Back to services",
                  buttonHeight: isDesktop ? .l : null,
                  onPressed: () {
                    if (Util.isDesktop) {
                      DesktopDialogCloseButton(
                        onPressedOverride: () => NestedNavigatorDialog.of(
                          context,
                        ).close(args: const .noWarning()),
                      );
                    } else {
                      _popToServices(context);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
