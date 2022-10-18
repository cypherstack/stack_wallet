import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/exchange_view/exchange_loading_overlay.dart';
import 'package:stackwallet/pages/exchange_view/exchange_view.dart';
import 'package:stackwallet/pages/home_view/sub_widgets/home_view_button_bar.dart';
import 'package:stackwallet/pages/notification_views/notifications_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/global_settings_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/hidden_settings.dart';
import 'package:stackwallet/pages/wallets_view/wallets_view.dart';
import 'package:stackwallet/providers/global/notifications_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/ui/home_view_index_provider.dart';
import 'package:stackwallet/providers/ui/unread_notifications_provider.dart';
import 'package:stackwallet/services/exchange/exchange_data_loading_service.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  static const routeName = "/home";

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();

  late final PageController _pageController;

  late final List<Widget> _children;

  DateTime? _cachedTime;

  bool _exitEnabled = false;

  final _exchangeDataLoadingService = ExchangeDataLoadingService();

  Future<bool> _onWillPop() async {
    // go to home view when tapping back on the main exchange view
    if (ref.read(homeViewPageIndexStateProvider.state).state == 1) {
      ref.read(homeViewPageIndexStateProvider.state).state = 0;
      return false;
    }

    if (_exitEnabled) {
      return true;
    }

    final now = DateTime.now();
    const timeout = Duration(milliseconds: 1500);
    if (_cachedTime == null || now.difference(_cachedTime!) > timeout) {
      _cachedTime = now;
      await showDialog<dynamic>(
        context: context,
        barrierDismissible: false,
        builder: (_) => WillPopScope(
          onWillPop: () async {
            _exitEnabled = true;
            return true;
          },
          child: const StackDialog(title: "Tap back again to exit"),
        ),
      ).timeout(
        timeout,
        onTimeout: () {
          _exitEnabled = false;
          Navigator.of(context).pop();
        },
      );
    }
    return _exitEnabled;
  }

  void _loadCNData() {
    // unawaited future
    if (ref.read(prefsChangeNotifierProvider).externalCalls) {
      _exchangeDataLoadingService.loadAll(ref);
    } else {
      Logging.instance.log("User does not want to use external calls",
          level: LogLevel.Info);
    }
  }

  @override
  void initState() {
    _pageController = PageController();
    _children = [
      const WalletsView(),
      if (Constants.enableExchange)
        Stack(
          children: [
            const ExchangeView(),
            ExchangeLoadingOverlayView(
              unawaitedLoad: _loadCNData,
            ),
          ],
        ),
      // const BuyView(),
    ];

    ref.read(notificationsProvider).startCheckingWatchedNotifications();

    super.initState();
  }

  @override
  dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _hiddenTime = DateTime.now();
  int _hiddenCount = 0;

  void _hiddenOptions() {
    if (_hiddenCount == 5) {
      Navigator.of(context).pushNamed(HiddenSettings.routeName);
    }
    final now = DateTime.now();
    const timeout = Duration(seconds: 1);
    if (now.difference(_hiddenTime) < timeout) {
      _hiddenCount++;
    } else {
      _hiddenCount = 0;
    }
    _hiddenTime = now;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _key,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              GestureDetector(
                onTap: _hiddenOptions,
                child: SvgPicture.asset(
                  Assets.svg.stackIcon(context),
                  width: 24,
                  height: 24,
                ),
              ),
              const SizedBox(
                width: 16,
              ),
              Text(
                "My Stack",
                style: STextStyles.navBarTitle(context),
              )
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 10,
                right: 10,
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: AppBarIconButton(
                  key: const Key("walletsViewAlertsButton"),
                  size: 36,
                  shadows: const [],
                  color: Theme.of(context).extension<StackColors>()!.background,
                  icon: SvgPicture.asset(
                    ref.watch(notificationsProvider
                            .select((value) => value.hasUnreadNotifications))
                        ? Assets.svg.bellNew(context)
                        : Assets.svg.bell,
                    width: 20,
                    height: 20,
                    color: ref.watch(notificationsProvider
                            .select((value) => value.hasUnreadNotifications))
                        ? null
                        : Theme.of(context)
                            .extension<StackColors>()!
                            .topNavIconPrimary,
                  ),
                  onPressed: () {
                    // reset unread state
                    ref.refresh(unreadNotificationsStateProvider);

                    Navigator.of(context)
                        .pushNamed(NotificationsView.routeName)
                        .then((_) {
                      final Set<int> unreadNotificationIds = ref
                          .read(unreadNotificationsStateProvider.state)
                          .state;
                      if (unreadNotificationIds.isEmpty) return;

                      List<Future<void>> futures = [];
                      for (int i = 0;
                          i < unreadNotificationIds.length - 1;
                          i++) {
                        futures.add(ref.read(notificationsProvider).markAsRead(
                            unreadNotificationIds.elementAt(i), false));
                      }

                      // wait for multiple to update if any
                      Future.wait(futures).then((_) {
                        // only notify listeners once
                        ref
                            .read(notificationsProvider)
                            .markAsRead(unreadNotificationIds.last, true);
                      });
                    });
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 10,
                right: 10,
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: AppBarIconButton(
                  key: const Key("walletsViewSettingsButton"),
                  size: 36,
                  shadows: const [],
                  color: Theme.of(context).extension<StackColors>()!.background,
                  icon: SvgPicture.asset(
                    Assets.svg.gear,
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .topNavIconPrimary,
                    width: 20,
                    height: 20,
                  ),
                  onPressed: () {
                    debugPrint("main view settings tapped");
                    Navigator.of(context)
                        .pushNamed(GlobalSettingsView.routeName);
                  },
                ),
              ),
            ),
          ],
        ),
        body: Container(
          color: Theme.of(context).extension<StackColors>()!.background,
          child: Column(
            children: [
              if (Constants.enableExchange)
                Container(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).extension<StackColors>()!.background,
                    boxShadow: [
                      Theme.of(context)
                          .extension<StackColors>()!
                          .standardBoxShadow,
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      bottom: 12,
                      right: 16,
                      top: 0,
                    ),
                    child: HomeViewButtonBar(),
                  ),
                ),
              Expanded(
                child: Consumer(
                  builder: (_, _ref, __) {
                    _ref.listen(homeViewPageIndexStateProvider,
                        (previous, next) {
                      if (next is int) {
                        if (next == 1) {
                          _exchangeDataLoadingService.loadAll(ref);
                        }
                        if (next >= 0 && next <= 1) {
                          _pageController.animateToPage(
                            next,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.decelerate,
                          );
                        }
                      }
                    });
                    return PageView(
                      controller: _pageController,
                      children: _children,
                      onPageChanged: (pageIndex) {
                        ref.read(homeViewPageIndexStateProvider.state).state =
                            pageIndex;
                      },
                    );
                  },
                ),
              ),
              // Expanded(
              //   child: HomeStack(
              //     children: _children,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
