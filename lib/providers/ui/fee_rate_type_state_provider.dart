import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/utilities/enums/fee_rate_type_enum.dart';

final feeRateTypeStateProvider =
    StateProvider.autoDispose<FeeRateType>((_) => FeeRateType.average);
