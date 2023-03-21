import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/models/transaction_filter.dart';

final transactionFilterProvider =
    StateProvider<TransactionFilter?>((_) => null);
