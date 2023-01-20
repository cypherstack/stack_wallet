import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/paynym/paynym_account_lite.dart';

final selectedPaynymDetailsItemProvider =
    StateProvider.autoDispose<PaynymAccountLite?>((_) => null);
