import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_recovery_phrase_view/sub_widgets/mnemonic_table.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

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
    return Scaffold(
      backgroundColor: CFColors.almostWhite,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "Wallet backup",
          style: STextStyles.navBarTitle,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: AspectRatio(
              aspectRatio: 1,
              child: AppBarIconButton(
                color: CFColors.almostWhite,
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
              ref
                  .watch(walletsChangeNotifierProvider
                      .select((value) => value.getManager(walletId)))
                  .walletName,
              textAlign: TextAlign.center,
              style: STextStyles.label.copyWith(
                fontSize: 12,
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              "Recovery Phrase",
              textAlign: TextAlign.center,
              style: STextStyles.pageTitleH1,
            ),
            const SizedBox(
              height: 16,
            ),
            Container(
              decoration: BoxDecoration(
                color: CFColors.white,
                borderRadius:
                    BorderRadius.circular(Constants.size.circularBorderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  "Please write down your backup key. Keep it safe and never share it with anyone. Your backup key is the only way you can access your funds if you forget your PIN, lose your phone, etc.\n\nStack Wallet does not keep nor is able to restore your backup key. Only you have access to your wallet.",
                  style: STextStyles.label,
                ),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: MnemonicTable(
                  words: mnemonic,
                  isDesktop: false,
                ),
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            TextButton(
              style: Theme.of(context).textButtonTheme.style?.copyWith(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      CFColors.stackAccent,
                    ),
                  ),
              onPressed: () {
                String data = AddressUtils.encodeQRSeedData(mnemonic);

                showDialog<dynamic>(
                  context: context,
                  useSafeArea: false,
                  barrierDismissible: true,
                  builder: (_) {
                    final width = MediaQuery.of(context).size.width / 2;
                    return StackDialogBase(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Text(
                              "Recovery phrase QR code",
                              style: STextStyles.pageTitleH2,
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Center(
                            child: RepaintBoundary(
                              // key: _qrKey,
                              child: SizedBox(
                                width: width + 20,
                                height: width + 20,
                                child: QrImage(
                                  data: data,
                                  size: width,
                                  backgroundColor: CFColors.white,
                                  foregroundColor: CFColors.stackAccent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Center(
                            child: SizedBox(
                              width: width,
                              child: TextButton(
                                onPressed: () async {
                                  // await _capturePng(true);
                                  Navigator.of(context).pop();
                                },
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                    CFColors.buttonGray,
                                  ),
                                ),
                                child: Text(
                                  "Cancel",
                                  style: STextStyles.button.copyWith(
                                    color: CFColors.stackAccent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Text(
                "Show QR Code",
                style: STextStyles.button,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
