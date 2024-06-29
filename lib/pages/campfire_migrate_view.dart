import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/special_migrations.dart';
import '../themes/stack_colors.dart';
import '../utilities/text_styles.dart';
import '../utilities/util.dart';
import '../widgets/app_icon.dart';
import '../widgets/background.dart';
import '../widgets/custom_buttons/blue_text_button.dart';
import '../widgets/custom_buttons/checkbox_text_button.dart';
import '../widgets/desktop/primary_button.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/rounded_container.dart';
import 'add_wallet_views/new_wallet_recovery_phrase_view/sub_widgets/mnemonic_table.dart';
import 'intro_view.dart';

class CampfireMigrateView extends StatelessWidget {
  const CampfireMigrateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: AppIcon(
                        width: 50,
                        height: 50,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Your old Campfire wallets are listed below. "
                        "If you would like to keep them then copy the mnemonics "
                        "somewhere safe so you can restore them.",
                        style: STextStyles.w600_12(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: FutureBuilder(
                          future: CampfireMigration.fetch(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              final count = (snapshot.data?.length ?? 0) + 1;

                              return ListView.separated(
                                itemCount: count,
                                separatorBuilder: (_, __) => const SizedBox(
                                  height: 10,
                                ),
                                itemBuilder: (_, index) => index == count - 1
                                    ? const _ContinueButtonGroup()
                                    : _CampfireWallet(
                                        mnemonic: snapshot.data![index].$2,
                                        name: snapshot.data![index].$1,
                                      ),
                              );
                            } else {
                              return const Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  LoadingIndicator(
                                    width: 100,
                                    height: 100,
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),
                    ],
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

class _ContinueButtonGroup extends StatefulWidget {
  const _ContinueButtonGroup({super.key});

  @override
  State<_ContinueButtonGroup> createState() => _ContinueButtonGroupState();
}

class _ContinueButtonGroupState extends State<_ContinueButtonGroup> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 10,
        ),
        CheckboxTextButton(
          label: "I have saved all my mnemonics and double checked each one",
          onChanged: (value) {
            setState(() {
              _checked = value;
            });
          },
        ),
        const SizedBox(
          height: 16,
        ),
        PrimaryButton(
          enabled: _checked,
          label: "Continue",
          onPressed: () {
            CampfireMigration.setDidRun();
            // could do pushReplacementNamed but we won't show this again on next run anyways
            Navigator.of(context).pushNamed(
              IntroView.routeName,
            );
          },
        ),
      ],
    );
  }
}

class _CampfireWallet extends StatefulWidget {
  const _CampfireWallet({
    super.key,
    required this.name,
    required this.mnemonic,
  });

  final String name;
  final List<String> mnemonic;

  @override
  State<_CampfireWallet> createState() => _CampfireWalletState();
}

class _CampfireWalletState extends State<_CampfireWallet> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    return RoundedContainer(
      color: Theme.of(context).extension<StackColors>()!.background,
      borderColor: Theme.of(context).extension<StackColors>()!.textDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.name,
                style: STextStyles.w500_14(context),
              ),
              CustomTextButton(
                text: "Copy mnemonic",
                onTap: () => Clipboard.setData(
                  ClipboardData(
                    text: widget.mnemonic.join(" "),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          _show
              ? MnemonicTable(
                  words: widget.mnemonic,
                  isDesktop: Util.isDesktop,
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: PrimaryButton(
                    label: "Show mnemonic",
                    onPressed: () => setState(() => _show = true),
                  ),
                ),
        ],
      ),
    );
  }
}
