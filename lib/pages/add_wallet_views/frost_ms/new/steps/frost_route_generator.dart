import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/new/steps/frost_create_step_1a.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/new/steps/frost_create_step_1b.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/new/steps/frost_create_step_2.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/new/steps/frost_create_step_3.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/new/steps/frost_create_step_4.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/new/steps/frost_create_step_5.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/reshare/frost_reshare_step_1a.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/reshare/frost_reshare_step_1b.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/reshare/frost_reshare_step_1c.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/reshare/frost_reshare_step_2abd.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/reshare/frost_reshare_step_2c.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/reshare/frost_reshare_step_3abd.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/reshare/frost_reshare_step_3c.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/reshare/frost_reshare_step_4.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/reshare/frost_reshare_step_5.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/frost_currency.dart';

typedef FrostStepRoute = ({String routeName, String title});

final pFrostCreateCurrentStep = StateProvider.autoDispose((ref) => 1);
final pFrostScaffoldArgs = StateProvider<
    ({
      ({String walletName, FrostCurrency frostCurrency}) info,
      String? walletId,
      List<FrostStepRoute> stepRoutes,
      VoidCallback onSuccess,
    })?>((ref) => null);

abstract class FrostRouteGenerator {
  static const bool useMaterialPageRoute = true;

  static const List<FrostStepRoute> createNewConfigStepRoutes = [
    (routeName: FrostCreateStep1a.routeName, title: FrostCreateStep1a.title),
    (routeName: FrostCreateStep2.routeName, title: FrostCreateStep2.title),
    (routeName: FrostCreateStep3.routeName, title: FrostCreateStep3.title),
    (routeName: FrostCreateStep4.routeName, title: FrostCreateStep4.title),
    (routeName: FrostCreateStep5.routeName, title: FrostCreateStep5.title),
  ];

  static const List<FrostStepRoute> importNewConfigStepRoutes = [
    (routeName: FrostCreateStep1b.routeName, title: FrostCreateStep1b.title),
    (routeName: FrostCreateStep2.routeName, title: FrostCreateStep2.title),
    (routeName: FrostCreateStep3.routeName, title: FrostCreateStep3.title),
    (routeName: FrostCreateStep4.routeName, title: FrostCreateStep4.title),
    (routeName: FrostCreateStep5.routeName, title: FrostCreateStep5.title),
  ];

  static const List<FrostStepRoute> initiateReshareStepRoutes = [
    (routeName: FrostReshareStep1a.routeName, title: FrostReshareStep1a.title),
    (
      routeName: FrostReshareStep2abd.routeName,
      title: FrostReshareStep2abd.title
    ),
    (
      routeName: FrostReshareStep3abd.routeName,
      title: FrostReshareStep3abd.title
    ),
    (routeName: FrostReshareStep4.routeName, title: FrostReshareStep4.title),
    (routeName: FrostReshareStep5.routeName, title: FrostReshareStep5.title),
  ];

  static const List<FrostStepRoute> importReshareStepRoutes = [
    (routeName: FrostReshareStep1b.routeName, title: FrostReshareStep1b.title),
    (
      routeName: FrostReshareStep2abd.routeName,
      title: FrostReshareStep2abd.title
    ),
    (
      routeName: FrostReshareStep3abd.routeName,
      title: FrostReshareStep3abd.title
    ),
    (routeName: FrostReshareStep4.routeName, title: FrostReshareStep4.title),
    (routeName: FrostReshareStep5.routeName, title: FrostReshareStep5.title),
  ];

  static const List<FrostStepRoute> joinReshareStepRoutes = [
    (routeName: FrostReshareStep1c.routeName, title: FrostReshareStep1c.title),
    (routeName: FrostReshareStep2c.routeName, title: FrostReshareStep2c.title),
    (routeName: FrostReshareStep3c.routeName, title: FrostReshareStep3c.title),
    (routeName: FrostReshareStep4.routeName, title: FrostReshareStep4.title),
    (routeName: FrostReshareStep5.routeName, title: FrostReshareStep5.title),
  ];

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case FrostCreateStep1a.routeName:
        return RouteGenerator.getRoute(
          shouldUseMaterialRoute: useMaterialPageRoute,
          builder: (_) => const FrostCreateStep1a(),
          settings: settings,
        );

      case FrostCreateStep1b.routeName:
        return RouteGenerator.getRoute(
          shouldUseMaterialRoute: useMaterialPageRoute,
          builder: (_) => const FrostCreateStep1b(),
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

      case FrostCreateStep5.routeName:
        return RouteGenerator.getRoute(
          shouldUseMaterialRoute: useMaterialPageRoute,
          builder: (_) => const FrostCreateStep5(),
          settings: settings,
        );

      case FrostReshareStep1a.routeName:
        return RouteGenerator.getRoute(
          shouldUseMaterialRoute: useMaterialPageRoute,
          builder: (_) => const FrostReshareStep1a(),
          settings: settings,
        );

      case FrostReshareStep1b.routeName:
        return RouteGenerator.getRoute(
          shouldUseMaterialRoute: useMaterialPageRoute,
          builder: (_) => const FrostReshareStep1b(),
          settings: settings,
        );

      case FrostReshareStep1c.routeName:
        return RouteGenerator.getRoute(
          shouldUseMaterialRoute: useMaterialPageRoute,
          builder: (_) => const FrostReshareStep1c(),
          settings: settings,
        );

      case FrostReshareStep2abd.routeName:
        return RouteGenerator.getRoute(
          shouldUseMaterialRoute: useMaterialPageRoute,
          builder: (_) => const FrostReshareStep2abd(),
          settings: settings,
        );

      case FrostReshareStep2c.routeName:
        return RouteGenerator.getRoute(
          shouldUseMaterialRoute: useMaterialPageRoute,
          builder: (_) => const FrostReshareStep2c(),
          settings: settings,
        );

      case FrostReshareStep3abd.routeName:
        return RouteGenerator.getRoute(
          shouldUseMaterialRoute: useMaterialPageRoute,
          builder: (_) => const FrostReshareStep3abd(),
          settings: settings,
        );

      case FrostReshareStep3c.routeName:
        return RouteGenerator.getRoute(
          shouldUseMaterialRoute: useMaterialPageRoute,
          builder: (_) => const FrostReshareStep3c(),
          settings: settings,
        );

      case FrostReshareStep4.routeName:
        return RouteGenerator.getRoute(
          shouldUseMaterialRoute: useMaterialPageRoute,
          builder: (_) => const FrostReshareStep4(),
          settings: settings,
        );

      case FrostReshareStep5.routeName:
        return RouteGenerator.getRoute(
          shouldUseMaterialRoute: useMaterialPageRoute,
          builder: (_) => const FrostReshareStep5(),
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
