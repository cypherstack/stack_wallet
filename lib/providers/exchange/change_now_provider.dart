import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/services/change_now/change_now.dart';

final changeNowProvider = Provider<ChangeNow>((ref) => ChangeNow.instance);
