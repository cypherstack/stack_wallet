import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicmobile/services/auto_swb_service.dart';

final autoSWBServiceProvider =
    ChangeNotifierProvider<AutoSWBService>((_) => AutoSWBService());
