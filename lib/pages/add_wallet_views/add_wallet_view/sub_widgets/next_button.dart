import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/add_wallet_views/create_or_restore_wallet_view/create_or_restore_wallet_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';

class AddWalletNextButton extends ConsumerWidget {
  const AddWalletNextButton({
    Key? key,
    required this.isDesktop,
  }) : super(key: key);

  final bool isDesktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("BUILD: NextButton");
    final selectedCoin =
        ref.watch(addWalletSelectedCoinStateProvider.state).state;

    final enabled = selectedCoin != null;

    return TextButton(
      onPressed: !enabled
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
      style: enabled
          ? StackTheme.instance.getPrimaryEnabledButtonColor(context)
          : StackTheme.instance.getPrimaryDisabledButtonColor(context),
      child: Text(
        "Next",
        style: isDesktop
            ? enabled
                ? STextStyles.desktopButtonEnabled
                : STextStyles.desktopButtonDisabled
            : STextStyles.button,
      ),
    );
  }
}
