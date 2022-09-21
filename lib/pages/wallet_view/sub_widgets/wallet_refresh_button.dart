import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';

/// [eventBus] should only be set during testing
class WalletRefreshButton extends ConsumerStatefulWidget {
  const WalletRefreshButton({
    Key? key,
    required this.walletId,
    required this.initialSyncStatus,
    this.onPressed,
    this.eventBus,
  }) : super(key: key);

  final String walletId;
  final WalletSyncStatus initialSyncStatus;
  final VoidCallback? onPressed;
  final EventBus? eventBus;

  @override
  ConsumerState<WalletRefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends ConsumerState<WalletRefreshButton>
    with TickerProviderStateMixin {
  late final EventBus eventBus;

  late AnimationController? _spinController;
  late Animation<double> _spinAnimation;

  late StreamSubscription<dynamic> _syncStatusSubscription;

  @override
  void initState() {
    _spinController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _spinAnimation = CurvedAnimation(
      parent: _spinController!,
      curve: Curves.linear,
    );

    if (widget.initialSyncStatus == WalletSyncStatus.syncing) {
      _spinController?.repeat();
    }

    eventBus =
        widget.eventBus != null ? widget.eventBus! : GlobalEventBus.instance;

    _syncStatusSubscription =
        eventBus.on<WalletSyncStatusChangedEvent>().listen(
      (event) async {
        if (event.walletId == widget.walletId) {
          switch (event.newStatus) {
            case WalletSyncStatus.unableToSync:
              _spinController?.stop();
              break;
            case WalletSyncStatus.synced:
              _spinController?.stop();
              break;
            case WalletSyncStatus.syncing:
              _spinController?.repeat();
              break;
          }
        }
      },
    );

    super.initState();
  }

  @override
  void dispose() {
    _spinController?.dispose();
    _spinController = null;

    _syncStatusSubscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      width: 36,
      child: MaterialButton(
        splashColor: StackTheme.instance.color.highlight,
        onPressed: () {
          final managerProvider = ref
              .read(walletsChangeNotifierProvider)
              .getManagerProvider(widget.walletId);
          final isRefreshing = ref.read(managerProvider).isRefreshing;
          if (!isRefreshing) {
            _spinController?.repeat();
            ref
                .read(managerProvider)
                .refresh()
                .then((_) => _spinController?.stop());
          }
        },
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
        ),
        child: RotationTransition(
          turns: _spinAnimation,
          child: SvgPicture.asset(
            Assets.svg.arrowRotate,
            width: 24,
            height: 24,
            color: StackTheme.instance.color.accentColorDark,
          ),
        ),
      ),
    );
  }
}
