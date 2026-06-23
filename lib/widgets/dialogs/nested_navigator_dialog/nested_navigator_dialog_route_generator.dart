import 'package:flutter/material.dart';

import '../../../db/drift/shared_db/shared_database.dart';
import '../../../models/shopinbit/shopinbit_enums.dart';
import '../../../models/shopinbit/shopinbit_request_draft.dart';
import '../../../pages/cakepay/cakepay_card_detail_view.dart';
import '../../../pages/cakepay/cakepay_order_view.dart';
import '../../../pages/cakepay/cakepay_orders_view.dart';
import '../../../pages/cakepay/cakepay_vendors_view.dart';
import '../../../pages/shopinbit/shopinbit_car_fee_view.dart';
import '../../../pages/shopinbit/shopinbit_car_research_payment_view.dart';
import '../../../pages/shopinbit/shopinbit_offer_view.dart';
import '../../../pages/shopinbit/shopinbit_order_created.dart';
import '../../../pages/shopinbit/shopinbit_payment_view.dart';
import '../../../pages/shopinbit/shopinbit_shipping_view.dart';
import '../../../pages/shopinbit/shopinbit_step_2.dart';
import '../../../pages/shopinbit/shopinbit_step_3.dart';
import '../../../pages/shopinbit/shopinbit_step_4.dart';
import '../../../pages/shopinbit/shopinbit_ticket_detail.dart';
import '../../../pages/shopinbit/shopinbit_tickets_view.dart';
import '../../../pages_desktop_specific/services/shopin_bit/sub_widgets/desktop_shopin_bit_first_run.dart';
import '../../../services/cakepay/src/models/card.dart';
import '../../../services/cakepay/src/models/order.dart';
import '../../../services/shopinbit/src/models/models.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../conditional_parent.dart';
import '../../desktop/desktop_dialog_close_button.dart';
import '../s_dialog.dart';

abstract final class NestedNavigatorDialogRouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case DesktopShopinBitFirstRun.routeName:
        return getRoute(
          builder: (_) => const DesktopShopinBitFirstRun(),
          settings: RouteSettings(name: settings.name),
        );

      case ShopInBitStep2.routeName:
        if (args is bool) {
          return getRoute(
            builder: (_) => ShopInBitStep2(isActuallyFirstStep: args),
            settings: RouteSettings(name: settings.name),
          );
        }
        return getRoute(
          builder: (_) => const ShopInBitStep2(),
          settings: RouteSettings(name: settings.name),
        );

      case ShopInBitStep3.routeName:
        if (args is ({ShopInBitCategory category, String customerKey})) {
          return getRoute(
            builder: (_) => ShopInBitStep3(
              category: args.category,
              customerKey: args.customerKey,
            ),
            settings: RouteSettings(name: settings.name),
          );
        }
        return _routeError(
          "${settings.name} invalid args\n"
          "Got ${args.runtimeType}\n"
          "Expected ({ShopInBitCategory category, String customerKey})",
        );

      case ShopInBitStep4.routeName:
        if (args is ShopInBitCategory) {
          return getRoute(
            builder: (_) => ShopInBitStep4(category: args),
            settings: RouteSettings(name: settings.name),
          );
        }
        return _routeError(
          "${settings.name} invalid args\n"
          "Got ${args.runtimeType}\n"
          "Expected ShopInBitCategory",
        );

      case ShopInBitTicketsView.routeName:
        return getRoute(
          builder: (_) => const ShopInBitTicketsView(),
          settings: RouteSettings(name: settings.name),
        );

      case ShopInBitOrderCreated.routeName:
        if (args is int) {
          return getRoute(
            builder: (_) => ShopInBitOrderCreated(apiTicketId: args),
            settings: RouteSettings(name: settings.name),
          );
        }
        return _routeError(
          "${settings.name} invalid args\n"
          "Got ${args.runtimeType}\n"
          "Expected int apiTicketId",
        );

      case ShopInBitCarFeeView.routeName:
        if (args is ShopinbitRequestDraft) {
          return getRoute(
            builder: (_) => ShopInBitCarFeeView(draft: args),
            settings: RouteSettings(name: settings.name),
          );
        }
        return _routeError(
          "${settings.name} invalid args\n"
          "Got ${args.runtimeType}\n"
          "Expected ShopinbitRequestDraft",
        );

      case ShopInBitCarResearchPaymentView.routeName:
        if (args is ({CarResearchInvoice invoice, String customerKey})) {
          return getRoute(
            builder: (_) => ShopInBitCarResearchPaymentView(
              invoice: args.invoice,
              customerKey: args.customerKey,
            ),
            settings: RouteSettings(name: settings.name),
          );
        }
        return _routeError(
          "${settings.name} invalid args\n"
          "Got ${args.runtimeType}\n"
          "Expected CarResearchInvoice",
        );

      case ShopInBitTicketDetail.routeName:
        if (args is int) {
          return getRoute(
            builder: (_) => ShopInBitTicketDetail(apiTicketId: args),
            settings: RouteSettings(name: settings.name),
          );
        }
        return _routeError(
          "${settings.name} invalid args\n"
          "Got ${args.runtimeType}\n"
          "Expected int apiTicketId",
        );

      case ShopInBitOfferView.routeName:
        if (args is int) {
          return getRoute(
            builder: (_) => ShopInBitOfferView(apiTicketId: args),
            settings: RouteSettings(name: settings.name),
          );
        }
        return _routeError(
          "${settings.name} invalid args\n"
          "Got ${args.runtimeType}\n"
          "Expected int apiTicketId",
        );

      case ShopInBitShippingView.routeName:
        if (args
            is ({
              ShopInBitTicket ticket,
              List<Map<String, dynamic>> countries,
            })) {
          return getRoute(
            builder: (_) => ShopInBitShippingView(
              ticket: args.ticket,
              countries: args.countries,
            ),
            settings: RouteSettings(name: settings.name),
          );
        }
        return _routeError(
          "${settings.name} invalid args\n"
          "Got ${args.runtimeType}\n"
          "Expected ({int apiTicketId, String deliveryCountry, "
          "List<Map<String, dynamic>> countries})",
        );

      case ShopInBitPaymentView.routeName:
        if (args is ({int apiTicketId, PaymentInfo paymentInfo})) {
          return getRoute(
            builder: (_) => ShopInBitPaymentView(
              apiTicketId: args.apiTicketId,
              paymentInfo: args.paymentInfo,
            ),
            settings: RouteSettings(name: settings.name),
          );
        }
        return _routeError(
          "${settings.name} invalid args\n"
          "Got ${args.runtimeType}\n"
          "Expected ({int apiTicketId, PaymentInfo paymentInfo})",
        );

      case CakePayVendorsView.routeName:
        return getRoute(
          builder: (_) => const CakePayVendorsView(),
          settings: RouteSettings(name: settings.name),
        );

      case CakePayOrdersView.routeName:
        return getRoute(
          builder: (_) => const CakePayOrdersView(),
          settings: RouteSettings(name: settings.name),
        );

      case CakePayCardDetailView.routeName:
        if (args is CakePayCard) {
          return getRoute(
            builder: (_) => CakePayCardDetailView(card: args),
            settings: RouteSettings(name: settings.name),
          );
        }
        return _routeError(
          "${settings.name} invalid args\n"
          "Got ${args.runtimeType}\n"
          "Expected CakePayCard",
        );

      case CakePayOrderView.routeName:
        if (args is CakePayOrder) {
          return getRoute(
            builder: (_) => CakePayOrderView(order: args),
            settings: RouteSettings(name: settings.name),
          );
        }
        return _routeError(
          "${settings.name} invalid args\n"
          "Got ${args.runtimeType}\n"
          "Expected CakePayOrder",
        );

      default:
        return _routeError("Unknown route name: ${settings.name}");
    }
  }

  static Route<T> getRoute<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (BuildContext context, _, __) => builder(context),
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return FadeTransition(
              opacity: animation,
              child: FadeTransition(
                opacity: Tween<double>(
                  begin: 1,
                  end: 0,
                ).animate(secondaryAnimation),
                child: child,
              ),
            );
          },
    );
  }

  static Route<T> _routeError<T>(String message) {
    return getRoute<T>(
      builder: (context) => SDialog(
        child: ConditionalParent(
          condition: Util.isDesktop,
          builder: (child) => SizedBox(
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
                        "Navigation Error",
                        style: STextStyles.desktopH3(context),
                      ),
                    ),
                    const DesktopDialogCloseButton(),
                  ],
                ),
                child,
                const SizedBox(height: 32),
              ],
            ),
          ),
          child: SelectableText(
            "Error handling route, this is not supposed to happen. "
            "Contact developers.\n$message",
          ),
        ),
      ),
    );
  }
}
