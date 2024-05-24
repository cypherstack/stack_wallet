import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../wallet/impl/sub_wallets/eth_token_wallet.dart';

final tokenServiceStateProvider = StateProvider<EthTokenWallet?>((ref) => null);

final pCurrentTokenWallet =
    Provider<EthTokenWallet?>((ref) => ref.watch(tokenServiceStateProvider));
