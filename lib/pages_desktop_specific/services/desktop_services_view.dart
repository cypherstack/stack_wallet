import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../app_config.dart';
import '../../route_generator.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/text_styles.dart';
import '../../widgets/desktop/desktop_app_bar.dart';
import '../../widgets/desktop/desktop_scaffold.dart';
import '../settings/settings_menu_item.dart';
import 'cakepay/desktop_gift_cards_view.dart';
import 'shopin_bit/desktop_shopinbit_view.dart';

final _selectedServicesMenuItemStateProvider = StateProvider<_MenuItem?>(
  (_) => _labels.firstOrNull,
);

enum _MenuItem {
  shopinBit("Services"),
  cakePay("Gift Cards");

  final String value;
  const _MenuItem(this.value);
}

final _labels = [
  if (AppConfig.hasFeature(.shopinBit)) _MenuItem.shopinBit,
  if (AppConfig.hasFeature(.cakePay)) _MenuItem.cakePay,
];

class DesktopServicesView extends ConsumerStatefulWidget {
  const DesktopServicesView({super.key});

  static const String routeName = "/desktopServicesView";

  @override
  ConsumerState<DesktopServicesView> createState() =>
      _DesktopServicesViewState();
}

class _DesktopServicesViewState extends ConsumerState<DesktopServicesView> {
  @override
  Widget build(BuildContext context) {
    final Map<_MenuItem, Widget> contentViews = {
      if (AppConfig.hasFeature(.shopinBit))
        .shopinBit: const Navigator(
          key: Key("servicesShopInBitDesktopKey"),
          onGenerateRoute: RouteGenerator.generateRoute,
          initialRoute: DesktopShopInBitView.routeName,
        ),
      if (AppConfig.hasFeature(.cakePay))
        .cakePay: const Navigator(
          key: Key("servicesGiftCardsDesktopKey"),
          onGenerateRoute: RouteGenerator.generateRoute,
          initialRoute: DesktopGiftCardsView.routeName,
        ),
    };

    return DesktopScaffold(
      background: Theme.of(context).extension<StackColors>()!.background,
      appBar: DesktopAppBar(
        isCompactHeight: true,
        leading: Row(
          children: [
            const SizedBox(width: 24, height: 24),
            Text("Services", style: STextStyles.desktopH3(context)),
          ],
        ),
      ),
      body: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 250,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ..._labels.map(
                            (label) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SettingsMenuItem<_MenuItem?>(
                                  icon: SvgPicture.asset(
                                    Assets.svg.polygon,
                                    width: 11,
                                    height: 11,
                                    color:
                                        ref
                                                .watch(
                                                  _selectedServicesMenuItemStateProvider
                                                      .state,
                                                )
                                                .state ==
                                            label
                                        ? Theme.of(context)
                                              .extension<StackColors>()!
                                              .accentColorBlue
                                        : Colors.transparent,
                                  ),
                                  label: label.value,
                                  value: label,
                                  group: ref
                                      .watch(
                                        _selectedServicesMenuItemStateProvider
                                            .state,
                                      )
                                      .state,
                                  onChanged: (newValue) =>
                                      ref
                                              .read(
                                                _selectedServicesMenuItemStateProvider
                                                    .state,
                                              )
                                              .state =
                                          newValue,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child:
                contentViews[ref
                    .watch(_selectedServicesMenuItemStateProvider.state)
                    .state]!,
          ),
        ],
      ),
    );
  }
}
