import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/rounded_white_container.dart';
import 'shopinbit_ticket_detail.dart';

class ShopInBitOrderCreated extends StatelessWidget {
  const ShopInBitOrderCreated({super.key, required this.model});

  static const String routeName = "/shopInBitOrderCreated";

  final ShopInBitOrderModel model;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        SvgPicture.asset(
          Assets.svg.checkCircle,
          width: isDesktop ? 64 : 48,
          height: isDesktop ? 64 : 48,
          color: Theme.of(context).extension<StackColors>()!.accentColorGreen,
        ),
        SizedBox(height: isDesktop ? 24 : 16),
        Text(
          "Order created!",
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
                    "Ticket ID",
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
        const Spacer(),
        PrimaryButton(
          label: "View ticket",
          onPressed: () {
            if (Util.isDesktop) {
              Navigator.of(context, rootNavigator: true).pop();
              showDialog<void>(
                context: context,

                builder: (_) => ShopInBitTicketDetail(model: model),
              );
            } else {
              Navigator.of(
                context,
              ).pushNamed(ShopInBitTicketDetail.routeName, arguments: model);
            }
          },
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        SecondaryButton(
          label: "Back to services",
          onPressed: () {
            if (Util.isDesktop) {
              Navigator.of(context, rootNavigator: true).pop();
            } else {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
        ),
      ],
    );

    if (isDesktop) {
      return DesktopDialog(
        maxWidth: 580,
        maxHeight: 550,
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
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () => Navigator.of(context).pop(),
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
    );
  }
}
