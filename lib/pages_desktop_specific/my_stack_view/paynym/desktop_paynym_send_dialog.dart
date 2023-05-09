import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/paynym/paynym_account_lite.dart';
import 'package:stackwallet/models/send_view_auto_fill_data.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_send.dart';
import 'package:stackwallet/providers/global/locale_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/price_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/providers/wallet/public_private_balance_state_provider.dart';
import 'package:stackwallet/services/coins/firo/firo_wallet.dart';
import 'package:stackwallet/themes/coin_icon_provider.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/barcode_scanner_interface.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class DesktopPaynymSendDialog extends ConsumerStatefulWidget {
  const DesktopPaynymSendDialog({
    Key? key,
    required this.walletId,
    this.autoFillData,
    this.clipboard = const ClipboardWrapper(),
    this.barcodeScanner = const BarcodeScannerWrapper(),
    this.accountLite,
  }) : super(key: key);

  final String walletId;
  final SendViewAutoFillData? autoFillData;
  final ClipboardInterface clipboard;
  final BarcodeScannerInterface barcodeScanner;
  final PaynymAccountLite? accountLite;

  @override
  ConsumerState<DesktopPaynymSendDialog> createState() =>
      _DesktopPaynymSendDialogState();
}

class _DesktopPaynymSendDialogState
    extends ConsumerState<DesktopPaynymSendDialog> {
  @override
  Widget build(BuildContext context) {
    final manager = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(widget.walletId)));
    final String locale = ref.watch(
        localeServiceChangeNotifierProvider.select((value) => value.locale));

    final coin = manager.coin;

    final isFiro = coin == Coin.firo || coin == Coin.firoTestNet;

    return DesktopDialog(
      maxHeight: double.infinity,
      maxWidth: 580,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(
                  "Send ${manager.coin.ticker.toUpperCase()}",
                  style: STextStyles.desktopH3(context),
                ),
              ),
              const DesktopDialogCloseButton(),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: RoundedWhiteContainer(
              borderColor:
                  Theme.of(context).extension<StackColors>()!.background,
              // Theme.of(context).extension<StackColors>()!.textSubtitle4,
              child: Row(
                children: [
                  SvgPicture.asset(
                    ref.watch(coinIconProvider(coin)),
                    width: 36,
                    height: 36,
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        manager.walletName,
                        style: STextStyles.titleBold12(context),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        isFiro
                            ? "${ref.watch(publicPrivateBalanceStateProvider.state).state} balance"
                            : "Available balance",
                        style: STextStyles.baseXS(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textSubtitle1,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    color: Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${!isFiro ? manager.balance.spendable.localizedStringAsFixed(
                              locale: locale,
                            ) : ref.watch(
                                publicPrivateBalanceStateProvider.state,
                              ).state == "Private" ? (manager.wallet as FiroWallet).availablePrivateBalance().localizedStringAsFixed(
                                locale: locale,
                              ) : (manager.wallet as FiroWallet).availablePublicBalance().localizedStringAsFixed(
                                locale: locale,
                              )} ${coin.ticker}",
                          style: STextStyles.titleBold12(context),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Text(
                          "${((!isFiro ? manager.balance.spendable.decimal : ref.watch(publicPrivateBalanceStateProvider.state).state == "Private" ? (manager.wallet as FiroWallet).availablePrivateBalance().decimal : (manager.wallet as FiroWallet).availablePublicBalance().decimal) * ref.watch(priceAnd24hChangeNotifierProvider.select((value) => value.getPrice(coin).item1))).toAmount(fractionDigits: 2).localizedStringAsFixed(locale: locale)} ${ref.watch(prefsChangeNotifierProvider.select((value) => value.currency))}",
                          style: STextStyles.baseXS(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textSubtitle1,
                          ),
                          textAlign: TextAlign.right,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 32,
              right: 32,
              bottom: 32,
            ),
            child: DesktopSend(
              walletId: manager.walletId,
              accountLite: widget.accountLite,
            ),
          ),
        ],
      ),
    );
  }
}
