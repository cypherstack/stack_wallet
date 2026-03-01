import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../app_config.dart';
import '../../models/isar/models/blockchain_data/address.dart';
import '../../models/isar/models/ethereum/eth_contract.dart';
import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../providers/providers.dart';
import '../../route_generator.dart';
import '../../themes/coin_icon_provider.dart';
import '../../themes/stack_colors.dart';
import '../../themes/theme_providers.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/amount/amount_formatter.dart';
import '../../utilities/constants.dart';
import '../../utilities/enums/fee_rate_type_enum.dart';
import '../../utilities/logger.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../../wallets/isar/providers/eth/token_balance_provider.dart';
import '../../wallets/isar/providers/wallet_info_provider.dart';
import '../../wallets/models/tx_data.dart';
import '../../services/shopinbit/shopinbit_service.dart';
import '../../wallets/wallet/impl/ethereum_wallet.dart';
import '../../wallets/wallet/intermediate/external_wallet.dart';
import '../../wallets/wallet/wallet.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_dialog.dart';
import '../../pages_desktop_specific/desktop_home_view.dart';
import '../home_view/home_view.dart';
import '../send_view/sub_widgets/building_transaction_dialog.dart';
import 'shopinbit_confirm_send_view.dart';

class ShopInBitSendFromView extends ConsumerStatefulWidget {
  const ShopInBitSendFromView({
    super.key,
    required this.coin,
    required this.model,
    this.amount,
    required this.address,
    this.shouldPopRoot = false,
    this.tokenContract,
  });

  static const String routeName = "/shopInBitSendFrom";

  final CryptoCurrency coin;
  final Amount? amount;
  final String address;
  final ShopInBitOrderModel model;
  final bool shouldPopRoot;
  final EthContract? tokenContract;

  @override
  ConsumerState<ShopInBitSendFromView> createState() =>
      _ShopInBitSendFromViewState();
}

class _ShopInBitSendFromViewState extends ConsumerState<ShopInBitSendFromView> {
  late final CryptoCurrency coin;
  late final Amount? amount;
  late final String address;
  late final ShopInBitOrderModel model;
  late final EthContract? tokenContract;

  @override
  void initState() {
    coin = widget.coin;
    address = widget.address;
    amount = widget.amount;
    model = widget.model;
    tokenContract = widget.tokenContract;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> walletIds;
    if (tokenContract != null) {
      walletIds = ref
          .watch(pWallets)
          .wallets
          .where(
            (w) =>
                w.info.coin == coin &&
                w.info.tokenContractAddresses.contains(tokenContract!.address),
          )
          .map((e) => e.walletId)
          .toList();
    } else {
      walletIds = ref
          .watch(pWallets)
          .wallets
          .where((e) => e.info.coin == coin)
          .map((e) => e.walletId)
          .toList();
    }

    final isDesktop = Util.isDesktop;

    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) {
        return Background(
          child: Scaffold(
            backgroundColor: Theme.of(
              context,
            ).extension<StackColors>()!.background,
            appBar: AppBar(
              leading: AppBarBackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Text("Send from", style: STextStyles.navBarTitle(context)),
            ),
            body: SafeArea(
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            ),
          ),
        );
      },
      child: ConditionalParent(
        condition: isDesktop,
        builder: (child) => DesktopDialog(
          maxHeight: double.infinity,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Text(
                      "Send from ${AppConfig.prefix}",
                      style: STextStyles.desktopH3(context),
                    ),
                  ),
                  DesktopDialogCloseButton(
                    onPressedOverride: Navigator.of(
                      context,
                      rootNavigator: widget.shouldPopRoot,
                    ).pop,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 32, right: 32, bottom: 32),
                child: child,
              ),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  amount != null
                      ? tokenContract != null
                            ? "You need to send ${amount!.decimal.toStringAsFixed(tokenContract!.decimals)} ${tokenContract!.symbol}"
                            : "You need to send ${ref.watch(pAmountFormatter(coin)).format(amount!)}"
                      : "Select a wallet to pay",
                  style: isDesktop
                      ? STextStyles.desktopTextExtraExtraSmall(context)
                      : STextStyles.itemSubtitle(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ConditionalParent(
              condition: !isDesktop,
              builder: (child) => Expanded(child: child),
              child: ListView.builder(
                primary: isDesktop ? false : null,
                shrinkWrap: isDesktop,
                itemCount: walletIds.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ShopInBitSendFromCard(
                      walletId: walletIds[index],
                      amount: amount,
                      address: address,
                      model: model,
                      tokenContract: tokenContract,
                    ),
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

class ShopInBitSendFromCard extends ConsumerStatefulWidget {
  const ShopInBitSendFromCard({
    super.key,
    required this.walletId,
    this.amount,
    required this.address,
    required this.model,
    this.tokenContract,
  });

  final String walletId;
  final Amount? amount;
  final String address;
  final ShopInBitOrderModel model;
  final EthContract? tokenContract;

  @override
  ConsumerState<ShopInBitSendFromCard> createState() =>
      _ShopInBitSendFromCardState();
}

class _ShopInBitSendFromCardState extends ConsumerState<ShopInBitSendFromCard> {
  late final String walletId;
  late final Amount? amount;
  late final String address;
  late final ShopInBitOrderModel model;
  late final EthContract? tokenContract;

  Future<void> _send() async {
    final coin = ref.read(pWalletCoin(walletId));

    final int fractionDigits = tokenContract != null
        ? tokenContract!.decimals
        : coin.fractionDigits;

    Amount? sendAmount = amount;
    if (sendAmount == null) {
      if (ShopInBitService.instance.client.sandbox) {
        sendAmount = Amount(
          rawValue: BigInt.from(10000),
          fractionDigits: fractionDigits,
        );
      } else {
        await showDialog<dynamic>(
          context: context,
          useSafeArea: false,
          barrierDismissible: true,
          builder: (context) {
            return StackDialog(
              title: "Transaction failed",
              message: "Payment amount not available yet",
              rightButton: TextButton(
                style: Theme.of(context)
                    .extension<StackColors>()!
                    .getSecondaryEnabledButtonStyle(context),
                child: Text(
                  "Ok",
                  style: STextStyles.button(context).copyWith(
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.buttonTextSecondary,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            );
          },
        );
        return;
      }
    }

    bool wasCancelled = false;

    try {
      final parentWallet = ref.read(pWallets).getWallet(walletId);

      unawaited(
        showDialog<dynamic>(
          context: context,
          useSafeArea: false,
          barrierDismissible: false,
          builder: (context) {
            return ConditionalParent(
              condition: Util.isDesktop,
              builder: (child) => DesktopDialog(
                maxWidth: 400,
                maxHeight: double.infinity,
                child: Padding(padding: const EdgeInsets.all(32), child: child),
              ),
              child: BuildingTransactionDialog(
                coin: coin,
                isSpark: false,
                onCancel: () {
                  wasCancelled = true;

                  Navigator.of(context).pop();
                },
              ),
            );
          },
        ),
      );

      if (parentWallet is ExternalWallet) {
        await parentWallet.init();
        await parentWallet.open();
      }

      final time = Future<dynamic>.delayed(const Duration(milliseconds: 2500));

      TxData txData;

      // Use token wallet for ERC-20 tokens, parent wallet otherwise
      final wallet = tokenContract != null
          ? Wallet.loadTokenWallet(
              ethWallet: parentWallet as EthereumWallet,
              contract: tokenContract!,
            )
          : parentWallet;

      if (tokenContract != null) {
        await wallet.init();
      }

      final addressType =
          wallet.cryptoCurrency.getAddressType(address) ??
          parentWallet.cryptoCurrency.getAddressType(address) ??
          AddressType.ethereum;

      final recipient = TxRecipient(
        address: address,
        amount: sendAmount,
        isChange: false,
        addressType: addressType,
      );

      final txDataFuture = wallet.prepareSend(
        txData: TxData(
          recipients: [recipient],
          feeRateType: FeeRateType.average,
        ),
      );

      final results = await Future.wait([txDataFuture, time]);

      txData = results.first as TxData;

      if (!wasCancelled) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        txData = txData.copyWith(note: "ShopInBit payment");

        if (mounted) {
          await Navigator.of(context).push(
            RouteGenerator.getRoute<dynamic>(
              shouldUseMaterialRoute: RouteGenerator.useMaterialPageRoute,
              builder: (_) => ShopInBitConfirmSendView(
                txData: txData,
                walletId: walletId,
                routeOnSuccessName: Util.isDesktop
                    ? DesktopHomeView.routeName
                    : HomeView.routeName,
                model: model,
                tokenContract: tokenContract,
              ),
              settings: const RouteSettings(
                name: ShopInBitConfirmSendView.routeName,
              ),
            ),
          );
        }
      }
    } catch (e, s) {
      Logging.instance.e("$e\n$s", error: e, stackTrace: s);
      if (mounted && !wasCancelled) {
        Navigator.of(context, rootNavigator: true).pop();

        await showDialog<dynamic>(
          context: context,
          useSafeArea: false,
          barrierDismissible: true,
          builder: (context) {
            return StackDialog(
              title: "Transaction failed",
              message: e.toString(),
              rightButton: TextButton(
                style: Theme.of(context)
                    .extension<StackColors>()!
                    .getSecondaryEnabledButtonStyle(context),
                child: Text(
                  "Ok",
                  style: STextStyles.button(context).copyWith(
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.buttonTextSecondary,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            );
          },
        );
      }
    }
  }

  @override
  void initState() {
    walletId = widget.walletId;
    amount = widget.amount;
    address = widget.address;
    model = widget.model;
    tokenContract = widget.tokenContract;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final coin = ref.watch(pWalletCoin(walletId));

    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(0),
      child: MaterialButton(
        splashColor: Theme.of(context).extension<StackColors>()!.highlight,
        key: Key("walletsSheetItemButtonKey_$walletId"),
        padding: const EdgeInsets.all(8),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
        ),
        onPressed: () async {
          if (mounted) {
            unawaited(_send());
          }
        },
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: ref.watch(pCoinColor(coin)).withOpacity(0.5),
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: SvgPicture.file(
                  File(ref.watch(coinIconProvider(coin))),
                  width: 24,
                  height: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tokenContract != null
                        ? "${ref.watch(pWalletName(walletId))} (${tokenContract!.symbol})"
                        : ref.watch(pWalletName(walletId)),
                    style: STextStyles.titleBold12(context),
                  ),
                  const SizedBox(height: 2),
                  if (tokenContract != null)
                    Builder(
                      builder: (context) {
                        final balance = ref.watch(
                          pTokenBalance((
                            walletId: walletId,
                            contractAddress: tokenContract!.address,
                          )),
                        );
                        return Text(
                          "${balance.spendable.decimal.toStringAsFixed(tokenContract!.decimals)} ${tokenContract!.symbol}",
                          style: STextStyles.itemSubtitle(context),
                        );
                      },
                    )
                  else
                    Text(
                      ref
                          .watch(pAmountFormatter(coin))
                          .format(
                            ref.watch(pWalletBalance(walletId)).spendable,
                          ),
                      style: STextStyles.itemSubtitle(context),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
