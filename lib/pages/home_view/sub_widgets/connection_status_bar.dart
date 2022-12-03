import 'dart:async';

import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/rounded_container.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/global/wallet_provider.dart';
import '../../../services/event_bus/events/global/node_connection_status_changed_event.dart';
import '../../../services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import '../../../services/event_bus/global_event_bus.dart';

class ConnectionStatusBar extends StatelessWidget {
  const ConnectionStatusBar({
    Key? key,
    required this.currentSyncPercent,
    required this.color,
    required this.background,
  }) : super(key: key);

  final double currentSyncPercent;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(1000)),
          child: RoundedContainer(
            padding: const EdgeInsets.all(0),
            height: constraints.maxHeight,
            width: constraints.maxWidth,
            color: background,
            radiusMultiplier: 1000,
            child: CustomPaint(
              size: Size(
                constraints.maxWidth,
                constraints.maxHeight,
              ),
              painter: ProgressPainter(
                percent: currentSyncPercent,
                color: color,
                background: background,
              ),
              child: const Center(
                child: ConnectionStatusInfo(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ConnectionStatusInfo extends ConsumerStatefulWidget {
  const ConnectionStatusInfo({Key? key, this.eventBus}) : super(key: key);

  final EventBus? eventBus;

  @override
  ConsumerState<ConnectionStatusInfo> createState() =>
      _ConnectionStatusInfoState();
}

class _ConnectionStatusInfoState extends ConsumerState<ConnectionStatusInfo> {
  late final EventBus eventBus;

  late WalletSyncStatus _currentSyncStatus;
  late NodeConnectionStatus _currentNodeStatus;

  late StreamSubscription<dynamic> _syncStatusSubscription;
  late StreamSubscription<dynamic> _nodeStatusSubscription;

  Color getSyncColor(WalletSyncStatus status) {
    switch (status) {
      case WalletSyncStatus.unableToSync:
        return Theme.of(context).extension<StackColors>()!.accentColorRed;

      case WalletSyncStatus.synced:
        return Theme.of(context).extension<StackColors>()!.accentColorGreen;
      case WalletSyncStatus.syncing:
        return Theme.of(context).extension<StackColors>()!.accentColorYellow;
    }
  }

  String label(WalletSyncStatus status) {
    switch (status) {
      case WalletSyncStatus.unableToSync:
        return "DISCONNECTED";
      case WalletSyncStatus.synced:
        return "CONNECTED";
      case WalletSyncStatus.syncing:
        return "SYNCHRONIZING";
    }
  }

  @override
  void initState() {
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

    eventBus = widget.eventBus ?? GlobalEventBus.instance;

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

    super.initState();
  }

  @override
  dispose() {
    _nodeStatusSubscription.cancel();
    _syncStatusSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        RoundedContainer(
          width: 6,
          height: 6,
          color: getSyncColor(_currentSyncStatus),
        ),
        Text(
          label(_currentSyncStatus),
          style: STextStyles.overLine(context),
        )
      ],
    );
  }
}

class ProgressPainter extends CustomPainter {
  final double percent;
  final Color color;
  final Color background;

  ProgressPainter({
    required this.percent,
    required this.color,
    required this.background,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.color = color;
    paint.strokeWidth = size.height;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width * percent, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    final oldPainter = (oldDelegate as ProgressPainter);
    return oldPainter.percent != percent ||
        oldPainter.background != background ||
        oldPainter.color != color;
  }
}
