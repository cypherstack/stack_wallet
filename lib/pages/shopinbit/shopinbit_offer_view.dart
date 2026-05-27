import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../providers/global/shopin_bit_service_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/dialogs/s_dialog.dart';
import '../../widgets/rounded_white_container.dart';
import 'shopinbit_shipping_view.dart';

class ShopInBitOfferView extends ConsumerStatefulWidget {
  const ShopInBitOfferView({super.key, required this.model});

  static const String routeName = "/shopInBitOffer";

  final ShopInBitOrderModel model;

  @override
  ConsumerState<ShopInBitOfferView> createState() => _ShopInBitOfferViewState();
}

class _ShopInBitOfferViewState extends ConsumerState<ShopInBitOfferView> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.model.apiTicketId != 0) {
      _loadOffer();
    }
  }

  Future<void> _loadOffer() async {
    setState(() => _loading = true);
    try {
      final resp = await ref
          .read(pShopinBitService)
          .client
          .getTicketFull(widget.model.apiTicketId);
      if (!resp.hasError && resp.value != null) {
        final t = resp.value!;
        widget.model.setOffer(
          productName: t.productName,
          price: t.customerPrice,
        );
      }
    } catch (_) {
      // Fall back to local data
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final model = widget.model;

    final content = Column(
      mainAxisSize: .min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Review offer",
          style: isDesktop
              ? STextStyles.desktopH2(context)
              : STextStyles.pageTitleH1(context),
        ),
        SizedBox(height: isDesktop ? 16 : 8),
        Text(
          "ShopinBit has found a match for your request.",
          style: isDesktop
              ? STextStyles.desktopTextSmall(context)
              : STextStyles.itemSubtitle(context),
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        RoundedWhiteContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Product",
                style: isDesktop
                    ? STextStyles.desktopTextExtraExtraSmall(context)
                    : STextStyles.itemSubtitle12(context),
              ),
              const SizedBox(height: 4),
              Text(
                model.offerProductName ?? (_loading ? "Loading..." : "N/A"),
                style: isDesktop
                    ? STextStyles.desktopTextSmall(context)
                    : STextStyles.titleBold12(context),
              ),
            ],
          ),
        ),
        SizedBox(height: isDesktop ? 12 : 8),
        RoundedWhiteContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Price (incl. service fee)",
                style: isDesktop
                    ? STextStyles.desktopTextExtraExtraSmall(context)
                    : STextStyles.itemSubtitle12(context),
              ),
              const SizedBox(height: 4),
              Text(
                _loading && model.offerPrice == null
                    ? "Loading..."
                    : "${model.offerPrice ?? '0'} EUR",
                style: isDesktop
                    ? STextStyles.desktopTextSmall(context)
                    : STextStyles.titleBold12(context),
              ),
            ],
          ),
        ),
        isDesktop ? const SizedBox(height: 40) : const Spacer(),
        BranchedParent(
          condition: isDesktop,
          conditionBranchBuilder: (children) => Row(
            children: [
              Expanded(child: children[1]),
              const SizedBox(width: 16),
              Expanded(child: children[0]),
            ],
          ),
          otherBranchBuilder: (children) => Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [children[0], const SizedBox(height: 16), children[1]],
          ),
          children: [
            PrimaryButton(
              label: "Accept offer",
              buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
              enabled: !_loading,
              onPressed: () {
                // TODO verify this is ok to stay set to accepted if the next route pops back and then decline is tapped
                model.status = ShopInBitOrderStatus.accepted;

                Navigator.of(
                  context,
                ).pushNamed(ShopInBitShippingView.routeName, arguments: model);
              },
            ),
            SecondaryButton(
              label: "Decline",
              buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ],
    );

    if (isDesktop) {
      return SDialog(
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
                  const DesktopDialogCloseButton(),
                ],
              ),
              Flexible(
                child: Padding(
                  padding: const .only(
                    left: 32,
                    right: 32,
                    bottom: 32,
                    top: 16,
                  ),
                  child: content,
                ),
              ),
            ],
          ),
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
