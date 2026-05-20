import 'dart:math';

import 'package:flutter/material.dart';

import '../../../models/shopinbit/shopinbit_order_model.dart';
import '../../../pages/shopinbit/shopinbit_step_1.dart';
import '../../../pages/shopinbit/shopinbit_step_2.dart';
import '../../../pages/shopinbit/shopinbit_step_3.dart';
import '../../../pages/shopinbit/shopinbit_step_4.dart';
import '../../../pages/shopinbit/shopinbit_ticket_detail.dart';
import '../../../pages/shopinbit/shopinbit_tickets_view.dart';
import '../../../pages_desktop_specific/services/shopin_bit/sub_widgets/desktop_shopin_bit_first_run.dart';
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
        if (args is ShopInBitOrderModel) {
          return getRoute(
            builder: (_) => DesktopShopinBitFirstRun(model: args),
            settings: RouteSettings(name: settings.name),
          );
        }
        return _routeError(
          "${settings.name} invalid args\n"
          "Got ${args.runtimeType}\n"
          "Expected ShopInBitOrderModel",
        );

      case ShopInBitStep1.routeName:
        if (args is ShopInBitOrderModel) {
          return getRoute(
            builder: (_) => ShopInBitStep1(model: args),
            settings: RouteSettings(name: settings.name),
          );
        }
        return _routeError(
          "${settings.name} invalid args\n"
          "Got ${args.runtimeType}\n"
          "Expected ShopInBitOrderModel",
        );

      case ShopInBitStep2.routeName:
        if (args is ShopInBitOrderModel) {
          return getRoute(
            builder: (_) => ShopInBitStep2(model: args),
            settings: RouteSettings(name: settings.name),
          );
        }
        return _routeError(
          "${settings.name} invalid args\n"
          "Got ${args.runtimeType}\n"
          "Expected ShopInBitOrderModel",
        );

      case ShopInBitStep3.routeName:
        if (args is ShopInBitOrderModel) {
          return getRoute(
            builder: (_) => ShopInBitStep3(model: args),
            settings: RouteSettings(name: settings.name),
          );
        }
        return _routeError(
          "${settings.name} invalid args\n"
          "Got ${args.runtimeType}\n"
          "Expected ShopInBitOrderModel",
        );

      case ShopInBitStep4.routeName:
        if (args is ShopInBitOrderModel) {
          return getRoute(
            builder: (_) => ShopInBitStep4(model: args),
            settings: RouteSettings(name: settings.name),
          );
        }
        return _routeError(
          "${settings.name} invalid args\n"
          "Got ${args.runtimeType}\n"
          "Expected ShopInBitOrderModel",
        );

      case ShopInBitTicketsView.routeName:
        return getRoute(
          builder: (_) => const ShopInBitTicketsView(),
          settings: RouteSettings(name: settings.name),
        );

      case ShopInBitTicketDetail.routeName:
        if (args is ShopInBitOrderModel) {
          return getRoute(
            builder: (_) => ShopInBitTicketDetail(model: args),
            settings: RouteSettings(name: settings.name),
          );
        }
        return _routeError(
          "${settings.name} invalid args\n"
          "Got ${args.runtimeType}\n"
          "Expected ShopInBitOrderModel",
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
          child: Text(
            "Error handling route, this is not supposed to happen. "
            "Contact developers.\n$message",
          ),
        ),
      ),
    );
  }
}
