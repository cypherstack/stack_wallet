import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/ethereum/ethereum_wallet.dart';
import 'package:stackwallet/services/coins/firo/firo_wallet.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';

class WalletInfoRowBalance extends ConsumerWidget {
  const WalletInfoRowBalance({
    Key? key,
    required this.walletId,
    this.contractAddress,
  }) : super(key: key);

  final String walletId;
  final String? contractAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(ref
        .watch(walletsChangeNotifierProvider.notifier)
        .getManagerProvider(walletId));

    final locale = ref.watch(
      localeServiceChangeNotifierProvider.select(
        (value) => value.locale,
      ),
    );

    Decimal balance;
    int decimals;
    String unit;
    if (contractAddress == null) {
      balance = manager.balance.getTotal();
      if (manager.coin == Coin.firo || manager.coin == Coin.firoTestNet) {
        balance += (manager.wallet as FiroWallet).balancePrivate.getTotal();
      }
      unit = manager.coin.ticker;
      decimals = manager.coin.decimals;
    } else {
      final ethWallet = manager.wallet as EthereumWallet;
      final contract = MainDB.instance.getEthContractSync(contractAddress!)!;
      balance = ethWallet.getCachedTokenBalance(contract).getTotal();
      unit = contract.symbol;
      decimals = contract.decimals;
    }

    return Text(
      "${Format.localizedStringAsFixed(
        value: balance,
        locale: locale,
        decimalPlaces: decimals,
      )} $unit",
      style: Util.isDesktop
          ? STextStyles.desktopTextExtraSmall(context).copyWith(
              color: Theme.of(context).extension<StackColors>()!.textSubtitle1,
            )
          : STextStyles.itemSubtitle(context),
    );
  }
}
