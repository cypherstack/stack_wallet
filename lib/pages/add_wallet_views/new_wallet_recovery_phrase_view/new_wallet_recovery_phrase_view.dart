import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_recovery_phrase_view/sub_widgets/mnemonic_table.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_recovery_phrase_warning_view/new_wallet_recovery_phrase_warning_view.dart';
import 'package:stackwallet/pages/add_wallet_views/verify_recovery_phrase_view/verify_recovery_phrase_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:tuple/tuple.dart';

class NewWalletRecoveryPhraseView extends ConsumerStatefulWidget {
  const NewWalletRecoveryPhraseView({
    Key? key,
    required this.manager,
    required this.mnemonic,
    this.clipboardInterface = const ClipboardWrapper(),
  }) : super(key: key);

  static const routeName = "/newWalletRecoveryPhrase";

  final Manager manager;
  final List<String> mnemonic;

  final ClipboardInterface clipboardInterface;

  @override
  ConsumerState<NewWalletRecoveryPhraseView> createState() =>
      _NewWalletRecoveryPhraseViewState();
}

class _NewWalletRecoveryPhraseViewState
    extends ConsumerState<NewWalletRecoveryPhraseView>
// with WidgetsBindingObserver
{
  late Manager _manager;
  late List<String> _mnemonic;
  late ClipboardInterface _clipboardInterface;

  @override
  void initState() {
    _manager = widget.manager;
    _mnemonic = widget.mnemonic;
    _clipboardInterface = widget.clipboardInterface;
    super.initState();
  }

  Future<bool> onWillPop() async {
    await delete();
    return true;
  }

  Future<void> delete() async {
    await ref
        .read(walletsServiceChangeNotifierProvider)
        .deleteWallet(_manager.walletName, false);
    await _manager.exitCurrentWallet();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () async {
              await delete();

              if (mounted) {
                Navigator.of(context).popUntil(
                  ModalRoute.withName(
                    NewWalletRecoveryPhraseWarningView.routeName,
                  ),
                );
              }
              // Navigator.of(context).pop();
            },
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
                    width: 24,
                    height: 24,
                  ),
                  onPressed: () async {
                    final words = await _manager.mnemonic;
                    await _clipboardInterface
                        .setData(ClipboardData(text: words.join(" ")));
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
        body: Container(
          color: CFColors.almostWhite,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  height: 4,
                ),
                Text(
                  _manager.walletName,
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
                    borderRadius: BorderRadius.circular(
                        Constants.size.circularBorderRadius),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      "Please write down your recovery phrase in the correct order and save it to keep your funds secure. You will also be asked to verify the words on the next screen.",
                      style: STextStyles.label.copyWith(
                        color: CFColors.stackAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: MnemonicTable(
                      words: _mnemonic,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                TextButton(
                  onPressed: () async {
                    final int next = Random().nextInt(_mnemonic.length);
                    ref
                        .read(verifyMnemonicWordIndexStateProvider.state)
                        .update((state) => next);

                    ref
                        .read(verifyMnemonicCorrectWordStateProvider.state)
                        .update((state) => _mnemonic[next]);

                    Navigator.of(context).pushNamed(
                      VerifyRecoveryPhraseView.routeName,
                      arguments: Tuple2(_manager, _mnemonic),
                    );
                  },
                  style: Theme.of(context).textButtonTheme.style?.copyWith(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          CFColors.stackAccent,
                        ),
                      ),
                  child: Text(
                    "I saved my recovery phrase",
                    style: STextStyles.button,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
