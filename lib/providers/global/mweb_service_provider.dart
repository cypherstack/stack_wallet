import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/mwebd_service.dart';

final pMwebService = StateProvider<MwebdService>(
  (ref) => MwebdService.instance,
);
