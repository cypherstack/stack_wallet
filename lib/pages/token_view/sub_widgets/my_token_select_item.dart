import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/pages/token_view/token_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/desktop_token_view.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/ethereum/ethereum_wallet.dart';
import 'package:stackwallet/services/ethereum/cached_eth_token_balance.dart';
import 'package:stackwallet/services/ethereum/ethereum_token_service.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/show_loading.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/icon_widgets/eth_token_icon.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class MyTokenSelectItem extends ConsumerStatefulWidget {
  const MyTokenSelectItem({
    Key? key,
    required this.walletId,
    required this.token,
  }) : super(key: key);

  final String walletId;
  final EthContract token;

  @override
  ConsumerState<MyTokenSelectItem> createState() => _MyTokenSelectItemState();
}

class _MyTokenSelectItemState extends ConsumerState<MyTokenSelectItem> {
  final bool isDesktop = Util.isDesktop;

  late final CachedEthTokenBalance cachedBalance;

  void _onPressed() async {
    ref.read(tokenServiceStateProvider.state).state = EthTokenWallet(
      token: widget.token,
      secureStore: ref.read(secureStoreProvider),
      ethWallet: ref
          .read(walletsChangeNotifierProvider)
          .getManager(widget.walletId)
          .wallet as EthereumWallet,
      tracker: TransactionNotificationTracker(
        walletId: widget.walletId,
      ),
    );

    await showLoading<void>(
      whileFuture: ref.read(tokenServiceProvider)!.initialize(),
      context: context,
      isDesktop: isDesktop,
      message: "Loading ${widget.token.name}",
    );

    if (mounted) {
      await Navigator.of(context).pushNamed(
        isDesktop ? DesktopTokenView.routeName : TokenView.routeName,
        arguments: widget.walletId,
      );
    }
  }

  @override
  void initState() {
    cachedBalance = CachedEthTokenBalance(widget.walletId, widget.token);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final address = await ref
          .read(walletsChangeNotifierProvider)
          .getManager(widget.walletId)
          .currentReceivingAddress;
      await cachedBalance.fetchAndUpdateCachedBalance(address);
      if (mounted) {
        setState(() {});
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(0),
      child: MaterialButton(
        key: Key("walletListItemButtonKey_${widget.token.symbol}"),
        padding: isDesktop
            ? const EdgeInsets.symmetric(horizontal: 28, vertical: 24)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(Constants.size.circularBorderRadius),
        ),
        onPressed: _onPressed,
        child: Row(
          children: [
            EthTokenIcon(
              contractAddress: widget.token.address,
              size: isDesktop ? 32 : 28,
            ),
            SizedBox(
              width: isDesktop ? 12 : 10,
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
                            widget.token.name,
                            style: isDesktop
                                ? STextStyles.desktopTextExtraSmall(context)
                                : STextStyles.titleBold12(context),
                          ),
                          const Spacer(),
                          Text(
                            "${cachedBalance.getCachedBalance().total.localizedStringAsFixed(
                                  locale: ref.watch(
                                    localeServiceChangeNotifierProvider.select(
                                      (value) => value.locale,
                                    ),
                                  ),
                                )} "
                            "${widget.token.symbol}",
                            style: isDesktop
                                ? STextStyles.desktopTextExtraSmall(context)
                                : STextStyles.itemSubtitle(context),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Row(
                        children: [
                          Text(
                            widget.token.symbol,
                            style: isDesktop
                                ? STextStyles.desktopTextExtraExtraSmall(
                                    context)
                                : STextStyles.itemSubtitle(context),
                          ),
                          const Spacer(),
                          Text(
                            "${ref.watch(
                              priceAnd24hChangeNotifierProvider.select(
                                (value) => value
                                    .getTokenPrice(widget.token.address)
                                    .item1
                                    .toStringAsFixed(2),
                              ),
                            )} "
                            "${ref.watch(
                              prefsChangeNotifierProvider.select(
                                (value) => value.currency,
                              ),
                            )}",
                            style: isDesktop
                                ? STextStyles.desktopTextExtraExtraSmall(
                                    context)
                                : STextStyles.itemSubtitle(context),
                          ),
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
