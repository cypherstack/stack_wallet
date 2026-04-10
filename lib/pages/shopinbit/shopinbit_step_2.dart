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
import '../exchange_view/sub_widgets/step_row.dart';
import 'shopinbit_step_3.dart';

class ShopInBitStep2 extends StatefulWidget {
  const ShopInBitStep2({super.key, required this.model});

  static const String routeName = "/shopInBitStep2";

  final ShopInBitOrderModel model;

  @override
  State<ShopInBitStep2> createState() => _ShopInBitStep2State();
}

class _ShopInBitStep2State extends State<ShopInBitStep2> {
  ShopInBitCategory? _selected;

  @override
  void initState() {
    super.initState();
    // Reset category selection.
    widget.model.category = null;
    _selected = null;
  }

  void _continue() {
    widget.model.category = _selected;
    if (Util.isDesktop) {
      Navigator.of(context, rootNavigator: true).pop();
      showDialog<void>(
        context: context,
        builder: (_) => ShopInBitStep3(model: widget.model),
      );
    } else {
      Navigator.of(
        context,
      ).pushNamed(ShopInBitStep3.routeName, arguments: widget.model);
    }
  }

  Widget _categoryCard({
    required ShopInBitCategory category,
    required String title,
    required String description,
    required String iconAsset,
    required bool isDesktop,
  }) {
    final isSelected = _selected == category;
    return GestureDetector(
      onTap: () => setState(() => _selected = category),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).extension<StackColors>()!.accentColorBlue
                : Theme.of(context).extension<StackColors>()!.background,
            width: 2,
          ),
          color: Theme.of(context).extension<StackColors>()!.popupBG,
        ),
        padding: EdgeInsets.all(isDesktop ? 20 : 16),
        child: Row(
          children: [
            Container(
              width: isDesktop ? 48 : 40,
              height: isDesktop ? 48 : 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .accentColorBlue
                    .withOpacity(0.1),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                iconAsset,
                width: isDesktop ? 24 : 20,
                height: isDesktop ? 24 : 20,
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .accentColorBlue,
              ),
            ),
            SizedBox(width: isDesktop ? 16 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: isDesktop
                        ? STextStyles.desktopTextSmall(context)
                        : STextStyles.titleBold12(context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: isDesktop
                        ? STextStyles.desktopTextExtraExtraSmall(context)
                        : STextStyles.itemSubtitle12(context).copyWith(
                            color: Theme.of(
                              context,
                            ).extension<StackColors>()!.textSubtitle1,
                          ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(
                  context,
                ).extension<StackColors>()!.accentColorBlue,
                size: isDesktop ? 24 : 20,
              ),
          ],
        ),
      ),
    );
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
            current: 1,
            width: MediaQuery.of(context).size.width - 32,
          ),
        if (!isDesktop) const SizedBox(height: 14),
        Text(
          "Choose a service",
          style: isDesktop
              ? STextStyles.desktopH2(context)
              : STextStyles.pageTitleH1(context),
        ),
        SizedBox(height: isDesktop ? 16 : 8),
        Text(
          "Select the type of service you need.",
          style: isDesktop
              ? STextStyles.desktopTextSmall(context)
              : STextStyles.itemSubtitle(context),
        ),
        SizedBox(height: isDesktop ? 32 : 24),
        _categoryCard(
          category: ShopInBitCategory.concierge,
          title: "Concierge",
          description: "Purchase products and services online.",
          iconAsset: Assets.svg.dollarSign,
          isDesktop: isDesktop,
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        _categoryCard(
          category: ShopInBitCategory.travel,
          title: "Travel",
          description: "Book flights, hotels, and more.",
          iconAsset: Assets.svg.circleArrowUpRight,
          isDesktop: isDesktop,
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        _categoryCard(
          category: ShopInBitCategory.car,
          title: "Car",
          description: "Find and purchase vehicles.",
          iconAsset: Assets.svg.boxAuto,
          isDesktop: isDesktop,
        ),
        const Spacer(),
        PrimaryButton(
          label: "Next",
          enabled: _selected != null,
          onPressed: _selected != null ? _continue : null,
        ),
      ],
    );

    if (isDesktop) {
      return DesktopDialog(
        maxWidth: 580,
        maxHeight: 580,
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
