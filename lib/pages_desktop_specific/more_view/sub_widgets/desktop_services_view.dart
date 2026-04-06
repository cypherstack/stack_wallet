import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../../route_generator.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/text_styles.dart';
import '../../../widgets/desktop/desktop_app_bar.dart';
import '../../../widgets/desktop/desktop_scaffold.dart';
import '../../settings/settings_menu_item.dart';
import 'desktop_shopinbit_view.dart';

final selectedServicesMenuItemStateProvider = StateProvider<int>((_) => 0);

class DesktopServicesView extends ConsumerStatefulWidget {
  const DesktopServicesView({super.key});

  static const String routeName = "/desktopServicesView";

  @override
  ConsumerState<DesktopServicesView> createState() =>
      _DesktopServicesViewState();
}

class _DesktopServicesViewState extends ConsumerState<DesktopServicesView> {
  final List<String> _labels = const ["Services" /*, "Gift Cards"*/];

  @override
  Widget build(BuildContext context) {
    final List<Widget> contentViews = [
      const Navigator(
        key: Key("servicesShopInBitDesktopKey"),
        onGenerateRoute: RouteGenerator.generateRoute,
        initialRoute: DesktopShopInBitView.routeName,
      ),
      // const Navigator(
      //   key: Key("servicesGiftCardsDesktopKey"),
      //   onGenerateRoute: RouteGenerator.generateRoute,
      //   initialRoute: DesktopGiftCardsView.routeName,
      // ),
    ];

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
                          for (int i = 0; i < _labels.length; i++)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (i > 0) const SizedBox(height: 2),
                                SettingsMenuItem<int>(
                                  icon: SvgPicture.asset(
                                    Assets.svg.polygon,
                                    width: 11,
                                    height: 11,
                                    color:
                                        ref
                                                .watch(
                                                  selectedServicesMenuItemStateProvider
                                                      .state,
                                                )
                                                .state ==
                                            i
                                        ? Theme.of(context)
                                              .extension<StackColors>()!
                                              .accentColorBlue
                                        : Colors.transparent,
                                  ),
                                  label: _labels[i],
                                  value: i,
                                  group: ref
                                      .watch(
                                        selectedServicesMenuItemStateProvider
                                            .state,
                                      )
                                      .state,
                                  onChanged: (newValue) =>
                                      ref
                                              .read(
                                                selectedServicesMenuItemStateProvider
                                                    .state,
                                              )
                                              .state =
                                          newValue,
                                ),
                              ],
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
                    .watch(selectedServicesMenuItemStateProvider.state)
                    .state],
          ),
        ],
      ),
    );
  }
}
