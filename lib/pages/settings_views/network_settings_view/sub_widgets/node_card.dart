import 'dart:async';

import 'package:epicpay/models/node_model.dart';
import 'package:epicpay/pages/settings_views/network_settings_view/manage_nodes_views/add_edit_node_view.dart';
import 'package:epicpay/providers/providers.dart';
import 'package:epicpay/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/enums/coin_enum.dart';
import 'package:epicpay/utilities/enums/sync_type_enum.dart';
import 'package:epicpay/utilities/logger.dart';
import 'package:epicpay/utilities/test_epic_box_connection.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/widgets/conditional_parent.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tuple/tuple.dart';

import '../../../../services/event_bus/global_event_bus.dart';

class NodeCard extends ConsumerStatefulWidget {
  const NodeCard({
    Key? key,
    required this.nodeId,
    required this.coin,
    required this.popBackToRoute,
    this.eventBus,
  }) : super(key: key);

  final Coin coin;
  final String nodeId;
  final String popBackToRoute;
  final EventBus? eventBus;

  @override
  ConsumerState<NodeCard> createState() => _NodeCardState();
}

class _NodeCardState extends ConsumerState<NodeCard> {
  late final EventBus eventBus;

  late WalletSyncStatus? _currentSyncStatus;

  late StreamSubscription<dynamic>? _syncStatusSubscription;

  bool _isCurrentNode = false;

  Future<void> _notifyWalletsOfUpdatedNode(WidgetRef ref) async {
    final managers = [ref.read(walletProvider)!];
    final prefs = ref.read(prefsChangeNotifierProvider);

    switch (prefs.syncType) {
      case SyncingType.currentWalletOnly:
        for (final manager in managers) {
          if (manager.isActiveWallet) {
            manager.updateNode(true);
          } else {
            manager.updateNode(false);
          }
        }
        break;
      case SyncingType.selectedWalletsAtStartup:
        final List<String> walletIdsToSync = prefs.walletIdsSyncOnStartup;
        for (final manager in managers) {
          if (walletIdsToSync.contains(manager.walletId)) {
            manager.updateNode(true);
          } else {
            manager.updateNode(false);
          }
        }
        break;
      case SyncingType.allWalletsOnStartup:
        for (final manager in managers) {
          manager.updateNode(true);
        }
        break;
    }
  }

  Future<bool> _testConnection(
    NodeModel node,
    BuildContext context,
    WidgetRef ref,
  ) async {
    bool testPassed = false;

    switch (widget.coin) {
      case Coin.epicCash:
        try {
          final String uriString = "${node.host}:${node.port}/v1/version";

          testPassed = await testEpicBoxNodeConnection(Uri.parse(uriString));
        } catch (e, s) {
          Logging.instance.log("$e\n$s", level: LogLevel.Warning);
        }
        break;
    }

    if (testPassed) {
      // showFloatingFlushBar(
      //   type: FlushBarType.success,
      //   message: "Server ping success",
      //   context: context,
      // );
    } else {
      // unawaited(
      //   showFloatingFlushBar(
      //     type: FlushBarType.warning,
      //     iconAsset: Assets.svg.circleAlert,
      //     message: "Could not connect to node",
      //     context: context,
      //   ),
      // );
    }

    return testPassed;
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

    super.initState();
  }

  @override
  void dispose() {
    _syncStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = ref.watch(nodeServiceChangeNotifierProvider
        .select((value) => value.getPrimaryNodeFor(coin: widget.coin)));
    final _node = ref.watch(nodeServiceChangeNotifierProvider
        .select((value) => value.getNodeById(id: widget.nodeId)))!;

    _isCurrentNode = node?.name == _node.name;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(
                AddEditNodeView.routeName,
                arguments: Tuple4(
                  AddEditNodeViewType.edit,
                  Coin.epicCash,
                  widget.nodeId,
                  widget.popBackToRoute,
                ),
              );
            },
            child: Container(
              height: 48,
              color: Colors.transparent,
              child: Row(
                children: [
                  SvgPicture.asset(
                    Assets.svg.networkWired,
                    color: _isCurrentNode
                        ? _currentSyncStatus == WalletSyncStatus.unableToSync
                            ? Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorRed
                            : Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorGreen
                        : Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Text(
                    _node.name,
                    style: STextStyles.bodyBold(context).copyWith(
                      color: _isCurrentNode
                          ? _currentSyncStatus == WalletSyncStatus.unableToSync
                              ? Theme.of(context)
                                  .extension<StackColors>()!
                                  .accentColorRed
                              : Theme.of(context)
                                  .extension<StackColors>()!
                                  .accentColorGreen
                          : Theme.of(context)
                              .extension<StackColors>()!
                              .textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isCurrentNode && _currentSyncStatus != null)
          CurrentNodeStatusIcon(
            status: _currentSyncStatus!,
          ),
      ],
    );
  }
}

class CurrentNodeStatusIcon extends ConsumerWidget {
  const CurrentNodeStatusIcon({
    Key? key,
    required this.status,
  }) : super(key: key);

  final WalletSyncStatus status;

  Widget _getAsset(BuildContext context) {
    switch (status) {
      case WalletSyncStatus.unableToSync:
        return SvgPicture.asset(
          Assets.svg.refresh,
          color: Theme.of(context).extension<StackColors>()!.accentColorRed,
        );
      case WalletSyncStatus.synced:
      case WalletSyncStatus.syncing:
        return SvgPicture.asset(
          Assets.svg.check,
          color: Theme.of(context).extension<StackColors>()!.accentColorGreen,
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConditionalParent(
      condition: status == WalletSyncStatus.unableToSync,
      builder: (child) {
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: SizedBox(
            height: 48,
            child: IconButton(
              splashRadius: 24,
              icon: child,
              onPressed: ref.read(walletProvider)!.refresh,
            ),
          ),
        );
      },
      child: ConditionalParent(
        condition: status != WalletSyncStatus.unableToSync,
        builder: (child) => Padding(
          padding: const EdgeInsets.only(
            right: 24,
          ),
          child: child,
        ),
        child: _getAsset(context),
      ),
    );
  }
}
