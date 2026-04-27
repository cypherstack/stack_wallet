import 'package:flutter/material.dart';

import '../../services/cakepay/cakepay_service.dart';
import '../../services/cakepay/src/models/order.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/rounded_white_container.dart';
import 'cakepay_order_view.dart';

class CakePayOrdersView extends StatefulWidget {
  const CakePayOrdersView({super.key});

  static const String routeName = "/cakePayOrders";

  @override
  State<CakePayOrdersView> createState() => _CakePayOrdersViewState();
}

class _CakePayOrdersViewState extends State<CakePayOrdersView> {
  List<CakePayOrder> _orders = [];
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _syncFromApi();
  }

  /// Fetch each locally-tracked order ID individually via getOrder()
  /// (which works with the seller API key, unlike getMyOrders()).
  /// Mirrors ShopInBit's _syncFromApi() pattern.
  Future<void> _syncFromApi() async {
    setState(() => _syncing = true);
    try {
      final orderIds = CakePayService.instance.getOrderIds();
      final results = <CakePayOrder>[];

      for (final id in orderIds) {
        final resp = await CakePayService.instance.client.getOrder(id);
        if (!resp.hasError && resp.value != null) {
          var order = resp.value!;
          final override = CakePayService.devStatusOverrides[order.orderId];
          if (override != null) {
            order = order.copyWith(status: override);
          }
          results.add(order);
        }
      }

      if (mounted) {
        setState(() {
          _orders = results;
        });
      }
    } catch (_) {
      // Fall back to empty list — no local cache to fall back on
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  String _statusLabel(CakePayOrderStatus status) {
    switch (status) {
      case CakePayOrderStatus.new_:
        return "New";
      case CakePayOrderStatus.expiredButStillPending:
        return "Expired (pending)";
      case CakePayOrderStatus.expired:
        return "Expired";
      case CakePayOrderStatus.failed:
        return "Failed";
      case CakePayOrderStatus.paid:
        return "Paid";
      case CakePayOrderStatus.paidPartial:
        return "Partially paid";
      case CakePayOrderStatus.pendingPurchase:
        return "Pending purchase";
      case CakePayOrderStatus.purchaseProcessing:
        return "Processing";
      case CakePayOrderStatus.purchased:
        return "Purchased";
      case CakePayOrderStatus.pendingEmail:
        return "Pending email";
      case CakePayOrderStatus.complete:
        return "Complete";
      case CakePayOrderStatus.pendingRefund:
        return "Pending refund";
      case CakePayOrderStatus.refunded:
        return "Refunded";
    }
  }

  Color _statusColor(BuildContext context, CakePayOrderStatus status) {
    final colors = Theme.of(context).extension<StackColors>()!;
    switch (status) {
      case CakePayOrderStatus.complete:
      case CakePayOrderStatus.purchased:
        return colors.accentColorGreen;
      case CakePayOrderStatus.new_:
      case CakePayOrderStatus.paid:
      case CakePayOrderStatus.paidPartial:
        return colors.accentColorBlue;
      case CakePayOrderStatus.pendingPurchase:
      case CakePayOrderStatus.purchaseProcessing:
      case CakePayOrderStatus.pendingEmail:
      case CakePayOrderStatus.expiredButStillPending:
        return colors.accentColorYellow;
      case CakePayOrderStatus.expired:
      case CakePayOrderStatus.failed:
      case CakePayOrderStatus.pendingRefund:
      case CakePayOrderStatus.refunded:
        return colors.textSubtitle1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    final list = _orders.isEmpty
        ? Center(
            child: Text(
              _syncing ? "Loading orders..." : "No orders yet",
              style: isDesktop
                  ? STextStyles.desktopTextSmall(context)
                  : STextStyles.itemSubtitle(context),
            ),
          )
        : ListView.separated(
            shrinkWrap: isDesktop,
            primary: isDesktop ? false : null,
            itemCount: _orders.length,
            separatorBuilder: (_, __) => SizedBox(height: isDesktop ? 16 : 12),
            itemBuilder: (context, index) {
              final order = _orders[index];
              return GestureDetector(
                onTap: () {
                  if (isDesktop) {
                    Navigator.of(context, rootNavigator: true).pop();
                    showDialog<void>(
                      context: context,
                      builder: (_) => CakePayOrderView(orderId: order.orderId),
                    );
                  } else {
                    Navigator.of(context).pushNamed(
                      CakePayOrderView.routeName,
                      arguments: order.orderId,
                    );
                  }
                },
                child: RoundedWhiteContainer(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    color: _statusColor(
                                      context,
                                      order.status,
                                    ).withValues(alpha: 0.2),
                                  ),
                                  child: Text(
                                    _statusLabel(order.status),
                                    style:
                                        (isDesktop
                                                ? STextStyles.desktopTextExtraExtraSmall(
                                                    context,
                                                  )
                                                : STextStyles.itemSubtitle12(
                                                    context,
                                                  ))
                                            .copyWith(
                                              color: _statusColor(
                                                context,
                                                order.status,
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
                ),
              );
            },
          );

    final content = Stack(
      children: [
        list,
        if (_syncing)
          const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );

    return ConditionalParent(
      condition: isDesktop,
      builder: (child) => DesktopDialog(
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
                    "My Orders",
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
                child: child,
              ),
            ),
          ],
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
        child: content,
      ),
    );
  }
}
