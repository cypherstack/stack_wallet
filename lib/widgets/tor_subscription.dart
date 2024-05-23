import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/event_bus/events/global/tor_connection_status_changed_event.dart';
import '../services/event_bus/global_event_bus.dart';

class TorSubscription extends ConsumerStatefulWidget {
  const TorSubscription({
    super.key,
    required this.onTorStatusChanged,
    this.eventBus,
    required this.child,
  });

  final Widget child;
  final void Function(TorConnectionStatus) onTorStatusChanged;
  final EventBus? eventBus;

  @override
  ConsumerState<TorSubscription> createState() => _TorSubscriptionBaseState();
}

class _TorSubscriptionBaseState extends ConsumerState<TorSubscription> {
  /// The global event bus.
  late final EventBus eventBus;

  /// Subscription to the TorConnectionStatusChangedEvent.
  late StreamSubscription<TorConnectionStatusChangedEvent>
      _torConnectionStatusSubscription;

  @override
  void initState() {
    // Initialize the global event bus.
    eventBus = widget.eventBus ?? GlobalEventBus.instance;

    // Subscribe to the TorConnectionStatusChangedEvent.
    _torConnectionStatusSubscription =
        eventBus.on<TorConnectionStatusChangedEvent>().listen(
      (event) async {
        widget.onTorStatusChanged.call(event.newStatus);
      },
    );

    super.initState();
  }

  @override
  void dispose() {
    // Clean up the TorConnectionStatusChangedEvent subscription.
    _torConnectionStatusSubscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
