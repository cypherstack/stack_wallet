import 'dart:async';

import 'package:epicmobile/pages/add_wallet_views/new_wallet_recovery_phrase_view/sub_widgets/mnemonic_table.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/clipboard_interface.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

class WalletBackupView extends ConsumerWidget {
  const WalletBackupView({
    Key? key,
    required this.walletId,
    required this.mnemonic,
    this.clipboardInterface = const ClipboardWrapper(),
  }) : super(key: key);

  static const String routeName = "/walletBackup";

  final String walletId;
  final List<String> mnemonic;
  final ClipboardInterface clipboardInterface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            "Backup Wallet",
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
          //           await clipboardInterface
          //               .setData(ClipboardData(text: mnemonic.join(" ")));
          //         },
          //       ),
          //     ),
          //   ),
          // ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  height: 4,
                ),
                Text(
                  "Wallet Key",
                  textAlign: TextAlign.center,
                  style: STextStyles.titleH2(context).copyWith(
                    color: Theme.of(context).extension<StackColors>()!.textGold,
                  ),
                ),
                const SizedBox(
                  height: 32,
                ),
                SingleChildScrollView(
                  child: MnemonicTable(
                    words: mnemonic,
                    isDesktop: false,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40.0, vertical: 10.0),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        Assets.svg.edit,
                        width: 22,
                        height: 22,
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      Text(
                        "Write down your wallet key.",
                        style: STextStyles.smallMed14(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40.0, vertical: 10.0),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        Assets.svg.lockFilled,
                        width: 22,
                        height: 22,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textMedium,
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      Text(
                        "Keep your wallet key safe.",
                        style: STextStyles.smallMed14(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40.0, vertical: 10.0),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        Assets.svg.eyeSlash,
                        width: 22,
                        height: 22,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textMedium,
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      Text(
                        "Do not show your wallet key to"
                        "\nanyone.",
                        style: STextStyles.smallMed14(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                GestureDetector(
                  onTap: () {
                    backupKeyRulesDialog(context);
                  },
                  child: Text(
                    "WHY THESE RULES?",
                    style: STextStyles.smallMed14(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .buttonBackPrimary),
                    textAlign: TextAlign.center,
                  ),
                ),
                // const SizedBox(
                //   height: 12,
                // ),
                // TextButton(
                //   style: Theme.of(context)
                //       .extension<StackColors>()!
                //       .getPrimaryEnabledButtonColor(context),
                //   onPressed: () {
                //     String data = AddressUtils.encodeQRSeedData(mnemonic);
                //
                //     showDialog<dynamic>(
                //       context: context,
                //       useSafeArea: false,
                //       barrierDismissible: true,
                //       builder: (_) {
                //         final width = MediaQuery.of(context).size.width / 2;
                //         return StackDialogBase(
                //           child: Column(
                //             crossAxisAlignment: CrossAxisAlignment.stretch,
                //             children: [
                //               Center(
                //                 child: Text(
                //                   "Recovery phrase QR code",
                //                   style: STextStyles.pageTitleH2(context),
                //                 ),
                //               ),
                //               const SizedBox(
                //                 height: 12,
                //               ),
                //               Center(
                //                 child: RepaintBoundary(
                //                   // key: _qrKey,
                //                   child: SizedBox(
                //                     width: width + 20,
                //                     height: width + 20,
                //                     child: QrImage(
                //                         data: data,
                //                         size: width,
                //                         backgroundColor: Theme.of(context)
                //                             .extension<StackColors>()!
                //                             .popupBG,
                //                         foregroundColor: Theme.of(context)
                //                             .extension<StackColors>()!
                //                             .accentColorDark),
                //                   ),
                //                 ),
                //               ),
                //               const SizedBox(
                //                 height: 12,
                //               ),
                //               Center(
                //                 child: SizedBox(
                //                   width: width,
                //                   child: TextButton(
                //                     onPressed: () async {
                //                       // await _capturePng(true);
                //                       Navigator.of(context).pop();
                //                     },
                //                     style: Theme.of(context)
                //                         .extension<StackColors>()!
                //                         .getSecondaryEnabledButtonColor(context),
                //                     child: Text(
                //                       "Cancel",
                //                       style: STextStyles.button(context).copyWith(
                //                           color: Theme.of(context)
                //                               .extension<StackColors>()!
                //                               .accentColorDark),
                //                     ),
                //                   ),
                //                 ),
                //               ),
                //             ],
                //           ),
                //         );
                //       },
                //     );
                //   },
                //   child: Text(
                //     "Show QR Code",
                //     style: STextStyles.button(context),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ///todo: put in a separate file
  Future<void> backupKeyRulesDialog(BuildContext context) async {
    unawaited(
      showDialog<dynamic>(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius * 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Wallet Key explained",
                      style: STextStyles.titleH3(context),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Text(
                      "Why is wallet key important?",
                      style: STextStyles.smallMed14(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .buttonBackPrimary,
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    const Text(
                      "Cryptocurrency does not work like regular finance. In the banking system, "
                      "banks are responsible for keeping your money safe."
                      "\n\nIn cryptocurrency, you are your own bank. Imagine keeping cash at home. If that cash "
                      "burns down or gets stolen, you lose it and nobody will help you get your money back."
                      "\n\nSince cryptocurrency is digital money, your wallet key is like that “cash” you keep at home. "
                      "If you lose your phone or if you forget your wallet PIN, but you have your wallet key, your crypto "
                      "money will be safe. That is why you should keep your wallet key safe.",
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Text(
                      "Why write the wallet key down?",
                      style: STextStyles.smallMed14(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .buttonBackPrimary,
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    const Text(
                      "You do not put your cash on display, do you? Keeping your wallet "
                      "key on a digital device is like having it on display for thieves - malicious "
                      "software and hackers. Write your wallet key down on paper in multiple copies and "
                      "keep them in a real, physical safe.",
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            "CLOSE",
                            style: STextStyles.buttonText(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }
}
