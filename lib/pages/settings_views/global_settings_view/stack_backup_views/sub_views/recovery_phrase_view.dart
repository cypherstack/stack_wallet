import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_recovery_phrase_view/sub_widgets/mnemonic_table.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';

class RecoverPhraseView extends StatelessWidget {
  const RecoverPhraseView({
    Key? key,
    required this.walletName,
    required this.mnemonic,
    this.clipboardInterface = const ClipboardWrapper(),
  }) : super(key: key);

  static const String routeName = "/recoverPhrase";

  final String walletName;
  final List<String> mnemonic;
  final ClipboardInterface clipboardInterface;

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return Scaffold(
      backgroundColor: Theme.of(context).extension<StackColors>()!.background,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: AspectRatio(
              aspectRatio: 1,
              child: AppBarIconButton(
                color: Theme.of(context).extension<StackColors>()!.background,
                shadows: const [],
                icon: SvgPicture.asset(
                  Assets.svg.copy,
                  width: 20,
                  height: 20,
                ),
                onPressed: () async {
                  await clipboardInterface
                      .setData(ClipboardData(text: mnemonic.join(" ")));
                  showFloatingFlushBar(
                    type: FlushBarType.info,
                    message: "Copied to clipboard",
                    iconAsset: Assets.svg.copy,
                    context: context,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              height: 4,
            ),
            Text(
              walletName,
              textAlign: TextAlign.center,
              style: STextStyles.label(context).copyWith(
                fontSize: 12,
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              "Recovery Phrase",
              textAlign: TextAlign.center,
              style: STextStyles.pageTitleH1(context),
            ),
            const SizedBox(
              height: 12,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: MnemonicTable(
                  words: mnemonic,
                  isDesktop: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
