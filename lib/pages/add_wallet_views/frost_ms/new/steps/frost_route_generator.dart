import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/new/steps/frost_create_step_1.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/new/steps/frost_create_step_2.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/new/steps/frost_create_step_3.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/new/steps/frost_create_step_4.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/frost_currency.dart';

typedef FrostStepRoute = ({String routeName, String title});

final pFrostCreateCurrentStep = StateProvider.autoDispose((ref) => 1);
final pFrostCreateNewArgs = StateProvider<
    (
      ({String walletName, FrostCurrency frostCurrency}),
      List<FrostStepRoute>,
      VoidCallback,
    )?>((ref) => null);

abstract class FrostRouteGenerator {
  static const bool useMaterialPageRoute = true;

  static const List<FrostStepRoute> createNewConfigStepRoutes = [
    (routeName: FrostCreateStep1.routeName, title: FrostCreateStep1.title),
    (routeName: FrostCreateStep2.routeName, title: FrostCreateStep2.title),
    (routeName: FrostCreateStep3.routeName, title: FrostCreateStep3.title),
    (routeName: FrostCreateStep4.routeName, title: FrostCreateStep4.title),
  ];

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case FrostCreateStep1.routeName:
        return RouteGenerator.getRoute(
          shouldUseMaterialRoute: useMaterialPageRoute,
          builder: (_) => const FrostCreateStep1(),
          settings: settings,
        );

      case FrostCreateStep2.routeName:
        return RouteGenerator.getRoute(
          shouldUseMaterialRoute: useMaterialPageRoute,
          builder: (_) => const FrostCreateStep2(),
          settings: settings,
        );

      case FrostCreateStep3.routeName:
        return RouteGenerator.getRoute(
          shouldUseMaterialRoute: useMaterialPageRoute,
          builder: (_) => const FrostCreateStep3(),
          settings: settings,
        );

      case FrostCreateStep4.routeName:
        return RouteGenerator.getRoute(
          shouldUseMaterialRoute: useMaterialPageRoute,
          builder: (_) => const FrostCreateStep4(),
          settings: settings,
        );

      default:
        return _routeError("");
    }
  }

  static Route<dynamic> _routeError(String message) {
    return RouteGenerator.getRoute(
      shouldUseMaterialRoute: useMaterialPageRoute,
      builder: (_) => Placeholder(
        child: Center(
          child: Text(message),
        ),
      ),
    );
  }
}
