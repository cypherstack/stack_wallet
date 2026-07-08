import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/global/shopin_bit_service_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/logger.dart';
import '../../utilities/show_loading.dart';
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
import '../../widgets/stack_dialog.dart';
import 'shopinbit_shipping_view.dart';

class ShopInBitOfferView extends ConsumerStatefulWidget {
  const ShopInBitOfferView({super.key, required this.apiTicketId});

  static const String routeName = "/shopInBitOffer";

  final int apiTicketId;

  @override
  ConsumerState<ShopInBitOfferView> createState() => _ShopInBitOfferViewState();
}

class _ShopInBitOfferViewState extends ConsumerState<ShopInBitOfferView> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.apiTicketId != 0) {
      _loadOffer();
    }
  }

  Future<void> _loadOffer() async {
    setState(() => _loading = true);
    try {
      // Refresh pulls /full (offer product + price) into the ticket row, which
      // we then read reactively from the DB stream.
      await ref.read(pShopinBitService).refreshOne(widget.apiTicketId);
    } catch (e, s) {
      Logging.instance.w(
        "Failed to refresh ShopInBit offer ${widget.apiTicketId}, "
        "using cached data",
        error: e,
        stackTrace: s,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final ticket = ref
        .watch(pShopInBitTicket(widget.apiTicketId))
        .asData
        ?.value;

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
                ticket?.offerProductName ?? (_loading ? "Loading..." : "N/A"),
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
                "Price (incl. service fee and VAT)",
                style: isDesktop
                    ? STextStyles.desktopTextExtraExtraSmall(context)
                    : STextStyles.itemSubtitle12(context),
              ),
              const SizedBox(height: 4),
              Text(
                _loading && ticket?.offerPrice == null
                    ? "Loading..."
                    : "${ticket?.offerPrice ?? '0'} EUR",
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
              onPressed: () async {
                final deliveryCountry = ticket?.deliveryCountry ?? "";

                final shopinBitApi = ref.read(pShopinBitService).client;
                final response = await showLoading(
                  context: context,
                  rootNavigator: true,
                  message: "Updating available countries",
                  whileFuture: shopinBitApi.getCountries(),
                  delay: const Duration(
                    seconds: 1,
                  ), // at least 1 sec to prevent ui flashing
                );

                if (!context.mounted) return;

                String? errorMessage;

                if (response?.value == null) {
                  errorMessage =
                      response?.exception?.toString() ??
                      "Failed to fetch countries data";
                } else if (response!.value!
                        .where((c) => c['iso'] == deliveryCountry)
                        .length !=
                    1) {
                  errorMessage =
                      "Delivery country code \""
                      "$deliveryCountry"
                      "\" is invalid";
                }

                if (errorMessage != null) {
                  await showDialog<dynamic>(
                    context: context,
                    useRootNavigator: Util.isDesktop,
                    builder: (context) => StackOkDialog(
                      title: "ShopinBit API error",
                      maxWidth: Util.isDesktop ? 500 : null,
                      message: errorMessage,
                      desktopPopRootNavigator: Util.isDesktop,
                    ),
                  );
                  return;
                }

                if (context.mounted) {
                  await Navigator.of(context).pushNamed(
                    ShopInBitShippingView.routeName,
                    arguments: (ticket: ticket!, countries: response!.value!),
                  );
                }
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
