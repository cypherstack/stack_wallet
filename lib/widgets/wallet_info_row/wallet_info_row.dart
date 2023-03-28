import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/pages/token_view/sub_widgets/token_summary.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/wallet_info_row/sub_widgets/wallet_info_row_balance_future.dart';
import 'package:stackwallet/widgets/wallet_info_row/sub_widgets/wallet_info_row_coin_icon.dart';

class WalletInfoRow extends ConsumerWidget {
  const WalletInfoRow({
    Key? key,
    required this.walletId,
    this.onPressedDesktop,
    this.contractAddress,
    this.padding = const EdgeInsets.all(0),
  }) : super(key: key);

  final String walletId;
  final String? contractAddress;
  final VoidCallback? onPressedDesktop;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(ref
        .watch(walletsChangeNotifierProvider.notifier)
        .getManagerProvider(walletId));

    EthContract? contract;
    if (contractAddress != null) {
      contract = ref.watch(mainDBProvider
          .select((value) => value.getEthContractSync(contractAddress!)));
    }

    if (Util.isDesktop) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onPressedDesktop,
          child: Padding(
            padding: padding,
            child: Container(
              color: Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        WalletInfoCoinIcon(
                          coin: manager.coin,
                          contractAddress: contractAddress,
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Text(
                          manager.walletName,
                          style: STextStyles.desktopTextExtraSmall(context)
                              .copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: WalletInfoRowBalance(
                      walletId: walletId,
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SvgPicture.asset(
                          Assets.svg.chevronRight,
                          width: 20,
                          height: 20,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textSubtitle1,
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return Row(
        children: [
          WalletInfoCoinIcon(
            coin: manager.coin,
            contractAddress: contractAddress,
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                contract != null
                    ? Row(
                        children: [
                          Text(
                            contract.name,
                            style: STextStyles.titleBold12(context),
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          CoinTickerTag(
                            walletId: walletId,
                          ),
                        ],
                      )
                    : Text(
                        manager.walletName,
                        style: STextStyles.titleBold12(context),
                      ),
                const SizedBox(
                  height: 2,
                ),
                WalletInfoRowBalance(
                  walletId: walletId,
                  contractAddress: contractAddress,
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}
