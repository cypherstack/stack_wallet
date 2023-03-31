import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/wallet_info_row/sub_widgets/wallet_info_row_balance_future.dart';
import 'package:stackwallet/widgets/wallet_info_row/sub_widgets/wallet_info_row_coin_icon.dart';

class EthWalletRadio extends ConsumerStatefulWidget {
  const EthWalletRadio({
    Key? key,
    required this.walletId,
    this.selectedWalletId,
  }) : super(key: key);

  final String walletId;
  final String? selectedWalletId;

  @override
  ConsumerState<EthWalletRadio> createState() => _EthWalletRadioState();
}

class _EthWalletRadioState extends ConsumerState<EthWalletRadio> {
  @override
  Widget build(BuildContext context) {
    final manager = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(widget.walletId)));

    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            IgnorePointer(
              child: Radio(
                value: widget.walletId,
                groupValue: widget.selectedWalletId,
                onChanged: (_) {
                  // do nothing since changing updating the ui is already
                  // done elsewhere
                },
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            WalletInfoCoinIcon(
              coin: manager.coin,
              size: 40,
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    manager.walletName,
                    style: STextStyles.desktopTextExtraSmall(context).copyWith(
                      color:
                          Theme.of(context).extension<StackColors>()!.textDark,
                    ),
                  ),
                  WalletInfoRowBalance(
                    walletId: widget.walletId,
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
