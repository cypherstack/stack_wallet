import 'dart:async';

import 'package:epicmobile/notifications/show_flush_bar.dart';
import 'package:epicmobile/pages/add_wallet_views/new_wallet_recovery_phrase_warning_view/new_wallet_recovery_phrase_warning_view.dart';
import 'package:epicmobile/pages/add_wallet_views/restore_wallet_view/restore_options_view/restore_options_view.dart';
import 'package:epicmobile/providers/global/wallets_service_provider.dart';
import 'package:epicmobile/providers/ui/verify_recovery_phrase/mnemonic_word_count_state_provider.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/enums/add_wallet_type_enum.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/enums/flush_bar_type.dart';
import 'package:epicmobile/utilities/name_generator.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/utilities/util.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/desktop/desktop_app_bar.dart';
import 'package:epicmobile/widgets/desktop/desktop_scaffold.dart';
import 'package:epicmobile/widgets/icon_widgets/dice_icon.dart';
import 'package:epicmobile/widgets/icon_widgets/x_icon.dart';
import 'package:epicmobile/widgets/rounded_white_container.dart';
import 'package:epicmobile/widgets/stack_text_field.dart';
import 'package:epicmobile/widgets/textfield_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';

class NameYourWalletView extends ConsumerStatefulWidget {
  const NameYourWalletView({
    Key? key,
    required this.addWalletType,
    required this.coin,
  }) : super(key: key);

  static const routeName = "/nameYourWallet";

  final AddWalletType addWalletType;
  final Coin coin;

  @override
  ConsumerState<NameYourWalletView> createState() => _NameYourWalletViewState();
}

class _NameYourWalletViewState extends ConsumerState<NameYourWalletView> {
  late final AddWalletType addWalletType;
  late final Coin coin;

  late TextEditingController textEditingController;
  late FocusNode textFieldFocusNode;

  bool _nextEnabled = false;

  bool _showDiceIcon = true;

  Set<String> namesToExclude = {};
  late final NameGenerator generator;

  late final bool isDesktop;

  Future<String> _generateRandomWalletName() async {
    final name = generator.generate(namesToExclude: namesToExclude);
    namesToExclude.add(name);
    return name;
  }

  @override
  void initState() {
    isDesktop = Util.isDesktop;

    ref.read(walletsServiceChangeNotifierProvider).walletNames.then(
          (value) => namesToExclude.addAll(
            value.values.map((e) => e.name),
          ),
        );
    generator = NameGenerator();
    addWalletType = widget.addWalletType;
    coin = widget.coin;
    textEditingController = TextEditingController();
    textFieldFocusNode = FocusNode();

    super.initState();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        "BUILD: NameYourWalletView with ${coin.name} ${addWalletType.name}");

    if (isDesktop) {
      return DesktopScaffold(
        appBar: const DesktopAppBar(
          leading: AppBarBackButton(),
          isCompactHeight: false,
        ),
        body: SizedBox(
          width: 480,
          child: _content(),
        ),
      );
    } else {
      return Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: AppBarBackButton(
              onPressed: () {
                if (textFieldFocusNode.hasFocus) {
                  textFieldFocusNode.unfocus();
                  Future<void>.delayed(const Duration(milliseconds: 100))
                      .then((value) => Navigator.of(context).pop());
                } else {
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ),
          body: Container(
            color: Theme.of(context).extension<StackColors>()!.background,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: _content(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _content() => Column(
        crossAxisAlignment:
            isDesktop ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
        children: [
          if (isDesktop)
            const Spacer(
              flex: 10,
            ),
          if (!isDesktop)
            const Spacer(
              flex: 1,
            ),
          if (!isDesktop)
            Image(
              image: AssetImage(
                Assets.png.imageFor(coin: coin),
              ),
              height: 100,
            ),
          SizedBox(
            height: isDesktop ? 0 : 16,
          ),
          Text(
            "Name your ${coin.prettyName} wallet",
            textAlign: TextAlign.center,
            style: isDesktop
                ? STextStyles.desktopH2(context)
                : STextStyles.pageTitleH1(context),
          ),
          SizedBox(
            height: isDesktop ? 16 : 8,
          ),
          Text(
            "Enter a label for your wallet (e.g. Savings)",
            textAlign: TextAlign.center,
            style: isDesktop
                ? STextStyles.desktopSubtitleH2(context)
                : STextStyles.subtitle(context),
          ),
          SizedBox(
            height: isDesktop ? 40 : 16,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
            child: TextField(
              autocorrect: Util.isDesktop ? false : true,
              enableSuggestions: Util.isDesktop ? false : true,
              onChanged: (string) {
                if (string.isEmpty) {
                  if (_nextEnabled) {
                    setState(() {
                      _nextEnabled = false;
                      _showDiceIcon = true;
                    });
                  }
                } else {
                  if (!_nextEnabled) {
                    setState(() {
                      _nextEnabled = true;
                      _showDiceIcon = false;
                    });
                  }
                }
              },
              focusNode: textFieldFocusNode,
              controller: textEditingController,
              style: isDesktop
                  ? STextStyles.desktopTextMedium(context).copyWith(
                      height: 2,
                    )
                  : STextStyles.field(context),
              decoration: standardInputDecoration(
                "Enter wallet name",
                textFieldFocusNode,
                context,
              ).copyWith(
                suffixIcon: Padding(
                  padding: EdgeInsets.only(right: isDesktop ? 6 : 0),
                  child: UnconstrainedBox(
                    child: Row(
                      children: [
                        TextFieldIconButton(
                          key: const Key("genRandomWalletNameButtonKey"),
                          child: _showDiceIcon
                              ? DiceIcon(
                                  width: isDesktop ? 20 : 17,
                                  height: isDesktop ? 20 : 17,
                                )
                              : XIcon(
                                  width: isDesktop ? 21 : 18,
                                  height: isDesktop ? 21 : 18,
                                ),
                          onTap: () async {
                            if (_showDiceIcon) {
                              textEditingController.text =
                                  await _generateRandomWalletName();
                              setState(() {
                                _nextEnabled = true;
                                _showDiceIcon = false;
                              });
                            } else {
                              textEditingController.text = "";
                              setState(() {
                                _nextEnabled = false;
                                _showDiceIcon = true;
                              });
                            }
                          },
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: isDesktop ? 16 : 8,
          ),
          RoundedWhiteContainer(
            child: Center(
              child: Text(
                "Roll the dice to pick a random name.",
                style: isDesktop
                    ? STextStyles.desktopTextExtraSmall(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textSubtitle1,
                      )
                    : STextStyles.itemSubtitle(context),
              ),
            ),
          ),
          if (!isDesktop)
            const Spacer(
              flex: 4,
            ),
          if (isDesktop)
            const SizedBox(
              height: 32,
            ),
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: isDesktop ? 480 : 0,
              minHeight: isDesktop ? 70 : 0,
            ),
            child: TextButton(
              onPressed: _nextEnabled
                  ? () async {
                      final walletsService =
                          ref.read(walletsServiceChangeNotifierProvider);
                      final name = textEditingController.text;

                      if (await walletsService.checkForDuplicate(name)) {
                        unawaited(showFloatingFlushBar(
                          type: FlushBarType.warning,
                          message: "Wallet name already in use.",
                          iconAsset: Assets.svg.circleAlert,
                          context: context,
                        ));
                      } else {
                        // hide keyboard if has focus
                        if (FocusScope.of(context).hasFocus) {
                          FocusScope.of(context).unfocus();
                          await Future<void>.delayed(
                              const Duration(milliseconds: 50));
                        }

                        if (mounted) {
                          switch (widget.addWalletType) {
                            case AddWalletType.New:
                              unawaited(Navigator.of(context).pushNamed(
                                NewWalletRecoveryPhraseWarningView.routeName,
                                arguments: Tuple2(
                                  name,
                                  coin,
                                ),
                              ));
                              break;
                            case AddWalletType.Restore:
                              ref
                                  .read(mnemonicWordCountStateProvider.state)
                                  .state = Constants.possibleLengthsForCoin(
                                      coin)
                                  .first;
                              unawaited(Navigator.of(context).pushNamed(
                                RestoreOptionsView.routeName,
                                arguments: Tuple2(
                                  name,
                                  coin,
                                ),
                              ));
                              break;
                          }
                        }
                      }
                    }
                  : null,
              style: _nextEnabled
                  ? Theme.of(context)
                      .extension<StackColors>()!
                      .getPrimaryEnabledButtonColor(context)
                  : Theme.of(context)
                      .extension<StackColors>()!
                      .getPrimaryDisabledButtonColor(context),
              child: Text(
                "Next",
                style: isDesktop
                    ? _nextEnabled
                        ? STextStyles.desktopButtonEnabled(context)
                        : STextStyles.desktopButtonDisabled(context)
                    : STextStyles.button(context),
              ),
            ),
          ),
          if (isDesktop)
            const Spacer(
              flex: 15,
            ),
        ],
      );
}
