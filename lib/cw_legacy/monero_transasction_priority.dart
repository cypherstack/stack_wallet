//import 'package:flutter_libmonero/generated/i18n.dart';
import 'package:stackwallet/cw_legacy/enumerable_item.dart';
import 'package:stackwallet/cw_legacy/wallet_type.dart';
abstract class TransactionPriority extends EnumerableItem<int?>
    with Serializable<int?> {
  const TransactionPriority({super.title, super.raw});
}
class MoneroTransactionPriority extends TransactionPriority {
  const MoneroTransactionPriority({super.title, super.raw});

  static const all = [
    MoneroTransactionPriority.slow,
    MoneroTransactionPriority.regular,
    MoneroTransactionPriority.medium,
    MoneroTransactionPriority.fast,
    MoneroTransactionPriority.fastest
  ];
  static const slow = MoneroTransactionPriority(title: 'Slow', raw: 0);
  static const regular = MoneroTransactionPriority(title: 'Regular', raw: 1);
  static const medium = MoneroTransactionPriority(title: 'Medium', raw: 2);
  static const fast = MoneroTransactionPriority(title: 'Fast', raw: 3);
  static const fastest = MoneroTransactionPriority(title: 'Fastest', raw: 4);
  static const standard = slow;

  static List<MoneroTransactionPriority> forWalletType(WalletType type) {
    switch (type) {
      case WalletType.monero:
        return MoneroTransactionPriority.all;
      case WalletType.bitcoin:
        return [
          MoneroTransactionPriority.slow,
          MoneroTransactionPriority.regular,
          MoneroTransactionPriority.fast
        ];
      default:
        return [];
    }
  }

  static MoneroTransactionPriority? deserialize({int? raw}) {
    switch (raw) {
      case 0:
        return slow;
      case 1:
        return regular;
      case 2:
        return medium;
      case 3:
        return fast;
      case 4:
        return fastest;
      default:
        return null;
    }
  }

  @override
  String toString() {
    switch (this) {
      case MoneroTransactionPriority.slow:
        return 'Slow'; // S.current.transaction_priority_slow;
      case MoneroTransactionPriority.regular:
        return 'Regular'; // S.current.transaction_priority_regular;
      case MoneroTransactionPriority.medium:
        return 'Medium'; // S.current.transaction_priority_medium;
      case MoneroTransactionPriority.fast:
        return 'Fast'; // S.current.transaction_priority_fast;
      case MoneroTransactionPriority.fastest:
        return 'Fastest'; // S.current.transaction_priority_fastest;
      default:
        return '';
    }
  }
}
