import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/ethereum/eth_token.dart';
import 'package:stackwallet/pages/token_view/token_view.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/services/coins/ethereum/ethereum_wallet.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/ethereum/ethereum_token_service.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/show_loading.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class MyTokenSelectItem extends ConsumerWidget {
  const MyTokenSelectItem(
      {Key? key,
      required this.managerProvider,
      required this.walletId,
      required this.walletAddress,
      required this.token,
      required})
      : super(key: key);

  final ChangeNotifierProvider<Manager> managerProvider;
  final String walletId;
  final String walletAddress;
  final EthToken token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceInDecimal = Format.satoshisToEthTokenAmount(
      token.balance,
      token.decimals,
    );

    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(0),
      child: MaterialButton(
        // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
        key: Key("walletListItemButtonKey_${token.symbol}"),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(Constants.size.circularBorderRadius),
        ),
        onPressed: () async {
          ref.read(tokenServiceStateProvider.state).state =
              EthereumTokenService(
            token: token,
            secureStore: ref.read(secureStoreProvider),
            ethWallet: ref.read(managerProvider).wallet as EthereumWallet,
            tracker: TransactionNotificationTracker(
              walletId: ref.read(managerProvider).walletId,
            ),
          );

          await showLoading<void>(
            whileFuture: ref.read(tokenServiceProvider)!.initializeExisting(),
            context: context,
            message: "Loading ${token.name}",
          );

          await Navigator.of(context).pushNamed(
            TokenView.routeName,
            arguments: walletId,
          );
        },

        child: Row(
          children: [
            SvgPicture.asset(
              Assets.svg.iconFor(coin: Coin.ethereum),
              width: 28,
              height: 28,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Consumer(
                builder: (_, ref, __) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            token.name,
                            style: STextStyles.titleBold12(context),
                          ),
                          const Spacer(),
                          Text(
                            "$balanceInDecimal ${token.symbol}",
                            style: STextStyles.itemSubtitle(context),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 1,
                      ),
                      Row(
                        children: [
                          Text(
                            token.symbol,
                            style: STextStyles.itemSubtitle(context),
                          ),
                          const Spacer(),
                          const Text("0 USD"),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
