import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/services/exchange/change_now/change_now_api.dart';

final changeNowProvider =
    Provider<ChangeNowAPI>((ref) => ChangeNowAPI.instance);
