import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/add_wallet_views/create_or_restore_wallet_view/create_or_restore_wallet_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class AddWalletNextButton extends ConsumerWidget {
  const AddWalletNextButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("BUILD: NextButton");
    final selectedCoin =
        ref.watch(addWalletSelectedCoinStateProvider.state).state;
    return TextButton(
      onPressed: selectedCoin == null
          ? null
          : () {
              final selectedCoin =
                  ref.read(addWalletSelectedCoinStateProvider.state).state;
              debugPrint("Next pressed with ${selectedCoin!.name} selected!");
              Navigator.of(context).pushNamed(
                CreateOrRestoreWalletView.routeName,
                arguments: selectedCoin,
              );
            },
      style: selectedCoin == null
          ? Theme.of(context).textButtonTheme.style?.copyWith(
                backgroundColor: MaterialStateProperty.all<Color>(
                  CFColors.stackAccent.withOpacity(
                    0.25,
                  ),
                ),
              )
          : Theme.of(context).textButtonTheme.style?.copyWith(
                backgroundColor: MaterialStateProperty.all<Color>(
                  CFColors.stackAccent,
                ),
              ),
      child: Text(
        "Next",
        style: STextStyles.button,
      ),
    );
  }
}
