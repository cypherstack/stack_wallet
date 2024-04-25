import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/frost_scaffold.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/new/steps/frost_route_generator.dart';
import 'package:stackwallet/pages/home_view/home_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_home_view.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/services/frost.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/frost_currency.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/detail_item.dart';
import 'package:stackwallet/widgets/dialogs/simple_mobile_dialog.dart';
import 'package:stackwallet/widgets/frost_mascot.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class ShareNewMultisigConfigView extends ConsumerStatefulWidget {
  const ShareNewMultisigConfigView({
    super.key,
    required this.walletName,
    required this.frostCurrency,
  });

  static const String routeName = "/shareNewMultisigConfigView";

  final String walletName;
  final FrostCurrency frostCurrency;

  @override
  ConsumerState<ShareNewMultisigConfigView> createState() =>
      _ShareNewMultisigConfigViewState();
}

class _ShareNewMultisigConfigViewState
    extends ConsumerState<ShareNewMultisigConfigView> {
  bool _userVerifyContinue = false;

  void _showParticipantsDialog() {
    final participants = Frost.getParticipants(
      multisigConfig: ref.read(pFrostMultisigConfig.state).state!,
    );

    showDialog<void>(
      context: context,
      builder: (_) => SimpleMobileDialog(
        showCloseButton: false,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 24,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Group participants",
                style: STextStyles.w600_20(context),
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "The names are case-sensitive and must be entered exactly.",
                style: STextStyles.w400_16(context).copyWith(
                  color: Theme.of(context).extension<StackColors>()!.textDark3,
                ),
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            for (final participant in participants)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    height: 1.5,
                    color:
                        Theme.of(context).extension<StackColors>()!.background,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textFieldActiveBG,
                            borderRadius: BorderRadius.circular(
                              200,
                            ),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              Assets.svg.user,
                              width: 16,
                              height: 16,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child: Text(
                            participant,
                            style: STextStyles.w500_14(context),
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        IconCopyButton(
                          data: participant,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                ],
              ),
            const SizedBox(
              height: 24,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: Util.isDesktop,
      builder: (child) => DesktopScaffold(
        background: Theme.of(context).extension<StackColors>()!.background,
        appBar: const DesktopAppBar(
          isCompactHeight: false,
          leading: AppBarBackButton(),
          // TODO: [prio=high] get rid of placeholder text??
          trailing: FrostMascot(
            title: 'Lorem ipsum',
            body:
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam est justo, ',
          ),
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
              leading: AppBarBackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Text(
                "Share multisig group info",
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
                          padding: const EdgeInsets.all(16),
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
            const _SharingStepsInfo(),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              height: 220,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  QrImageView(
                    data:
                        ref.watch(pFrostMultisigConfig.state).state ?? "Error",
                    size: 220,
                    backgroundColor:
                        Theme.of(context).extension<StackColors>()!.background,
                    foregroundColor: Theme.of(context)
                        .extension<StackColors>()!
                        .accentColorDark,
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            DetailItem(
              title: "Encoded config",
              detail: ref.watch(pFrostMultisigConfig.state).state ?? "Error",
              button: Util.isDesktop
                  ? IconCopyButton(
                      data: ref.watch(pFrostMultisigConfig.state).state ??
                          "Error",
                    )
                  : SimpleCopyButton(
                      data: ref.watch(pFrostMultisigConfig.state).state ??
                          "Error",
                    ),
            ),
            SizedBox(
              height: Util.isDesktop ? 64 : 16,
            ),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: "Show group participants",
                    onPressed: _showParticipantsDialog,
                  ),
                ),
              ],
            ),
            if (!Util.isDesktop)
              const Spacer(
                flex: 2,
              ),
            const SizedBox(
              height: 16,
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _userVerifyContinue = !_userVerifyContinue;
                });
              },
              child: Container(
                color: Colors.transparent,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 26,
                      child: Checkbox(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        value: _userVerifyContinue,
                        onChanged: (value) => setState(
                          () => _userVerifyContinue = value == true,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child: Text(
                        "I have verified that everyone has joined the group",
                        style: STextStyles.w500_14(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            PrimaryButton(
              label: "Start key generation",
              enabled: _userVerifyContinue,
              onPressed: () async {
                ref.read(pFrostStartKeyGenData.notifier).state =
                    Frost.startKeyGeneration(
                  multisigConfig: ref.watch(pFrostMultisigConfig.state).state!,
                  myName: ref.read(pFrostMyName.state).state!,
                );

                ref.read(pFrostCreateNewArgs.state).state = (
                  (
                    walletName: widget.walletName,
                    frostCurrency: widget.frostCurrency,
                  ),
                  FrostRouteGenerator.createNewConfigStepRoutes,
                  () {
                    // successful completion of steps
                    if (Util.isDesktop) {
                      Navigator.of(context).popUntil(
                        ModalRoute.withName(
                          DesktopHomeView.routeName,
                        ),
                      );
                    } else {
                      unawaited(
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          HomeView.routeName,
                          (route) => false,
                        ),
                      );
                    }

                    ref.read(pFrostMultisigConfig.state).state = null;
                    ref.read(pFrostStartKeyGenData.state).state = null;
                    ref.read(pFrostSecretSharesData.state).state = null;
                    ref.read(pFrostCreateNewArgs.state).state = null;

                    unawaited(
                      showFloatingFlushBar(
                        type: FlushBarType.success,
                        message: "Your wallet is set up.",
                        iconAsset: Assets.svg.check,
                        context: context,
                      ),
                    );
                  }
                );

                await Navigator.of(context).pushNamed(
                  FrostStepScaffold.routeName,
                  // FrostShareCommitmentsView.routeName,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SharingStepsInfo extends StatelessWidget {
  const _SharingStepsInfo({super.key});

  static const steps = [
    "Share this config with the group participants.",
    "Wait for them to join the group.",
    "Verify that everyone has filled out their forms before continuing. If you "
        "try to continue before everyone is ready, the process will be canceled.",
    "Check the box and press “Generate keys”.",
  ];

  @override
  Widget build(BuildContext context) {
    final style = STextStyles.w500_12(context);
    return RoundedWhiteContainer(
      child: Column(
        children: [
          for (int i = 0; i < steps.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${i + 1}.",
                  style: style,
                ),
                const SizedBox(
                  width: 4,
                ),
                Expanded(
                  child: Text(
                    steps[i],
                    style: style,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
