import 'package:event_bus/event_bus.dart';

abstract class GlobalEventBus {
  static final instance = EventBus();
}
