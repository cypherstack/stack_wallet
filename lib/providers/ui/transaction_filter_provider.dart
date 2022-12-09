import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicpay/models/transaction_filter.dart';

final transactionFilterProvider =
    StateProvider<TransactionFilter?>((_) => null);
