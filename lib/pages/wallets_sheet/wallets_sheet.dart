import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/wallet_card.dart';

class WalletsSheet extends ConsumerWidget {
  const WalletsSheet({
    Key? key,
    required this.coin,
  }) : super(key: key);

  final Coin coin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManagerProvidersByCoin()))[coin];

    final maxHeight = MediaQuery.of(context).size.height * 0.60;

    return Container(
      decoration: BoxDecoration(
        color: StackTheme.instance.color.popupBG,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: LimitedBox(
        maxHeight: maxHeight,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 10,
            bottom: 0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: StackTheme.instance.color.textFieldDefaultBG,
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                  ),
                  width: 60,
                  height: 4,
                ),
              ),
              const SizedBox(
                height: 36,
              ),
              Text(
                "${coin.prettyName} (${coin.ticker}) wallets",
                style: STextStyles.pageTitleH2(context),
                textAlign: TextAlign.left,
              ),
              const SizedBox(
                height: 16,
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: providers!.length,
                  itemBuilder: (builderContext, index) {
                    final walletId = ref.watch(
                        providers[index].select((value) => value.walletId));
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: WalletSheetCard(
                        walletId: walletId,
                        popPrevious: true,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(
                height: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
