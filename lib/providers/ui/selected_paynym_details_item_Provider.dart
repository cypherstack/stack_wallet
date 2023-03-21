import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/models/paynym/paynym_account_lite.dart';

final selectedPaynymDetailsItemProvider =
    StateProvider.autoDispose<PaynymAccountLite?>((_) => null);
