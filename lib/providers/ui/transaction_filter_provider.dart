import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/transaction_filter.dart';

final transactionFilterProvider =
    StateProvider<TransactionFilter?>((_) => null);
