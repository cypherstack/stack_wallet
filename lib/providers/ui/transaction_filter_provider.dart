import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicmobile/models/transaction_filter.dart';

final transactionFilterProvider =
    StateProvider<TransactionFilter?>((_) => null);
