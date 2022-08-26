import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_recovery_phrase_warning_view/new_wallet_recovery_phrase_warning_view.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/restore_options_view.dart';
import 'package:stackwallet/providers/global/wallets_service_provider.dart';
import 'package:stackwallet/providers/ui/verify_recovery_phrase/mnemonic_word_count_state_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/add_wallet_type_enum.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/name_generator.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/icon_widgets/dice_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';
import 'package:tuple/tuple.dart';

// TODO replace with real list and move out of this file
const kWalletNameWordList = [
  "Bubby",
  "Baby",
  "Bobby",
  "Booby",
];

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

  Future<String> _generateRandomWalletName() async {
    final name = generator.generate(namesToExclude: namesToExclude);
    namesToExclude.add(name);
    return name;
  }

  @override
  void initState() {
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
    return Scaffold(
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
        color: CFColors.almostWhite,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(
                          flex: 1,
                        ),
                        Image(
                          image: AssetImage(
                            Assets.png.imageFor(coin: coin),
                          ),
                          height: 100,
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Text(
                          "Name your ${coin.prettyName} wallet",
                          textAlign: TextAlign.center,
                          style: STextStyles.pageTitleH1,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          "Enter a label for your wallet (e.g. Savings)",
                          textAlign: TextAlign.center,
                          style: STextStyles.subtitle,
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            Constants.size.circularBorderRadius,
                          ),
                          child: TextField(
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
                            style: STextStyles.field,
                            decoration: standardInputDecoration(
                              "Enter wallet name",
                              textFieldFocusNode,
                            ).copyWith(
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 0),
                                child: UnconstrainedBox(
                                  child: Row(
                                    children: [
                                      TextFieldIconButton(
                                        key: const Key(
                                            "genRandomWalletNameButtonKey"),
                                        child: _showDiceIcon
                                            ? const DiceIcon()
                                            : const XIcon(),
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
                        const SizedBox(
                          height: 8,
                        ),
                        RoundedWhiteContainer(
                          child: Center(
                            child: Text(
                              "Roll the dice to pick a random name.",
                              style: STextStyles.itemSubtitle,
                            ),
                          ),
                        ),
                        const Spacer(
                          flex: 4,
                        ),
                        TextButton(
                          onPressed: _nextEnabled
                              ? () async {
                                  final walletsService = ref.read(
                                      walletsServiceChangeNotifierProvider);
                                  final name = textEditingController.text;

                                  if (await walletsService
                                      .checkForDuplicate(name)) {
                                    showFloatingFlushBar(
                                      type: FlushBarType.warning,
                                      message: "Wallet name already in use.",
                                      iconAsset: Assets.svg.circleAlert,
                                      context: context,
                                    );
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
                                          Navigator.of(context).pushNamed(
                                            NewWalletRecoveryPhraseWarningView
                                                .routeName,
                                            arguments: Tuple2(
                                              name,
                                              coin,
                                            ),
                                          );
                                          break;
                                        case AddWalletType.Restore:
                                          ref
                                              .read(
                                                  mnemonicWordCountStateProvider
                                                      .state)
                                              .state = Constants
                                                  .possibleLengthsForCoin(coin)
                                              .first;
                                          Navigator.of(context).pushNamed(
                                            RestoreOptionsView.routeName,
                                            arguments: Tuple2(
                                              name,
                                              coin,
                                            ),
                                          );
                                          break;
                                      }
                                    }
                                  }
                                }
                              : null,
                          style: _nextEnabled
                              ? Theme.of(context)
                                  .textButtonTheme
                                  .style
                                  ?.copyWith(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                    CFColors.stackAccent,
                                  ))
                              : Theme.of(context)
                                  .textButtonTheme
                                  .style
                                  ?.copyWith(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      CFColors.stackAccent.withOpacity(
                                        0.25,
                                      ),
                                    ),
                                  ),
                          child: Text(
                            "Next",
                            style: STextStyles.button,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
