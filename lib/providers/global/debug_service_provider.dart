import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicmobile/services/debug_service.dart';

final debugServiceProvider =
    ChangeNotifierProvider<DebugService>((ref) => DebugService.instance);
