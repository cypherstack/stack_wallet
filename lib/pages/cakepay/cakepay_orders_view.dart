import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/global/cakepay_orders_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/dialogs/s_dialog.dart';
import '../../widgets/refresh_control.dart';
import '../../widgets/rounded_container.dart';
import 'cakepay_order_view.dart';

class CakePayOrdersView extends ConsumerStatefulWidget {
  const CakePayOrdersView({super.key});

  static const String routeName = "/cakePayOrders";

  @override
  ConsumerState<CakePayOrdersView> createState() => _CakePayOrdersViewState();
}

class _CakePayOrdersViewState extends ConsumerState<CakePayOrdersView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pCakePayOrdersService).refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final service = ref.watch(pCakePayOrdersService);
    final orders = service.all;
    final isRefreshing = service.isRefreshingAll;

    final orderItems = <Widget>[];
    if (orders.isEmpty) {
      orderItems.add(const SizedBox(height: 80));
      orderItems.add(
        Center(
          child: Text(
            isRefreshing ? "Loading orders..." : "No orders yet",
            style: isDesktop
                ? STextStyles.desktopTextSmall(context)
                : STextStyles.itemSubtitle(context),
          ),
        ),
      );
    } else {
      for (var i = 0; i < orders.length; i++) {
        final order = orders[i];
        if (i > 0) orderItems.add(SizedBox(height: isDesktop ? 16 : 12));
        orderItems.add(
          RoundedContainer(
            padding: EdgeInsets.all(isDesktop ? 16 : 12),
            borderColor: isDesktop
                ? Theme.of(context).extension<StackColors>()!.textFieldDefaultBG
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
                              color: order.status
                                  .color(
                                    Theme.of(context).extension<StackColors>()!,
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
                                          : STextStyles.itemSubtitle12(context))
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
                              ? STextStyles.desktopTextExtraExtraSmall(context)
                              : STextStyles.itemSubtitle12(context).copyWith(
                                  color: Theme.of(
                                    context,
                                  ).extension<StackColors>()!.textSubtitle1,
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
      }
    }

    Future<void> onRefresh() => ref.read(pCakePayOrdersService).refreshAll();

    final body = RefreshControl(
      onRefresh: onRefresh,
      child: ListView(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        primary: isDesktop ? false : null,
        padding: isDesktop ? const EdgeInsets.only(bottom: 32, top: 8) : null,
        children: orderItems,
      ),
    );

    return ConditionalParent(
      condition: isDesktop,
      builder: (child) => SDialog(
        child: SizedBox(
          width: 580,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RefreshButton(
                        isRefreshing: isRefreshing,
                        onPressed: onRefresh,
                      ),
                      const SizedBox(width: 8),
                      const DesktopDialogCloseButton(),
                    ],
                  ),
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
        child: body,
      ),
    );
  }
}
