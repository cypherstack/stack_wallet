import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/token_view/token_view.dart';
import 'package:stackwallet/providers/global/tokens_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';

import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:tuple/tuple.dart';

import 'package:stackwallet/providers/global/wallets_provider.dart';

import 'package:stackwallet/services/coins/manager.dart';

class MyTokenSelectItem extends ConsumerWidget {
  const MyTokenSelectItem(
      {Key? key,
      required this.managerProvider,
      required this.walletId,
      required this.walletAddress,
      required this.tokenData,
      required})
      : super(key: key);

  final ChangeNotifierProvider<Manager> managerProvider;
  final String walletId;
  final String walletAddress;
  final Map<String, String> tokenData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int balance = int.parse(tokenData["balance"] as String);
    int tokenDecimals = int.parse(tokenData["decimals"] as String);
    final balanceInDecimal = (balance / (pow(10, tokenDecimals)));

    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(0),
      child: MaterialButton(
        // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
        key: Key("walletListItemButtonKey_${tokenData["symbol"]}"),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(Constants.size.circularBorderRadius),
        ),
        onPressed: () {
          // ref
          //     .read(walletsChangeNotifierProvider)
          //     .getManagerProvider(walletId)

          // final walletId = ref
          //     .read(managerProvider)
          //     .walletName;
          // final manager =  ref
          //     .read(walletsChangeNotifierProvider)
          //     .getManagerProvider(walletId)

          // arguments: Tuple2(walletId, managerProvider,  walletAddress,
          //     tokenData["contractAddress"])

          // arguments: Tuple2(
          //     walletId,
          //     ref
          //         .read(tokensChangeNotifierProvider)
          //         .getManagerProvider(walletId)

          // arguments: Tuple2(
          //     walletId,
          //     ref
          //         .read(tokensChangeNotifierProvider)
          //         .getManagerProvider(walletId)

          Navigator.of(context).pushNamed(
            TokenView.routeName,
            arguments: Tuple2(
                walletId,
                ref.read(tokensChangeNotifierProvider).getManagerProvider(
                    tokenData["contractAddress"] as String)),
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
                            tokenData["name"] as String,
                            style: STextStyles.titleBold12(context),
                          ),
                          const Spacer(),
                          Text(
                            "$balanceInDecimal ${tokenData["symbol"]}",
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
                            tokenData["symbol"] as String,
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
