import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/sub_widgets/mobile_coin_list.dart';

final addWalletSelectedEntityStateProvider =
    StateProvider.autoDispose<AddWalletListEntity?>((_) => null);
