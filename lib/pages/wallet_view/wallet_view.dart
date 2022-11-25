import 'dart:async';

import 'package:epicmobile/pages/home_view/home_view.dart';
import 'package:epicmobile/pages/notification_views/notifications_view.dart';
import 'package:epicmobile/pages/receive_view/receive_view.dart';
import 'package:epicmobile/pages/send_view/send_view.dart';
import 'package:epicmobile/pages/settings_views/wallet_settings_view/wallet_network_settings_view/wallet_network_settings_view.dart';
import 'package:epicmobile/pages/settings_views/wallet_settings_view/wallet_settings_view.dart';
import 'package:epicmobile/pages/wallet_view/sub_widgets/transactions_list.dart';
import 'package:epicmobile/pages/wallet_view/sub_widgets/wallet_navigation_bar.dart';
import 'package:epicmobile/pages/wallet_view/sub_widgets/wallet_summary.dart';
import 'package:epicmobile/pages/wallet_view/transaction_views/all_transactions_view.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/providers/ui/transaction_filter_provider.dart';
import 'package:epicmobile/providers/ui/unread_notifications_provider.dart';
import 'package:epicmobile/providers/wallet/public_private_balance_state_provider.dart';
import 'package:epicmobile/providers/wallet/wallet_balance_toggle_state_provider.dart';
import 'package:epicmobile/services/coins/manager.dart';
import 'package:epicmobile/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:epicmobile/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:epicmobile/services/event_bus/global_event_bus.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/enums/wallet_balance_toggle_state.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/custom_buttons/blue_text_button.dart';
import 'package:epicmobile/widgets/stack_dialog.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tuple/tuple.dart';

/// [eventBus] should only be set during testing
class WalletView extends ConsumerStatefulWidget {
  const WalletView({
    Key? key,
    required this.walletId,
    required this.managerProvider,
    this.eventBus,
  }) : super(key: key);

  static const String routeName = "/wallet";
  static const double navBarHeight = 65.0;

  final String walletId;
  final ChangeNotifierProvider<Manager> managerProvider;
  final EventBus? eventBus;

  @override
  ConsumerState<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends ConsumerState<WalletView> {
  late final EventBus eventBus;
  late final String walletId;
  late final ChangeNotifierProvider<Manager> managerProvider;

  late final bool _shouldDisableAutoSyncOnLogOut;

  late WalletSyncStatus _currentSyncStatus;
  late NodeConnectionStatus _currentNodeStatus;

  late StreamSubscription<dynamic> _syncStatusSubscription;
  late StreamSubscription<dynamic> _nodeStatusSubscription;

  @override
  void initState() {
    walletId = widget.walletId;
    managerProvider = widget.managerProvider;

    ref.read(managerProvider).isActiveWallet = true;
    if (!ref.read(managerProvider).shouldAutoSync) {
      // enable auto sync if it wasn't enabled when loading wallet
      ref.read(managerProvider).shouldAutoSync = true;
      _shouldDisableAutoSyncOnLogOut = true;
    } else {
      _shouldDisableAutoSyncOnLogOut = false;
    }

    ref.read(managerProvider).refresh();

    if (ref.read(managerProvider).isRefreshing) {
      _currentSyncStatus = WalletSyncStatus.syncing;
      _currentNodeStatus = NodeConnectionStatus.connected;
    } else {
      _currentSyncStatus = WalletSyncStatus.synced;
      if (ref.read(managerProvider).isConnected) {
        _currentNodeStatus = NodeConnectionStatus.connected;
      } else {
        _currentNodeStatus = NodeConnectionStatus.disconnected;
        _currentSyncStatus = WalletSyncStatus.unableToSync;
      }
    }

    eventBus =
        widget.eventBus != null ? widget.eventBus! : GlobalEventBus.instance;

    _syncStatusSubscription =
        eventBus.on<WalletSyncStatusChangedEvent>().listen(
      (event) async {
        if (event.walletId == widget.walletId) {
          setState(() {
            _currentSyncStatus = event.newStatus;
          });
        }
      },
    );

    _nodeStatusSubscription =
        eventBus.on<NodeConnectionStatusChangedEvent>().listen(
      (event) async {
        if (event.walletId == widget.walletId) {
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

    super.initState();
  }

  @override
  void dispose() {
    _nodeStatusSubscription.cancel();
    _syncStatusSubscription.cancel();
    super.dispose();
  }

  DateTime? _cachedTime;

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    const timeout = Duration(milliseconds: 1500);
    if (_cachedTime == null || now.difference(_cachedTime!) > timeout) {
      _cachedTime = now;
      unawaited(showDialog<dynamic>(
        context: context,
        barrierDismissible: false,
        builder: (_) => WillPopScope(
          onWillPop: () async {
            Navigator.of(context).popUntil(
              ModalRoute.withName(HomeView.routeName),
            );
            _logout();
            return false;
          },
          child: const StackDialog(title: "Tap back again to exit wallet"),
        ),
      ).timeout(
        timeout,
        onTimeout: () => Navigator.of(context).popUntil(
          ModalRoute.withName(WalletView.routeName),
        ),
      ));
    }
    return false;
  }

  void _logout() async {
    if (_shouldDisableAutoSyncOnLogOut) {
      // disable auto sync if it was enabled only when loading wallet
      ref.read(managerProvider).shouldAutoSync = false;
    }
    ref.read(managerProvider.notifier).isActiveWallet = false;
    ref.read(transactionFilterProvider.state).state = null;
  }

  Widget _buildNetworkIcon(WalletSyncStatus status) {
    switch (status) {
      case WalletSyncStatus.unableToSync:
        return SvgPicture.asset(
          Assets.svg.radioProblem,
          color: Theme.of(context).extension<StackColors>()!.accentColorRed,
          width: 20,
          height: 20,
        );
      case WalletSyncStatus.synced:
        return SvgPicture.asset(
          Assets.svg.radio,
          color: Theme.of(context).extension<StackColors>()!.accentColorGreen,
          width: 20,
          height: 20,
        );
      case WalletSyncStatus.syncing:
        return SvgPicture.asset(
          Assets.svg.radioSyncing,
          color: Theme.of(context).extension<StackColors>()!.accentColorYellow,
          width: 20,
          height: 20,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final coin = ref.watch(managerProvider.select((value) => value.coin));

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: AppBarBackButton(
              onPressed: () {
                _logout();
                Navigator.of(context).pop();
              },
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                SvgPicture.asset(
                  Assets.svg.iconFor(coin: coin),
                  // color: Theme.of(context).extension<StackColors>()!.accentColorDark
                  width: 24,
                  height: 24,
                ),
                const SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: Text(
                    ref.watch(
                        managerProvider.select((value) => value.walletName)),
                    style: STextStyles.navBarTitle(context),
                    overflow: TextOverflow.ellipsis,
                  ),
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
                    key: const Key("walletViewRadioButton"),
                    size: 36,
                    shadows: const [],
                    color:
                        Theme.of(context).extension<StackColors>()!.background,
                    icon: _buildNetworkIcon(_currentSyncStatus),
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        WalletNetworkSettingsView.routeName,
                        arguments: Tuple3(
                          walletId,
                          _currentSyncStatus,
                          _currentNodeStatus,
                        ),
                      );
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
                    key: const Key("walletViewAlertsButton"),
                    size: 36,
                    shadows: const [],
                    color:
                        Theme.of(context).extension<StackColors>()!.background,
                    icon: SvgPicture.asset(
                      ref.watch(notificationsProvider.select((value) =>
                              value.hasUnreadNotificationsFor(walletId)))
                          ? Assets.svg.bellNew(context)
                          : Assets.svg.bell,
                      width: 20,
                      height: 20,
                      color: ref.watch(notificationsProvider.select((value) =>
                              value.hasUnreadNotificationsFor(walletId)))
                          ? null
                          : Theme.of(context)
                              .extension<StackColors>()!
                              .topNavIconPrimary,
                    ),
                    onPressed: () {
                      // reset unread state
                      ref.refresh(unreadNotificationsStateProvider);

                      Navigator.of(context)
                          .pushNamed(
                        NotificationsView.routeName,
                        arguments: walletId,
                      )
                          .then((_) {
                        final Set<int> unreadNotificationIds = ref
                            .read(unreadNotificationsStateProvider.state)
                            .state;
                        if (unreadNotificationIds.isEmpty) return;

                        List<Future<dynamic>> futures = [];
                        for (int i = 0;
                            i < unreadNotificationIds.length - 1;
                            i++) {
                          futures.add(ref
                              .read(notificationsProvider)
                              .markAsRead(
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
                    key: const Key("walletViewSettingsButton"),
                    size: 36,
                    shadows: const [],
                    color:
                        Theme.of(context).extension<StackColors>()!.background,
                    icon: SvgPicture.asset(
                      Assets.svg.bars,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorDark,
                      width: 20,
                      height: 20,
                    ),
                    onPressed: () {
                      debugPrint("wallet view settings tapped");
                      Navigator.of(context).pushNamed(
                        WalletSettingsView.routeName,
                        arguments: Tuple4(
                          walletId,
                          ref.read(managerProvider).coin,
                          _currentSyncStatus,
                          _currentNodeStatus,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Container(
              color: Theme.of(context).extension<StackColors>()!.background,
              child: Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: WalletSummary(
                        walletId: walletId,
                        managerProvider: managerProvider,
                        initialSyncStatus: ref.watch(managerProvider
                                .select((value) => value.isRefreshing))
                            ? WalletSyncStatus.syncing
                            : WalletSyncStatus.synced,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Transactions",
                          style: STextStyles.itemSubtitle(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark3,
                          ),
                        ),
                        BlueTextButton(
                          text: "See all",
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              AllTransactionsView.routeName,
                              arguments: walletId,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(
                                  Constants.size.circularBorderRadius,
                                ),
                                bottom: Radius.circular(
                                  // WalletView.navBarHeight / 2.0,
                                  Constants.size.circularBorderRadius,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    Constants.size.circularBorderRadius,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: TransactionsList(
                                        managerProvider: managerProvider,
                                        walletId: walletId,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 14,
                                    left: 16,
                                    right: 16,
                                  ),
                                  child: SizedBox(
                                    height: WalletView.navBarHeight,
                                    child: WalletNavigationBar(
                                      enableExchange:
                                          Constants.enableExchange &&
                                              ref.watch(managerProvider.select(
                                                      (value) => value.coin)) !=
                                                  Coin.epicCash,
                                      height: WalletView.navBarHeight,
                                      onExchangePressed: () {},
                                      onReceivePressed: () async {
                                        final coin =
                                            ref.read(managerProvider).coin;
                                        if (mounted) {
                                          unawaited(
                                              Navigator.of(context).pushNamed(
                                            ReceiveView.routeName,
                                            arguments: Tuple2(
                                              walletId,
                                              coin,
                                            ),
                                          ));
                                        }
                                      },
                                      onSendPressed: () {
                                        final walletId =
                                            ref.read(managerProvider).walletId;
                                        final coin =
                                            ref.read(managerProvider).coin;
                                        switch (ref
                                            .read(
                                                walletBalanceToggleStateProvider
                                                    .state)
                                            .state) {
                                          case WalletBalanceToggleState.full:
                                            ref
                                                .read(
                                                    publicPrivateBalanceStateProvider
                                                        .state)
                                                .state = "Public";
                                            break;
                                          case WalletBalanceToggleState
                                              .available:
                                            ref
                                                .read(
                                                    publicPrivateBalanceStateProvider
                                                        .state)
                                                .state = "Private";
                                            break;
                                        }
                                        Navigator.of(context).pushNamed(
                                          SendView.routeName,
                                          arguments: Tuple2(
                                            walletId,
                                            coin,
                                          ),
                                        );
                                      },
                                      onBuyPressed: () {},
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
