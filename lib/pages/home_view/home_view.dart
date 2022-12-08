import 'dart:async';

import 'package:epicmobile/pages/help/help_view.dart';
import 'package:epicmobile/pages/home_view/sub_widgets/connection_status_bar.dart';
import 'package:epicmobile/pages/receive_view/receive_view.dart';
import 'package:epicmobile/pages/send_view/send_view.dart';
import 'package:epicmobile/pages/settings_views/network_settings_view/network_settings_view.dart';
import 'package:epicmobile/pages/settings_views/settings_view.dart';
import 'package:epicmobile/pages/wallet_view/wallet_view.dart';
import 'package:epicmobile/providers/global/wallet_provider.dart';
import 'package:epicmobile/providers/tx_count_on_startup_state_provider.dart';
import 'package:epicmobile/providers/ui/home_view_index_provider.dart';
import 'package:epicmobile/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:epicmobile/services/event_bus/events/global/refresh_percent_changed_event.dart';
import 'package:epicmobile/services/event_bus/events/global/updated_in_background_event.dart';
import 'package:epicmobile/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:epicmobile/services/event_bus/global_event_bus.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/messages.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/rounded_container.dart';
import 'package:epicmobile/widgets/stack_dialog.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({
    Key? key,
    this.eventBus,
  }) : super(key: key);

  final EventBus? eventBus;

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

  late double _percent;

  late final EventBus eventBus;

  late WalletSyncStatus _currentSyncStatus;
  late NodeConnectionStatus _currentNodeStatus;

  late StreamSubscription<dynamic> _syncStatusSubscription;
  late StreamSubscription<dynamic> _nodeStatusSubscription;
  late StreamSubscription<dynamic> _refreshSubscription;

  int currentIndex = 1;

  void _onTappedBar(int value) {
    setState(() {
      currentIndex = value;
    });
    _pageController.jumpToPage(value);
  }

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

  @override
  void initState() {
    _pageController = PageController(initialPage: 1);
    _children = [
      SendView(
        walletId: ref.read(walletProvider)!.walletId,
        coin: ref.read(walletProvider)!.coin,
      ),
      WalletView(
        walletId: ref.read(walletProvider)!.walletId,
      ),
      ReceiveView(
        walletId: ref.read(walletProvider)!.walletId,
        coin: ref.read(walletProvider)!.coin,
      ),
    ];

    if (ref.read(walletProvider)!.isRefreshing) {
      _currentSyncStatus = WalletSyncStatus.syncing;
      _currentNodeStatus = NodeConnectionStatus.connected;
    } else {
      _currentSyncStatus = WalletSyncStatus.synced;
      if (ref.read(walletProvider)!.isConnected) {
        _currentNodeStatus = NodeConnectionStatus.connected;
      } else {
        _currentNodeStatus = NodeConnectionStatus.disconnected;
        _currentSyncStatus = WalletSyncStatus.unableToSync;
      }
    }

    if (_currentSyncStatus == WalletSyncStatus.synced) {
      _percent = 1;
    } else {
      _percent = 0;
    }

    eventBus = widget.eventBus ?? GlobalEventBus.instance;
    eventBus.on<UpdatedInBackgroundEvent>().listen((event) async {
      final count = ref.read(txCountOnStartUpProvider.state).state ?? 0;
      final newCount = ref.read(walletProvider)!.txCount;
      if (count < newCount) {
        ref.read(txCountOnStartUpProvider.state).state = newCount;
        await Messages.of(context).show(
          context: context,
          widget: RoundedContainer(
            color: Theme.of(context).extension<StackColors>()!.coal,
            child: Center(
              child: Text(
                "New transaction",
                style: STextStyles.bodySmallBold(context).copyWith(
                  color: Theme.of(context).extension<StackColors>()!.textMedium,
                ),
              ),
            ),
          ),
        );
      }
    });

    _syncStatusSubscription =
        eventBus.on<WalletSyncStatusChangedEvent>().listen(
      (event) async {
        if (event.walletId == ref.read(walletProvider)!.walletId) {
          setState(() {
            _currentSyncStatus = event.newStatus;
          });
        }
      },
    );

    _nodeStatusSubscription =
        eventBus.on<NodeConnectionStatusChangedEvent>().listen(
      (event) async {
        if (event.walletId == ref.read(walletProvider)!.walletId) {
          // switch (event.newStatus) {
          //   case NodeConnectionStatus.disconnected:
          //     break;
          //   case NodeConnectionStatus.connected:
          //     break;
          // }
          setState(() {
            _currentNodeStatus = event.newStatus;
          });
        }
      },
    );

    _refreshSubscription = eventBus.on<RefreshPercentChangedEvent>().listen(
      (event) async {
        if (event.walletId == ref.read(walletProvider)!.walletId) {
          setState(() {
            _percent = event.percent.clamp(0.0, 1.0);
          });
        }
      },
    );

    super.initState();
  }

  @override
  dispose() {
    _nodeStatusSubscription.cancel();
    _syncStatusSubscription.cancel();
    _refreshSubscription.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    ref.listen(homeViewPageIndexStateProvider, (previous, next) {
      if (next is int) {
        if (next >= 0 && next <= 1) {
          _pageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 300),
            curve: Curves.decelerate,
          );
        }
      }
    });

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Background(
        child: Stack(
          children: [
            Positioned(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 50,
                      ),
                      SvgPicture.asset(
                        Assets.svg.epicBG,
                        width: MediaQuery.of(context).size.width * 0.7,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Scaffold(
              backgroundColor:
                  Theme.of(context).extension<StackColors>()!.background,
              key: _key,
              appBar: AppBar(
                leading: AppBarIconButton(
                  icon: SvgPicture.asset(
                    Assets.svg.circleQuestion,
                    width: 22,
                    height: 22,
                  ),
                  onPressed: () =>
                      Navigator.of(context).pushNamed(HelpView.routeName),
                ),
                centerTitle: true,
                title: SizedBox(
                  height: 32,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        NetworkSettingsView.routeName,
                      );
                    },
                    child: ConnectionStatusBar(
                      currentSyncPercent: _percent,
                      color: Theme.of(context).extension<StackColors>()!.coal,
                      background:
                          Theme.of(context).extension<StackColors>()!.popupBG,
                    ),
                  ),
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
                        key: const Key("walletsViewSettingsButton"),
                        size: 36,
                        shadows: const [],
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .background,
                        icon: SvgPicture.asset(
                          Assets.svg.menu,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .topNavIconPrimary,
                          width: 20,
                          height: 20,
                        ),
                        onPressed: () {
                          debugPrint("main view settings tapped");
                          Navigator.of(context)
                              .pushNamed(SettingsView.routeName);
                        },
                      ),
                    ),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.only(
                  //     top: 10,
                  //     bottom: 10,
                  //     right: 10,
                  //   ),
                  //   child: AspectRatio(
                  //     aspectRatio: 1,
                  //     child: AppBarIconButton(
                  //       key: const Key("walletViewRadioButton"),
                  //       size: 36,
                  //       shadows: const [],
                  //       color:
                  //           Theme.of(context).extension<StackColors>()!.background,
                  //       icon: _buildNetworkIcon(_currentSyncStatus),
                  //       onPressed: () {
                  //         Navigator.of(context).pushNamed(
                  //           WalletNetworkSettingsView.routeName,
                  //           arguments: Tuple3(
                  //             walletId,
                  //             _currentSyncStatus,
                  //             _currentNodeStatus,
                  //           ),
                  //         );
                  //       },
                  //     ),
                  //   ),
                  // ),
                  // Padding(
                  //   padding: const EdgeInsets.only(
                  //     top: 10,
                  //     bottom: 10,
                  //     right: 10,
                  //   ),
                  //   child: AspectRatio(
                  //     aspectRatio: 1,
                  //     child: AppBarIconButton(
                  //       key: const Key("walletViewSettingsButton"),
                  //       size: 36,
                  //       shadows: const [],
                  //       color:
                  //           Theme.of(context).extension<StackColors>()!.background,
                  //       icon: SvgPicture.asset(
                  //         Assets.svg.menu,
                  //         color: Theme.of(context)
                  //             .extension<StackColors>()!
                  //             .accentColorDark,
                  //         width: 20,
                  //         height: 20,
                  //       ),
                  //       onPressed: () {
                  //         debugPrint("wallet view settings tapped");
                  //         Navigator.of(context).pushNamed(
                  //           WalletSettingsView.routeName,
                  //           arguments: Tuple4(
                  //             walletId,
                  //             ref.read(walletProvider)!.coin,
                  //             _currentSyncStatus,
                  //             _currentNodeStatus,
                  //           ),
                  //         );
                  //       },
                  //     ),
                  //   ),
                  // ),
                ],
              ),
              bottomNavigationBar: Container(
                color:
                    Theme.of(context).extension<StackColors>()!.bottomNavShadow,
                height: 75,
                child: BottomNavigationBar(
                  unselectedFontSize: 14.0,
                  unselectedLabelStyle: STextStyles.smallMed12(context)
                      .copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .bottomNavText),
                  backgroundColor: Theme.of(context)
                      .extension<StackColors>()!
                      .bottomNavShadow,
                  items: [
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(
                          Assets.svg.upload,
                        ),
                      ),
                      activeIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(
                          Assets.svg.upload,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .buttonBackPrimary,
                        ),
                      ),
                      label: 'SEND',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(Assets.svg.walletHome),
                      ),
                      activeIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(
                          Assets.svg.walletHome,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .buttonBackPrimary,
                        ),
                      ),
                      label: 'WALLET',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(Assets.svg.download),
                      ),
                      activeIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(
                          Assets.svg.download,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .buttonBackPrimary,
                        ),
                      ),
                      label: 'RECEIVE',
                    ),
                  ],
                  onTap: _onTappedBar,
                  currentIndex: currentIndex,
                  selectedItemColor: Theme.of(context)
                      .extension<StackColors>()!
                      .buttonBackPrimary,
                ),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      children: _children,
                      onPageChanged: (pageIndex) {
                        ref.read(homeViewPageIndexStateProvider.state).state =
                            pageIndex;
                        setState(() {
                          currentIndex = pageIndex;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
