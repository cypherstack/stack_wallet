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
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rounded_white_container.dart';
import 'shopinbit_shipping_view.dart';

class ShopInBitOfferView extends StatefulWidget {
  const ShopInBitOfferView({super.key, required this.model});

  static const String routeName = "/shopInBitOffer";

  final ShopInBitOrderModel model;

  @override
  State<ShopInBitOfferView> createState() => _ShopInBitOfferViewState();
}

class _ShopInBitOfferViewState extends State<ShopInBitOfferView> {
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
      final resp = await ShopInBitService.instance.client.getTicketFull(
        widget.model.apiTicketId,
      );
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
        const Spacer(),
        PrimaryButton(
          label: "Accept offer",
          enabled: !_loading,
          onPressed: () {
            model.status = ShopInBitOrderStatus.accepted;
            if (isDesktop) {
              Navigator.of(context, rootNavigator: true).pop();
              showDialog<void>(
                context: context,
                builder: (_) => ShopInBitShippingView(model: model),
              );
            } else {
              Navigator.of(
                context,
              ).pushNamed(ShopInBitShippingView.routeName, arguments: model);
            }
          },
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        SecondaryButton(
          label: "Decline",
          onPressed: () {
            if (isDesktop) {
              Navigator.of(context, rootNavigator: true).pop();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );

    if (isDesktop) {
      return DesktopDialog(
        maxWidth: 580,
        maxHeight: 600,
        child: Column(
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                child: Stack(
                  children: [
                    content,
                    if (_loading) const LoadingIndicator(width: 24, height: 24),
                  ],
                ),
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
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 32,
                        ),
                        child: IntrinsicHeight(child: content),
                      ),
                    ),
                  ),
                  if (_loading) const LoadingIndicator(width: 24, height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
