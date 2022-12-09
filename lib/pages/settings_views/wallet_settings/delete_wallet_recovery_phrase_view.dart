import 'dart:math';

import 'package:epicpay/pages/add_wallet_views/new_wallet_recovery_phrase_view/sub_widgets/mnemonic_table.dart';
import 'package:epicpay/pages/settings_views/wallet_settings/verify_mnemonic_view.dart';
import 'package:epicpay/providers/ui/verify_recovery_phrase/correct_word_provider.dart';
import 'package:epicpay/providers/ui/verify_recovery_phrase/random_index_provider.dart';
import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/clipboard_interface.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/widgets/background.dart';
import 'package:epicpay/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicpay/widgets/desktop/primary_button.dart';
import 'package:epicpay/widgets/rounded_white_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

class DeleteWalletRecoveryPhraseView extends ConsumerStatefulWidget {
  const DeleteWalletRecoveryPhraseView({
    Key? key,
    required this.mnemonic,
    this.clipboardInterface = const ClipboardWrapper(),
  }) : super(key: key);

  static const routeName = "/deleteWalletRecoveryPhrase";

  final List<String> mnemonic;

  final ClipboardInterface clipboardInterface;

  @override
  ConsumerState<DeleteWalletRecoveryPhraseView> createState() =>
      _DeleteWalletRecoveryPhraseViewState();
}

class _DeleteWalletRecoveryPhraseViewState
    extends ConsumerState<DeleteWalletRecoveryPhraseView> {
  late final List<String> _mnemonic;
  late final ClipboardInterface _clipboardInterface;

  @override
  void initState() {
    _mnemonic = widget.mnemonic;
    _clipboardInterface = widget.clipboardInterface;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          centerTitle: true,
          title: Text(
            "Delete wallet",
            style: STextStyles.titleH4(context),
          ),
          // actions: [
          //   Padding(
          //     padding: const EdgeInsets.all(10),
          //     child: AspectRatio(
          //       aspectRatio: 1,
          //       child: AppBarIconButton(
          //         color: Theme.of(context).extension<StackColors>()!.background,
          //         shadows: const [],
          //         icon: SvgPicture.asset(
          //           Assets.svg.copy,
          //           width: 20,
          //           height: 20,
          //           color: Theme.of(context)
          //               .extension<StackColors>()!
          //               .topNavIconPrimary,
          //         ),
          //         onPressed: () async {
          //           await _clipboardInterface
          //               .setData(ClipboardData(text: _mnemonic.join(" ")));
          //         },
          //       ),
          //     ),
          //   ),
          // ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RoundedWhiteContainer(
                  child: Column(
                    children: [
                      Text(
                        "Warning!",
                        style: STextStyles.titleH3(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .snackBarTextError,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Text(
                        "You must write down your wallet key. Saving your wallet key is the ONLY way you can have access to your funds after deleting the wallet.",
                        style: STextStyles.bodySmall(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textMedium,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Text(
                        "If you delete this wallet, you will lose your funds unless you save your wallet key.",
                        style: STextStyles.bodySmallBold(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .snackBarTextError,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 59,
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 135),
                        child: Text(
                          "My Wallet",
                          style: STextStyles.titleH4(context),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await _clipboardInterface.setData(
                              ClipboardData(text: _mnemonic.join(" ")));
                          // copied = true;
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // copied == false
                            Row(
                              children: [
                                Text(
                                  "Copy",
                                  style:
                                      STextStyles.smallMed14(context).copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .buttonBackPrimary,
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                                const SizedBox(
                                  width: 6,
                                ),
                                SvgPicture.asset(
                                  Assets.svg.copy,
                                  width: 20,
                                  height: 20,
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .buttonBackPrimary,
                                ),
                              ],
                            ),
                            // : Text(
                            //     "Copied!",
                            //     style: STextStyles.smallMed14(context).copyWith(
                            //       color: Theme.of(context)
                            //           .extension<StackColors>()!
                            //           .buttonBackPrimary,
                            //     ),
                            //     textAlign: TextAlign.end,
                            //   ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: MnemonicTable(
                      words: _mnemonic,
                      isDesktop: false,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                PrimaryButton(
                  label: "I'VE WRITTEN DOWN THE KEY",
                  onPressed: () {
                    final int next = Random().nextInt(_mnemonic.length);
                    ref
                        .read(verifyMnemonicWordIndexStateProvider.state)
                        .update((state) => next);
                    ref
                        .read(verifyMnemonicCorrectWordStateProvider.state)
                        .update((state) => _mnemonic[next]);

                    Navigator.of(context).pushNamed(
                      VerifyMnemonicView.routeName,
                      arguments: _mnemonic,
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
