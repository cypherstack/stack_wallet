import 'package:epicmobile/pages/add_wallet_views/new_wallet_recovery_phrase_view/sub_widgets/mnemonic_table.dart';
import 'package:epicmobile/utilities/clipboard_interface.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                Expanded(
                  child: SingleChildScrollView(
                    child: MnemonicTable(
                      words: mnemonic,
                      isDesktop: false,
                    ),
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
}
