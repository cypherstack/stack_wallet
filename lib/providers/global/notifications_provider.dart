import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/services/notifications_service.dart';

final notificationsProvider =
    ChangeNotifierProvider((_) => NotificationsService.instance);
