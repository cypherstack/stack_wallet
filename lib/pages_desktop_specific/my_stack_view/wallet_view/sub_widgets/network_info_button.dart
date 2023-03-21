import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackduo/pages/settings_views/wallet_settings_view/wallet_network_settings_view/wallet_network_settings_view.dart';
import 'package:stackduo/providers/providers.dart';
import 'package:stackduo/route_generator.dart';
import 'package:stackduo/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:stackduo/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackduo/services/event_bus/global_event_bus.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/utilities/util.dart';
import 'package:stackduo/widgets/desktop/desktop_dialog.dart';
import 'package:stackduo/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:tuple/tuple.dart';

class NetworkInfoButton extends ConsumerStatefulWidget {
  const NetworkInfoButton({
    Key? key,
    required this.walletId,
    this.eventBus,
  }) : super(key: key);

  final String walletId;
  final EventBus? eventBus;

  @override
  ConsumerState<NetworkInfoButton> createState() => _NetworkInfoButtonState();
}

class _NetworkInfoButtonState extends ConsumerState<NetworkInfoButton> {
  late final String walletId;
  late final EventBus eventBus;

  late WalletSyncStatus _currentSyncStatus;
  late NodeConnectionStatus _currentNodeStatus;

  late StreamSubscription<dynamic> _syncStatusSubscription;
  late StreamSubscription<dynamic> _nodeStatusSubscription;

  @override
  void initState() {
    walletId = widget.walletId;
    final managerProvider =
        ref.read(walletsChangeNotifierProvider).getManagerProvider(walletId);

    eventBus =
        widget.eventBus != null ? widget.eventBus! : GlobalEventBus.instance;

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

  Widget _buildNetworkIcon(WalletSyncStatus status, BuildContext context) {
    const size = 24.0;
    final color = _getColor(status, context);
    switch (status) {
      case WalletSyncStatus.unableToSync:
        return SvgPicture.asset(
          Assets.svg.radioProblem,
          color: color,
          width: size,
          height: size,
        );
      case WalletSyncStatus.synced:
        return SvgPicture.asset(
          Assets.svg.radio,
          color: color,
          width: size,
          height: size,
        );
      case WalletSyncStatus.syncing:
        return SvgPicture.asset(
          Assets.svg.radioSyncing,
          color: color,
          width: size,
          height: size,
        );
    }
  }

  Widget _buildText(WalletSyncStatus status, BuildContext context) {
    String label;

    switch (status) {
      case WalletSyncStatus.unableToSync:
        label = "Unable to sync";
        break;
      case WalletSyncStatus.synced:
        label = "Synchronized";
        break;
      case WalletSyncStatus.syncing:
        label = "Synchronizing";
        break;
    }

    return Text(
      label,
      style: STextStyles.desktopMenuItemSelected(context).copyWith(
        color: _getColor(status, context),
      ),
    );
  }

  Color _getColor(WalletSyncStatus status, BuildContext context) {
    switch (status) {
      case WalletSyncStatus.unableToSync:
        return Theme.of(context).extension<StackColors>()!.accentColorRed;
      case WalletSyncStatus.synced:
        return Theme.of(context).extension<StackColors>()!.accentColorGreen;
      case WalletSyncStatus.syncing:
        return Theme.of(context).extension<StackColors>()!.accentColorYellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      hoverColor: _getColor(_currentSyncStatus, context).withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(1000),
      ),
      onPressed: () {
        if (Util.isDesktop) {
          // showDialog<void>(
          //   context: context,
          //   builder: (context) => DesktopDialog(
          //     maxHeight: MediaQuery.of(context).size.height - 64,
          //     maxWidth: 580,
          //     child: Column(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Padding(
          //           padding: const EdgeInsets.only(
          //             left: 32,
          //           ),
          //           child: Row(
          //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //             children: [
          //               Text(
          //                 "Network",
          //                 style: STextStyles.desktopH3(context),
          //               ),
          //               const DesktopDialogCloseButton(),
          //             ],
          //           ),
          //         ),
          //         Padding(
          //           padding: const EdgeInsets.only(
          //             top: 16,
          //             left: 32,
          //             right: 32,
          //             bottom: 32,
          //           ),
          //           child: WalletNetworkSettingsView(
          //             walletId: walletId,
          //             initialSyncStatus: _currentSyncStatus,
          //             initialNodeStatus: _currentNodeStatus,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // );

          showDialog<void>(
            context: context,
            builder: (context) => Navigator(
              initialRoute: WalletNetworkSettingsView.routeName,
              onGenerateRoute: RouteGenerator.generateRoute,
              onGenerateInitialRoutes: (_, __) {
                return [
                  FadePageRoute(
                    DesktopDialog(
                      maxHeight: MediaQuery.of(context).size.height - 64,
                      maxWidth: 580,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 32,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Network",
                                  style: STextStyles.desktopH3(context),
                                ),
                                DesktopDialogCloseButton(
                                  onPressedOverride: Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 16,
                              left: 32,
                              right: 32,
                              bottom: 32,
                            ),
                            child: WalletNetworkSettingsView(
                              walletId: walletId,
                              initialSyncStatus: _currentSyncStatus,
                              initialNodeStatus: _currentNodeStatus,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const RouteSettings(
                      name: WalletNetworkSettingsView.routeName,
                    ),
                  ),
                ];
              },
            ),
          );
        } else {
          Navigator.of(context).pushNamed(
            WalletNetworkSettingsView.routeName,
            arguments: Tuple3(
              walletId,
              _currentSyncStatus,
              _currentNodeStatus,
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 32,
        ),
        child: Row(
          children: [
            _buildNetworkIcon(_currentSyncStatus, context),
            const SizedBox(
              width: 6,
            ),
            _buildText(_currentSyncStatus, context),
          ],
        ),
      ),
    );
  }
}
