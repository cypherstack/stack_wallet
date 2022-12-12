import 'dart:async';

import 'package:epicpay/models/node_model.dart';
import 'package:epicpay/pages/settings_views/network_settings_view/manage_nodes_views/add_edit_node_view.dart';
import 'package:epicpay/providers/providers.dart';
import 'package:epicpay/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:epicpay/services/event_bus/global_event_bus.dart';
import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/enums/coin_enum.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/widgets/conditional_parent.dart';
import 'package:epicpay/widgets/rounded_container.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tuple/tuple.dart';

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

  void showContextMenu(NodeModel node, bool isConnected, Offset tapPosition) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => NodeMenu(
        node: node,
        popBackToRoute: widget.popBackToRoute,
        isConnected: isConnected,
        tapPosition: tapPosition,
      ),
    );
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
            onTapDown: (tapDetails) {
              showContextMenu(_node, _isCurrentNode, tapDetails.globalPosition);
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

class NodeMenu extends ConsumerStatefulWidget {
  const NodeMenu({
    Key? key,
    required this.node,
    required this.popBackToRoute,
    required this.isConnected,
    required this.tapPosition,
  }) : super(key: key);

  final NodeModel node;
  final String popBackToRoute;
  final bool isConnected;
  final Offset tapPosition;

  @override
  ConsumerState<NodeMenu> createState() => _NodeMenuState();
}

class _NodeMenuState extends ConsumerState<NodeMenu> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IgnorePointer(
          child: Container(
            color: Colors.transparent,
          ),
        ),
        Positioned(
          top: widget.tapPosition.dy - 40,
          left: widget.tapPosition.dx,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 160,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return RoundedContainer(
                  padding: const EdgeInsets.all(8),
                  color: Theme.of(context).extension<StackColors>()!.coal,
                  child: Column(
                    children: [
                      if (!widget.isConnected)
                        GestureDetector(
                          onTap: () async {
                            await ref
                                .read(nodeServiceChangeNotifierProvider)
                                .setPrimaryNodeFor(
                                  coin: Coin.epicCash,
                                  node: widget.node,
                                );
                            await ref.read(walletProvider)!.updateNode(true);
                            if (mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Container(
                            color: Colors.transparent,
                            width: constraints.minWidth,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "Connect",
                                style: STextStyles.body(context),
                              ),
                            ),
                          ),
                        ),
                      if (!widget.isConnected)
                        const SizedBox(
                          height: 16,
                        ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(
                            AddEditNodeView.routeName,
                            arguments: Tuple4(
                              AddEditNodeViewType.edit,
                              Coin.epicCash,
                              widget.node.id,
                              widget.popBackToRoute,
                            ),
                          );
                        },
                        child: Container(
                          color: Colors.transparent,
                          width: constraints.minWidth,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "Edit",
                              style: STextStyles.body(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );

    return Column(
      children: [
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 160,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return RoundedContainer(
                      padding: const EdgeInsets.all(8),
                      color: Theme.of(context).extension<StackColors>()!.coal,
                      child: Column(
                        children: [
                          if (!widget.isConnected)
                            GestureDetector(
                              onTap: () async {
                                await ref
                                    .read(nodeServiceChangeNotifierProvider)
                                    .setPrimaryNodeFor(
                                      coin: Coin.epicCash,
                                      node: widget.node,
                                    );
                                await ref
                                    .read(walletProvider)!
                                    .updateNode(true);
                                if (mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              child: Container(
                                color: Colors.transparent,
                                width: constraints.minWidth,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    "Connect",
                                    style: STextStyles.body(context),
                                  ),
                                ),
                              ),
                            ),
                          if (!widget.isConnected)
                            const SizedBox(
                              height: 16,
                            ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pushNamed(
                                AddEditNodeView.routeName,
                                arguments: Tuple4(
                                  AddEditNodeViewType.edit,
                                  Coin.epicCash,
                                  widget.node.id,
                                  widget.popBackToRoute,
                                ),
                              );
                            },
                            child: Container(
                              color: Colors.transparent,
                              width: constraints.minWidth,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "Edit",
                                  style: STextStyles.body(context),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(
              width: 20,
            ),
          ],
        ),
      ],
    );
  }
}
