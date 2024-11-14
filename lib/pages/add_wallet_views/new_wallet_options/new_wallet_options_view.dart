import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tuple/tuple.dart';

import '../../../pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import '../../../providers/ui/verify_recovery_phrase/mnemonic_word_count_state_provider.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/constants.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/crypto_currency/crypto_currency.dart';
import '../../../wallets/crypto_currency/interfaces/view_only_option_currency_interface.dart';
import '../../../widgets/background.dart';
import '../../../widgets/conditional_parent.dart';
import '../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../widgets/custom_buttons/checkbox_text_button.dart';
import '../../../widgets/desktop/desktop_app_bar.dart';
import '../../../widgets/desktop/desktop_scaffold.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/rounded_white_container.dart';
import '../../../widgets/stack_text_field.dart';
import '../create_or_restore_wallet_view/sub_widgets/coin_image.dart';
import '../new_wallet_recovery_phrase_warning_view/new_wallet_recovery_phrase_warning_view.dart';
import '../restore_wallet_view/restore_options_view/sub_widgets/mobile_mnemonic_length_selector.dart';
import '../restore_wallet_view/sub_widgets/mnemonic_word_count_select_sheet.dart';

final pNewWalletOptions = StateProvider<
    ({
      String mnemonicPassphrase,
      int mnemonicWordsCount,
      bool convertToViewOnly,
    })?>(
  (ref) => null,
);

enum NewWalletOptions {
  Default,
  Advanced;
}

class NewWalletOptionsView extends ConsumerStatefulWidget {
  const NewWalletOptionsView({
    super.key,
    required this.walletName,
    required this.coin,
  });

  static const routeName = "/newWalletOptionsView";

  final String walletName;
  final CryptoCurrency coin;

  @override
  ConsumerState<NewWalletOptionsView> createState() =>
      _NewWalletOptionsViewState();
}

class _NewWalletOptionsViewState extends ConsumerState<NewWalletOptionsView> {
  late final FocusNode passwordFocusNode;
  late final TextEditingController passwordController;

  bool hidePassword = true;
  NewWalletOptions _selectedOptions = NewWalletOptions.Default;

  bool _convertToViewOnly = false;

  @override
  void initState() {
    passwordController = TextEditingController();
    passwordFocusNode = FocusNode();

    super.initState();
  }

  @override
  void dispose() {
    passwordController.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lengths = widget.coin.possibleMnemonicLengths;
    return ConditionalParent(
      condition: Util.isDesktop,
      builder: (child) => DesktopScaffold(
        background: Theme.of(context).extension<StackColors>()!.background,
        appBar: const DesktopAppBar(
          isCompactHeight: false,
          leading: AppBarBackButton(),
          trailing: ExitToMyStackButton(),
        ),
        body: SizedBox(
          width: 480,
          child: child,
        ),
      ),
      child: ConditionalParent(
        condition: !Util.isDesktop,
        builder: (child) => Background(
          child: Scaffold(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
            appBar: AppBar(
              leading: const AppBarBackButton(),
              title: Text(
                "Wallet Options",
                style: STextStyles.navBarTitle(context),
              ),
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        child: Column(
          children: [
            if (Util.isDesktop)
              const Spacer(
                flex: 10,
              ),
            if (!Util.isDesktop)
              const SizedBox(
                height: 16,
              ),
            if (!Util.isDesktop)
              CoinImage(
                coin: widget.coin,
                height: 100,
                width: 100,
              ),
            if (Util.isDesktop)
              Text(
                "Wallet options",
                textAlign: TextAlign.center,
                style: Util.isDesktop
                    ? STextStyles.desktopH2(context)
                    : STextStyles.pageTitleH1(context),
              ),
            SizedBox(
              height: Util.isDesktop ? 32 : 16,
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton2<NewWalletOptions>(
                value: _selectedOptions,
                items: [
                  ...NewWalletOptions.values.map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e.name,
                        style: STextStyles.desktopTextMedium(context),
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value is NewWalletOptions) {
                    setState(() {
                      _selectedOptions = value;
                    });
                  }
                },
                isExpanded: true,
                iconStyleData: IconStyleData(
                  icon: SvgPicture.asset(
                    Assets.svg.chevronDown,
                    width: 12,
                    height: 6,
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textFieldActiveSearchIconRight,
                  ),
                ),
                dropdownStyleData: DropdownStyleData(
                  offset: const Offset(0, -10),
                  elevation: 0,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textFieldDefaultBG,
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                  ),
                ),
                menuItemStyleData: const MenuItemStyleData(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            if (_selectedOptions == NewWalletOptions.Advanced)
              Column(
                children: [
                  if (Util.isDesktop && lengths.length > 1)
                    DropdownButtonHideUnderline(
                      child: DropdownButton2<int>(
                        value: ref
                            .watch(mnemonicWordCountStateProvider.state)
                            .state,
                        items: [
                          ...lengths.map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                "$e word seed",
                                style: STextStyles.desktopTextMedium(context),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value is int) {
                            ref
                                .read(mnemonicWordCountStateProvider.state)
                                .state = value;
                          }
                        },
                        isExpanded: true,
                        iconStyleData: IconStyleData(
                          icon: SvgPicture.asset(
                            Assets.svg.chevronDown,
                            width: 12,
                            height: 6,
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textFieldActiveSearchIconRight,
                          ),
                        ),
                        dropdownStyleData: DropdownStyleData(
                          offset: const Offset(0, -10),
                          elevation: 0,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textFieldDefaultBG,
                            borderRadius: BorderRadius.circular(
                              Constants.size.circularBorderRadius,
                            ),
                          ),
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  if (!Util.isDesktop && lengths.length > 1)
                    MobileMnemonicLengthSelector(
                      chooseMnemonicLength: () {
                        showModalBottomSheet<dynamic>(
                          backgroundColor: Colors.transparent,
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (_) {
                            return MnemonicWordCountSelectSheet(
                              lengthOptions: lengths,
                            );
                          },
                        );
                      },
                    ),
                  if (widget.coin.hasMnemonicPassphraseSupport)
                    const SizedBox(
                      height: 24,
                    ),
                  if (widget.coin.hasMnemonicPassphraseSupport)
                    RoundedWhiteContainer(
                      child: Center(
                        child: Text(
                          "You may add a BIP39 passphrase. This is optional. "
                          "You will need BOTH your seed and your passphrase to recover the wallet.",
                          style: Util.isDesktop
                              ? STextStyles.desktopTextExtraSmall(context)
                                  .copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textSubtitle1,
                                )
                              : STextStyles.itemSubtitle(context),
                        ),
                      ),
                    ),
                  if (widget.coin.hasMnemonicPassphraseSupport)
                    const SizedBox(
                      height: 8,
                    ),
                  if (widget.coin.hasMnemonicPassphraseSupport)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        Constants.size.circularBorderRadius,
                      ),
                      child: TextField(
                        key: const Key("mnemonicPassphraseFieldKey1"),
                        focusNode: passwordFocusNode,
                        controller: passwordController,
                        style: Util.isDesktop
                            ? STextStyles.desktopTextMedium(context).copyWith(
                                height: 2,
                              )
                            : STextStyles.field(context),
                        obscureText: hidePassword,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: standardInputDecoration(
                          "BIP39 passphrase",
                          passwordFocusNode,
                          context,
                        ).copyWith(
                          suffixIcon: UnconstrainedBox(
                            child: ConditionalParent(
                              condition: Util.isDesktop,
                              builder: (child) => SizedBox(
                                height: 70,
                                child: child,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: Util.isDesktop ? 24 : 16,
                                  ),
                                  GestureDetector(
                                    key: const Key(
                                      "mnemonicPassphraseFieldShowPasswordButtonKey",
                                    ),
                                    onTap: () async {
                                      setState(() {
                                        hidePassword = !hidePassword;
                                      });
                                    },
                                    child: SvgPicture.asset(
                                      hidePassword
                                          ? Assets.svg.eye
                                          : Assets.svg.eyeSlash,
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .textDark3,
                                      width: Util.isDesktop ? 24 : 16,
                                      height: Util.isDesktop ? 24 : 16,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (widget.coin is ViewOnlyOptionCurrencyInterface)
                    const SizedBox(
                      height: 24,
                    ),
                  if (widget.coin is ViewOnlyOptionCurrencyInterface)
                    CheckboxTextButton(
                      label: "Convert to view only wallet. "
                          "You will only be shown the seed phrase once. "
                          "Save it somewhere. "
                          "If you lose it you will lose access to any funds in this wallet.",
                      onChanged: (value) {
                        _convertToViewOnly = value;
                      },
                    ),
                ],
              ),
            if (!Util.isDesktop) const Spacer(),
            SizedBox(
              height: Util.isDesktop ? 32 : 16,
            ),
            PrimaryButton(
              label: "Continue",
              onPressed: () {
                if (_selectedOptions == NewWalletOptions.Advanced) {
                  ref.read(pNewWalletOptions.notifier).state = (
                    mnemonicWordsCount:
                        ref.read(mnemonicWordCountStateProvider.state).state,
                    mnemonicPassphrase: passwordController.text,
                    convertToViewOnly: _convertToViewOnly,
                  );
                } else {
                  ref.read(pNewWalletOptions.notifier).state = null;
                }

                Navigator.of(context).pushNamed(
                  NewWalletRecoveryPhraseWarningView.routeName,
                  arguments: Tuple2(
                    widget.walletName,
                    widget.coin,
                  ),
                );
              },
            ),
            if (!Util.isDesktop)
              const SizedBox(
                height: 16,
              ),
            if (Util.isDesktop)
              const Spacer(
                flex: 15,
              ),
          ],
        ),
      ),
    );
  }
}
