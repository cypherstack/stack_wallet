import 'package:epicpay/services/coins/manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final walletStateProvider = StateProvider<Manager?>((ref) => null);

final walletProvider = ChangeNotifierProvider<Manager?>(
    (ref) => ref.watch(walletStateProvider.state).state);
