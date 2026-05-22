import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../providers/providers.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/dialogs/s_dialog.dart';
import '../../widgets/rounded_container.dart';
import '../exchange_view/sub_widgets/step_row.dart';
import 'shopinbit_step_3.dart';
import 'shopinbit_step_4.dart';

class ShopInBitStep2 extends ConsumerStatefulWidget {
  const ShopInBitStep2({super.key, required this.model});

  static const String routeName = "/shopInBitStep2";

  final ShopInBitOrderModel model;

  @override
  ConsumerState<ShopInBitStep2> createState() => _ShopInBitStep2State();
}

class _ShopInBitStep2State extends ConsumerState<ShopInBitStep2> {
  ShopInBitCategory? _selected;

  Future<void> _continue() async {
    widget.model.category = _selected;
    final skipGuidelines =
        (await ref.read(pSharedDrift).shopinBitSettingsDao.getSettings())
            .guidelinesAccepted;
    if (!mounted) return;

    if (skipGuidelines) {
      widget.model.guidelinesAccepted = true;
      await Navigator.of(
        context,
      ).pushNamed(ShopInBitStep4.routeName, arguments: widget.model);
    } else {
      await Navigator.of(
        context,
      ).pushNamed(ShopInBitStep3.routeName, arguments: widget.model);
    }
  }

  @override
  void initState() {
    super.initState();
    // Reset category selection.
    widget.model.category = null;
    _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    return ConditionalParent(
      condition: isDesktop,
      builder: (content) => SDialog(
        child: SizedBox(
          width: 580,
          child: Column(
            mainAxisSize: .min,
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
                  const DesktopDialogCloseButton(),
                ],
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: content,
                ),
              ),
            ],
          ),
        ),
      ),
      child: ConditionalParent(
        condition: !isDesktop,
        builder: (content) => Background(
          child: Scaffold(
            backgroundColor: Theme.of(
              context,
            ).extension<StackColors>()!.background,
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isDesktop)
              StepRow(
                count: 4,
                current: 1,
                width: MediaQuery.of(context).size.width - 32,
              ),
            const SizedBox(height: 14),
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
            _CategoryCard(
              category: .concierge,
              title: "Concierge",
              description: "Purchase products and services online.",
              iconAsset: Assets.svg.dollarSign,
              isSelected: _selected == .concierge,
              onTap: (value) => setState(() => _selected = value),
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            _CategoryCard(
              category: .travel,
              title: "Travel",
              description: "Book flights, hotels, and more.",
              iconAsset: Assets.svg.circleArrowUpRight,
              isSelected: _selected == .travel,
              onTap: (value) => setState(() => _selected = value),
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            _CategoryCard(
              category: .car,
              title: "Car",
              description: "Find and purchase vehicles.",
              iconAsset: Assets.svg.boxAuto,
              isSelected: _selected == .car,
              onTap: (value) => setState(() => _selected = value),
            ),
            isDesktop ? const SizedBox(height: 32) : const Spacer(),
            PrimaryButton(
              label: "Next",
              enabled: _selected != null,
              onPressed: _selected != null ? _continue : null,
            ),
            if (isDesktop) const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    super.key,
    required this.category,
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.isSelected,
    required this.onTap,
  });

  final ShopInBitCategory category;
  final String title;
  final String description;
  final String iconAsset;
  final bool isSelected;
  final ValueChanged<ShopInBitCategory> onTap;

  @override
  Widget build(BuildContext context) {
    final StackColors colors = Theme.of(context).extension<StackColors>()!;
    final isDesktop = Util.isDesktop;

    return RoundedContainer(
      color: colors.popupBG,
      borderColor: colors.textFieldDefaultBG,
      onPressed: () => onTap(category),
      child: Row(
        children: [
          Container(
            width: isDesktop ? 48 : 40,
            height: isDesktop ? 48 : 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.textDark.withOpacity(0.1),
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              iconAsset,
              width: isDesktop ? 24 : 20,
              height: isDesktop ? 24 : 20,
              color: colors.textDark,
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
                      : STextStyles.itemSubtitle12(
                          context,
                        ).copyWith(color: colors.textSubtitle1),
                ),
              ],
            ),
          ),
          if (isSelected)
            SvgPicture.asset(
              Assets.svg.checkCircle,
              width: isDesktop ? 24 : 20,
              height: isDesktop ? 24 : 20,
              colorFilter: ColorFilter.mode(colors.textDark, .srcIn),
            ),
        ],
      ),
    );
  }
}
