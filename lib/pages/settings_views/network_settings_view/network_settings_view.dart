import 'dart:async';

import 'package:epicpay/pages/settings_views/network_settings_view/manage_nodes_views/add_edit_node_view.dart';
import 'package:epicpay/pages/settings_views/network_settings_view/sub_widgets/nodes_list.dart';
import 'package:epicpay/providers/providers.dart';
import 'package:epicpay/services/coins/epiccash/epiccash_wallet.dart';
import 'package:epicpay/services/event_bus/events/global/refresh_percent_changed_event.dart';
import 'package:epicpay/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:epicpay/services/event_bus/global_event_bus.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/widgets/background.dart';
import 'package:epicpay/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicpay/widgets/icon_widgets/plus_icon.dart';
import 'package:epicpay/widgets/rounded_white_container.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';

/// [eventBus] should only be set during testing
class NetworkSettingsView extends ConsumerStatefulWidget {
  const NetworkSettingsView({
    Key? key,
    this.eventBus,
  }) : super(key: key);

  final EventBus? eventBus;

  static const String routeName = "/walletNetworkSettings";

  @override
  ConsumerState<NetworkSettingsView> createState() =>
      _WalletNetworkSettingsViewState();
}

class _WalletNetworkSettingsViewState
    extends ConsumerState<NetworkSettingsView> {
  late final EventBus eventBus;

  late WalletSyncStatus _currentSyncStatus;

  late StreamSubscription<dynamic> _refreshSubscription;
  late StreamSubscription<dynamic> _syncStatusSubscription;

  late double _percent;

  String _percentString(double value) {
    double realPercent = (value * 10000).ceil().clamp(0, 10000) / 100.0;
    if (realPercent > 99.99 && _currentSyncStatus == WalletSyncStatus.syncing) {
      return "99.99%";
    }
    return "${realPercent.toStringAsFixed(2)}%";
  }

  @override
  void initState() {
    if (ref.read(walletProvider)!.isRefreshing) {
      _currentSyncStatus = WalletSyncStatus.syncing;
    } else {
      if (ref.read(walletProvider)!.isConnected) {
        _currentSyncStatus = WalletSyncStatus.synced;
      } else {
        _currentSyncStatus = WalletSyncStatus.unableToSync;
      }
    }
    if (_currentSyncStatus == WalletSyncStatus.synced) {
      _percent = 1;
    } else {
      _percent = 0;
    }

    eventBus =
        widget.eventBus != null ? widget.eventBus! : GlobalEventBus.instance;

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
  void dispose() {
    _syncStatusSubscription.cancel();
    _refreshSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double highestPercent =
        (ref.read(walletProvider)!.wallet as EpicCashWallet).highestPercent;
    if (_percent < highestPercent) {
      _percent = highestPercent.clamp(0.0, 1.0);
    }

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          centerTitle: true,
          title: Text(
            "Connections",
            style: STextStyles.titleH4(context),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                splashRadius: 20,
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AddEditNodeView.routeName,
                    arguments: Tuple4(
                      AddEditNodeViewType.add,
                      ref.read(walletProvider)!.coin,
                      null,
                      NetworkSettingsView.routeName,
                    ),
                  );
                },
                icon: const PlusIcon(
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 24,
              top: 24,
              bottom: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_currentSyncStatus == WalletSyncStatus.synced)
                          RoundedWhiteContainer(
                            child: Text(
                              "Connected",
                              textAlign: TextAlign.center,
                              style: STextStyles.syncPercent(context).copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .accentColorGreen,
                              ),
                            ),
                          ),
                        if (_currentSyncStatus == WalletSyncStatus.syncing)
                          RoundedWhiteContainer(
                            child: Text(
                              "Synchronizing transaction data (${_percentString(_percent)})",
                              textAlign: TextAlign.center,
                              style: STextStyles.syncPercent(context).copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .accentColorYellow,
                              ),
                            ),
                          ),
                        if (_currentSyncStatus == WalletSyncStatus.unableToSync)
                          GestureDetector(
                            onTap: () {
                              ref.read(walletProvider)!.refresh();
                            },
                            child: RoundedWhiteContainer(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "Could not connect.",
                                    textAlign: TextAlign.center,
                                    style: STextStyles.bodySmallBold(context)
                                        .copyWith(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .accentColorRed,
                                    ),
                                  ),
                                  Text(
                                    "Tap to retry or choose a different node.",
                                    textAlign: TextAlign.center,
                                    style: STextStyles.bodySmallBold(context)
                                        .copyWith(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .accentColorRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 32,
                  ),
                  Text(
                    "AVAILABLE CONNECTIONS",
                    textAlign: TextAlign.left,
                    style: STextStyles.overLineBold(context),
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  NodesList(
                    coin: ref
                        .watch(walletProvider.select((value) => value!.coin)),
                    popBackToRoute: NetworkSettingsView.routeName,
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
