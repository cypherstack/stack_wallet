import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_recovery_phrase_view/sub_widgets/mnemonic_table.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_recovery_phrase_warning_view/new_wallet_recovery_phrase_warning_view.dart';
import 'package:stackwallet/pages/add_wallet_views/verify_recovery_phrase_view/verify_recovery_phrase_view.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_home_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
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
  late final bool isDesktop;

  @override
  void initState() {
    _manager = widget.manager;
    _mnemonic = widget.mnemonic;
    _clipboardInterface = widget.clipboardInterface;
    isDesktop = Util.isDesktop;
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

  Future<void> _copy() async {
    final words = await _manager.mnemonic;
    await _clipboardInterface.setData(ClipboardData(text: words.join(" ")));
    unawaited(showFloatingFlushBar(
      type: FlushBarType.info,
      message: "Copied to clipboard",
      iconAsset: Assets.svg.copy,
      context: context,
    ));
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return WillPopScope(
      onWillPop: onWillPop,
      child: MasterScaffold(
        isDesktop: isDesktop,
        appBar: isDesktop
            ? DesktopAppBar(
                isCompactHeight: false,
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
                trailing: ExitToMyStackButton(
                  onPressed: () async {
                    await delete();
                    if (mounted) {
                      Navigator.of(context).popUntil(
                        ModalRoute.withName(DesktopHomeView.routeName),
                      );
                    }
                  },
                ),
              )
            : AppBar(
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
                  },
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: AppBarIconButton(
                        semanticsLabel: "Copy Button. Copies The Recovery Phrase To Clipboard.",
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .background,
                        shadows: const [],
                        icon: SvgPicture.asset(
                          Assets.svg.copy,
                          width: 24,
                          height: 24,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .topNavIconPrimary,
                        ),
                        onPressed: () async {
                          await _copy();
                        },
                      ),
                    ),
                  ),
                ],
              ),
        body: Container(
          color: Theme.of(context).extension<StackColors>()!.background,
          width: isDesktop ? 600 : null,
          child: Padding(
            padding:
                isDesktop ? const EdgeInsets.all(0) : const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isDesktop)
                  const Spacer(
                    flex: 10,
                  ),
                if (!isDesktop)
                  const SizedBox(
                    height: 4,
                  ),
                if (!isDesktop)
                  Text(
                    _manager.walletName,
                    textAlign: TextAlign.center,
                    style: STextStyles.label(context).copyWith(
                      fontSize: 12,
                    ),
                  ),
                SizedBox(
                  height: isDesktop ? 24 : 4,
                ),
                Text(
                  "Recovery Phrase",
                  textAlign: TextAlign.center,
                  style: isDesktop
                      ? STextStyles.desktopH2(context)
                      : STextStyles.pageTitleH1(context),
                ),
                const SizedBox(
                  height: 16,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDesktop
                        ? Theme.of(context).extension<StackColors>()!.background
                        : Theme.of(context).extension<StackColors>()!.popupBG,
                    borderRadius: BorderRadius.circular(
                        Constants.size.circularBorderRadius),
                  ),
                  child: Padding(
                    padding: isDesktop
                        ? const EdgeInsets.all(0)
                        : const EdgeInsets.all(12),
                    child: Text(
                      "Please write down your recovery phrase in the correct order and save it to keep your funds secure. You will also be asked to verify the words on the next screen.",
                      textAlign: TextAlign.center,
                      style: isDesktop
                          ? STextStyles.desktopSubtitleH2(context)
                          : STextStyles.label(context).copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .accentColorDark),
                    ),
                  ),
                ),
                SizedBox(
                  height: isDesktop ? 21 : 8,
                ),
                if (!isDesktop)
                  Expanded(
                    child: SingleChildScrollView(
                      child: MnemonicTable(
                        words: _mnemonic,
                        isDesktop: isDesktop,
                      ),
                    ),
                  ),
                if (isDesktop)
                  MnemonicTable(
                    words: _mnemonic,
                    isDesktop: isDesktop,
                  ),
                SizedBox(
                  height: isDesktop ? 24 : 16,
                ),
                if (isDesktop)
                  SizedBox(
                    height: 70,
                    child: TextButton(
                      onPressed: () async {
                        await _copy();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            Assets.svg.copy,
                            width: 20,
                            height: 20,
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .buttonTextSecondary,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                            "Copy to clipboard",
                            style: STextStyles.desktopButtonSecondaryEnabled(
                                context),
                          )
                        ],
                      ),
                    ),
                  ),
                if (isDesktop)
                  const SizedBox(
                    height: 16,
                  ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: isDesktop ? 70 : 0,
                  ),
                  child: TextButton(
                    onPressed: () async {
                      final int next = Random().nextInt(_mnemonic.length);
                      ref
                          .read(verifyMnemonicWordIndexStateProvider.state)
                          .update((state) => next);

                      ref
                          .read(verifyMnemonicCorrectWordStateProvider.state)
                          .update((state) => _mnemonic[next]);

                      unawaited(Navigator.of(context).pushNamed(
                        VerifyRecoveryPhraseView.routeName,
                        arguments: Tuple2(_manager, _mnemonic),
                      ));
                    },
                    style: Theme.of(context)
                        .extension<StackColors>()!
                        .getPrimaryEnabledButtonStyle(context),
                    child: Text(
                      "I saved my recovery phrase",
                      style: isDesktop
                          ? STextStyles.desktopButtonEnabled(context)
                          : STextStyles.button(context),
                    ),
                  ),
                ),
                if (isDesktop)
                  const Spacer(
                    flex: 15,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
