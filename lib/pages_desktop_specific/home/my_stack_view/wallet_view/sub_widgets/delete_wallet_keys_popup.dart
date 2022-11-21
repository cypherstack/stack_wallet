import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_recovery_phrase_view/sub_widgets/mnemonic_table.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';

class DeleteWalletKeysPopup extends ConsumerStatefulWidget {
  const DeleteWalletKeysPopup({
    Key? key,
    required this.walletId,
    required this.words,
  }) : super(key: key);

  final String walletId;
  final List<String> words;

  static const String routeName = "/desktopDeleteWalletKeysPopup";

  @override
  ConsumerState<DeleteWalletKeysPopup> createState() =>
      _DeleteWalletKeysPopup();
}

class _DeleteWalletKeysPopup extends ConsumerState<DeleteWalletKeysPopup> {
  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      maxWidth: 614,
      maxHeight: double.infinity,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 32,
                ),
                child: Text(
                  "Wallet keys",
                  style: STextStyles.desktopH3(context),
                ),
              ),
              DesktopDialogCloseButton(
                onPressedOverride: () {
                  int count = 0;
                  Navigator.of(context).popUntil((_) => count++ >= 2);
                },
              ),
            ],
          ),
          const SizedBox(
            height: 28,
          ),
          Text(
            "Recovery phrase",
            style: STextStyles.desktopTextMedium(context),
          ),
          const SizedBox(
            height: 8,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
              ),
              child: Text(
                "Please write down your recovery phrase in the correct order and save it to keep your funds secure. You will also be asked to verify the words on the next screen.",
                style: STextStyles.desktopTextExtraExtraSmall(context),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
            ),
            child: MnemonicTable(
              words: widget.words,
              isDesktop: true,
              itemBorderColor: Theme.of(context)
                  .extension<StackColors>()!
                  .buttonBackSecondary,
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
            ),
            child: Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: "Continue",
                    onPressed: () async {
                      int count = 0;
                      Navigator.of(context).popUntil((_) => count++ >= 2);

                      unawaited(
                        showDialog(
                            context: context,
                            builder: (context) {
                              return DesktopDialog(
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        DesktopDialogCloseButton(
                                          onPressedOverride: () {
                                            int count = 0;
                                            Navigator.of(context)
                                                .popUntil((_) => count++ >= 2);
                                          },
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          "Thanks! "
                                          "\n\nYour wallet will be deleted.",
                                          style: STextStyles.desktopH2(context),
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SecondaryButton(
                                                width: 250,
                                                buttonHeight: ButtonHeight.xl,
                                                label: "Cancel",
                                                onPressed: () {
                                                  int count = 0;
                                                  Navigator.of(context)
                                                      .popUntil(
                                                          (_) => count++ >= 2);
                                                }),
                                            const SizedBox(width: 16),
                                            PrimaryButton(
                                                width: 250,
                                                buttonHeight: ButtonHeight.xl,
                                                label: "Continue",
                                                onPressed: () async {
                                                  // final walletsInstance =
                                                  // ref.read(walletsChangeNotifierProvider);
                                                  // await ref
                                                  //     .read(walletsServiceChangeNotifierProvider)
                                                  //     .deleteWallet(walletId, true);
                                                  //
                                                  // if (mounted) {
                                                  //   Navigator.of(context).popUntil(
                                                  //       ModalRoute.withName(HomeView.routeName));
                                                  // }

                                                  // // wait for widget tree to dispose of any widgets watching the manager
                                                  // await Future<void>.delayed(const Duration(seconds: 1));
                                                  // walletsInstance.removeWallet(walletId: walletId);
                                                }),
                                          ],
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 32,
          ),
        ],
      ),
    );
  }
}
