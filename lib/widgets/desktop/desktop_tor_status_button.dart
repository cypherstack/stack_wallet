import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/cli_commands.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_menu_item.dart';
import 'package:stackwallet/services/event_bus/events/global/tor_connection_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class DesktopTorStatusButton extends ConsumerStatefulWidget {
  const DesktopTorStatusButton({
    super.key,
    this.onPressed,
    required this.transitionDuration,
    this.controller,
    this.labelLength = 125,
  });

  final VoidCallback? onPressed;
  final Duration transitionDuration;
  final DMIController? controller;
  final double labelLength;

  @override
  ConsumerState<DesktopTorStatusButton> createState() =>
      _DesktopTorStatusButtonState();
}

class _DesktopTorStatusButtonState extends ConsumerState<DesktopTorStatusButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  late final DMIController? controller;
  late final double labelLength;

  /// The global event bus.
  late final EventBus eventBus;

  /// The subscription to the TorConnectionStatusChangedEvent.
  late final StreamSubscription<TorConnectionStatusChangedEvent>
      _torConnectionStatusSubscription;

  /// The current status of the Tor connection.
  late TorConnectionStatus _torConnectionStatus;

  Color _color(TorConnectionStatus status) {
    switch (status) {
      case TorConnectionStatus.disconnected:
        return Theme.of(context).extension<StackColors>()!.textSubtitle3;
      case TorConnectionStatus.connecting:
        return Theme.of(context).extension<StackColors>()!.accentColorYellow;
      case TorConnectionStatus.connected:
        return Theme.of(context).extension<StackColors>()!.accentColorGreen;
    }
  }

  bool _iconOnly = false;

  void toggle() {
    setState(() {
      _iconOnly = !_iconOnly;
    });
    if (_iconOnly) {
      animationController.reverse();
    } else {
      animationController.forward();
    }
  }

  @override
  void initState() {
    labelLength = widget.labelLength;
    controller = widget.controller;

    // Initialize the global event bus.
    eventBus = GlobalEventBus.instance;

    // Initialize the TorConnectionStatus.
    _torConnectionStatus = ref.read(pTorService).enabled
        ? TorConnectionStatus.connected
        : TorConnectionStatus.disconnected;

    // Subscribe to the TorConnectionStatusChangedEvent.
    _torConnectionStatusSubscription =
        eventBus.on<TorConnectionStatusChangedEvent>().listen(
      (event) async {
        // Rebuild the widget.
        setState(() {
          _torConnectionStatus = event.newStatus;
        });

        // TODO implement spinner or animations and control from here
        // switch (event.newStatus) {
        //   case TorConnectionStatus.disconnected:
        //     // if (_spinController.hasLoadedAnimation) {
        //     //   _spinController.stop?.call();
        //     // }
        //     break;
        //   case TorConnectionStatus.connecting:
        //     // if (_spinController.hasLoadedAnimation) {
        //     //   _spinController.repeat?.call();
        //     // }
        //     break;
        //   case TorConnectionStatus.connected:
        //     // if (_spinController.hasLoadedAnimation) {
        //     //   _spinController.stop?.call();
        //     // }
        //     break;
        // }
      },
    );

    controller?.toggle = toggle;
    animationController = AnimationController(
      vsync: this,
      duration: widget.transitionDuration,
    )..forward();

    super.initState();
  }

  @override
  void dispose() {
    // Clean up the subscription to the TorConnectionStatusChangedEvent.
    _torConnectionStatusSubscription.cancel();

    controller?.dispose();
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: Theme.of(context)
          .extension<StackColors>()!
          .getDesktopMenuButtonStyle(context),
      onPressed: widget.onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: widget.transitionDuration,
              width: _iconOnly ? 0 : 16,
            ),
            SvgPicture.asset(
              Assets.svg.tor,
              color: _color(_torConnectionStatus),
              width: 20,
              height: 20,
            ),
            AnimatedOpacity(
              duration: widget.transitionDuration,
              opacity: _iconOnly ? 0 : 1.0,
              child: SizeTransition(
                sizeFactor: animationController,
                axis: Axis.horizontal,
                axisAlignment: -1,
                child: SizedBox(
                  width: labelLength,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 12,
                      ),
                      Text(
                        _torConnectionStatus.name.capitalize(),
                        style: STextStyles.smallMed12(context).copyWith(
                          color: _color(_torConnectionStatus),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
