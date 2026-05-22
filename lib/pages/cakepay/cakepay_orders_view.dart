import 'package:flutter/material.dart';

import '../../services/cakepay/cakepay_service.dart';
import '../../services/cakepay/src/models/order.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/show_loading.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/dialogs/s_dialog.dart';
import '../../widgets/rounded_container.dart';
import 'cakepay_order_view.dart';

class CakePayOrdersView extends StatefulWidget {
  const CakePayOrdersView({super.key});

  static const String routeName = "/cakePayOrders";

  @override
  State<CakePayOrdersView> createState() => _CakePayOrdersViewState();
}

class _CakePayOrdersViewState extends State<CakePayOrdersView> {
  List<CakePayOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromApi());
  }

  Future<void> _syncFromApi() async {
    await showLoading(
      context: context,
      message: "Loading orders...",
      whileFutureAlt: _syncFromApiHelper,
      rootNavigator: Util.isDesktop,
    );
  }

  Future<void> _syncFromApiHelper() async {
    try {
      final orderIds = await CakePayService.instance.getOrderIds();
      final results = <CakePayOrder>[];

      for (final id in orderIds) {
        final resp = await CakePayService.instance.client.getOrder(id);
        if (!resp.hasError && resp.value != null) {
          results.add(resp.value!);
        }
      }

      if (mounted) {
        setState(() {
          _orders = results;
        });
      }
    } catch (_) {
      // Fall back to empty list — no local cache to fall back on
    }
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
                      "My Orders",
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
              title: Text("My Orders", style: STextStyles.navBarTitle(context)),
            ),
            body: SafeArea(
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            ),
          ),
        ),
        child: _orders.isEmpty
            ? Center(
                child: Text(
                  "No orders yet",
                  style: isDesktop
                      ? STextStyles.desktopTextSmall(context)
                      : STextStyles.itemSubtitle(context),
                ),
              )
            : ListView.separated(
                shrinkWrap: isDesktop,
                primary: isDesktop ? false : null,
                itemCount: _orders.length,
                padding: isDesktop ? const .only(bottom: 32, top: 16) : null,
                separatorBuilder: (_, __) =>
                    SizedBox(height: isDesktop ? 16 : 12),
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return RoundedContainer(
                    padding: .all(Util.isDesktop ? 16 : 12),
                    borderColor: Util.isDesktop
                        ? Theme.of(
                            context,
                          ).extension<StackColors>()!.textFieldDefaultBG
                        : null,
                    color: Theme.of(context).extension<StackColors>()!.popupBG,
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushNamed(CakePayOrderView.routeName, arguments: order);
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    order.orderId.length > 8
                                        ? "${order.orderId.substring(0, 8)}..."
                                        : order.orderId,
                                    style: isDesktop
                                        ? STextStyles.desktopTextSmall(context)
                                        : STextStyles.titleBold12(context),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: order.status
                                          .color(
                                            Theme.of(
                                              context,
                                            ).extension<StackColors>()!,
                                          )
                                          .withValues(alpha: 0.2),
                                    ),
                                    child: Text(
                                      order.status.label,
                                      style:
                                          (isDesktop
                                                  ? STextStyles.desktopTextExtraExtraSmall(
                                                      context,
                                                    )
                                                  : STextStyles.itemSubtitle12(
                                                      context,
                                                    ))
                                              .copyWith(
                                                color: order.status.color(
                                                  Theme.of(
                                                    context,
                                                  ).extension<StackColors>()!,
                                                ),
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                              if (order.amountUsd != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  "\$${order.amountUsd} USD",
                                  style: isDesktop
                                      ? STextStyles.desktopTextExtraExtraSmall(
                                          context,
                                        )
                                      : STextStyles.itemSubtitle12(
                                          context,
                                        ).copyWith(
                                          color: Theme.of(context)
                                              .extension<StackColors>()!
                                              .textSubtitle1,
                                        ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: isDesktop ? 16 : 8),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(
                            context,
                          ).extension<StackColors>()!.textSubtitle1,
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
