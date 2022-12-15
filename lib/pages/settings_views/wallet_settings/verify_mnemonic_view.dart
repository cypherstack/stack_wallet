import 'dart:async';
import 'dart:math';

import 'package:epicpay/pages/settings_views/wallet_settings/sub_widgets/word_table.dart';
import 'package:epicpay/providers/providers.dart';
import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/widgets/background.dart';
import 'package:epicpay/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicpay/widgets/fullscreen_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tuple/tuple.dart';

import 'confirm_delete_wallet_view.dart';

class VerifyMnemonicView extends ConsumerStatefulWidget {
  const VerifyMnemonicView({
    Key? key,
    required this.mnemonic,
  }) : super(key: key);

  static const routeName = "/verifyRecoveryPhrase";

  final List<String> mnemonic;

  @override
  ConsumerState<VerifyMnemonicView> createState() =>
      _VerifyRecoveryPhraseViewState();
}

class _VerifyRecoveryPhraseViewState extends ConsumerState<VerifyMnemonicView> {
  late List<String> _mnemonic;

  final random = Random(DateTime.now().millisecondsSinceEpoch);

  @override
  void initState() {
    _mnemonic = widget.mnemonic;
    super.initState();
  }

  @override
  dispose() {
    super.dispose();
  }

  Future<void> _continue(bool isMatch) async {
    final nav = Navigator.of(context);

    if (isMatch) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return FullScreenMessage(
            icon: SvgPicture.asset(
              Assets.svg.circleCheck,
            ),
            message: "Correct",
            duration: const Duration(seconds: 2),
          );
        },
      );

      unawaited(
        nav.pushNamed(
          ConfirmWalletDeleteView.routeName,
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return FullScreenMessage(
            icon: SvgPicture.asset(
              Assets.svg.circleRedX,
            ),
            message: "Please write down your seed\nand try again",
            duration: const Duration(seconds: 2),
          );
        },
      );
      nav.pop();
    }
  }

  Tuple2<List<String>, String> randomize(
    List<String> mnemonic,
    int chosenIndex,
    int wordsToShow,
  ) {
    final List<String> remaining = [];
    final String chosenWord = mnemonic[chosenIndex];

    for (int i = 0; i < mnemonic.length; i++) {
      if (chosenWord != mnemonic[i]) {
        remaining.add(mnemonic[i]);
      }
    }

    final List<String> result = [];

    for (int i = 0; i < wordsToShow - 1; i++) {
      final randomIndex = random.nextInt(remaining.length);
      result.add(remaining.removeAt(randomIndex));
    }

    result.insert(random.nextInt(wordsToShow), chosenWord);

    debugPrint("Mnemonic game correct word: $chosenWord");

    return Tuple2(result, chosenWord);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    final correctIndex =
        ref.watch(verifyMnemonicWordIndexStateProvider.state).state;

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: const AppBarBackButton(),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(
                  flex: 4,
                ),
                Text(
                  "Let’s confirm",
                  textAlign: TextAlign.center,
                  style: STextStyles.titleH2(context).copyWith(
                    color: Theme.of(context).extension<StackColors>()!.textGold,
                  ),
                ),
                const Spacer(
                  flex: 1,
                ),
                Text(
                  "Tap word number",
                  textAlign: TextAlign.center,
                  style: STextStyles.titleH4(context),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  "${correctIndex + 1}",
                  textAlign: TextAlign.center,
                  style: STextStyles.titleH1(context).copyWith(
                    color: Theme.of(context).extension<StackColors>()!.textGold,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  "from your key:",
                  textAlign: TextAlign.center,
                  style: STextStyles.titleH4(context),
                ),
                const Spacer(
                  flex: 2,
                ),
                WordTable(
                  words: randomize(_mnemonic, correctIndex, 9).item1,
                  onPressed: (selectedWord) {
                    final correctWord = ref
                        .watch(verifyMnemonicCorrectWordStateProvider.state)
                        .state;

                    _continue(correctWord == selectedWord);
                  },
                ),
                const Spacer(
                  flex: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
