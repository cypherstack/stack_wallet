import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';

class FiatCryptoToggle extends ConsumerWidget {
  const FiatCryptoToggle({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("BUILD: $runtimeType");
    final isDesktop = Util.isDesktop;

    final buyWithFiat = ref.watch(
        prefsChangeNotifierProvider.select((value) => value.buyWithFiat));

    return BlueTextButton(
      text: buyWithFiat ? "Use crypto amount" : "Use fiat amount",
      textSize: 14,
      onTap: () {
        final buyWithFiat = ref.read(prefsChangeNotifierProvider).buyWithFiat;
        ref.read(prefsChangeNotifierProvider).buyWithFiat = !buyWithFiat;
        // Navigator.of(context).pop();
      },
    );
  }
}
