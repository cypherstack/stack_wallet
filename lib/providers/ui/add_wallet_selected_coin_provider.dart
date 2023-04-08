import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/add_wallet_list_entity/add_wallet_list_entity.dart';

final addWalletSelectedEntityStateProvider =
    StateProvider.autoDispose<AddWalletListEntity?>((_) => null);
