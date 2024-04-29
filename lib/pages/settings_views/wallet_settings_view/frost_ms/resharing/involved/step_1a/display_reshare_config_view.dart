import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/pages/settings_views/wallet_settings_view/frost_ms/resharing/involved/step_2/begin_resharing_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/frost.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/isar/models/frost_wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_frost_wallet.dart';
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
import 'package:stackwallet/widgets/frost_step_user_steps.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class DisplayReshareConfigView extends ConsumerStatefulWidget {
  const DisplayReshareConfigView({
    super.key,
    required this.walletId,
  });

  static const String routeName = "/displayReshareConfigView";

  final String walletId;

  @override
  ConsumerState<DisplayReshareConfigView> createState() =>
      _DisplayReshareConfigViewState();
}

class _DisplayReshareConfigViewState
    extends ConsumerState<DisplayReshareConfigView> {
  static const info = [
    "Share this config with the signing group participants as well as any new "
        "participant.",
    "Wait for them to import the config.",
    "Verify that everyone has imported the config. If you try to continue "
        "before everyone is ready, the process will be canceled.",
    "Check the box and press “Start resharing”.",
  ];

  late final bool iAmInvolved;

  bool _buttonLock = false;
  bool _userVerifyContinue = false;

  Future<void> _onPressed() async {
    if (_buttonLock) {
      return;
    }
    _buttonLock = true;

    try {
      final wallet =
          ref.read(pWallets).getWallet(widget.walletId) as BitcoinFrostWallet;

      final serializedKeys = await wallet.getSerializedKeys();
      if (mounted) {
        final result = Frost.beginResharer(
          serializedKeys: serializedKeys!,
          config: ref.read(pFrostResharingData).resharerConfig!,
        );

        ref.read(pFrostResharingData).startResharerData = result;

        await Navigator.of(context).pushNamed(
          BeginResharingView.routeName,
          arguments: widget.walletId,
        );
      }
    } catch (e, s) {
      Logging.instance.log(
        "$e\n$s",
        level: LogLevel.Fatal,
      );

      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => StackOkDialog(
            title: e.toString(),
            desktopPopRootNavigator: Util.isDesktop,
          ),
        );
      }
    } finally {
      _buttonLock = false;
    }
  }

  void _showParticipantsDialog() {
    final participants =
        ref.read(pFrostResharingData).configData!.newParticipants;

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
  void initState() {
    // TODO: optimize this by creating watcher providers (similar to normal WalletInfo)
    final frostInfo = ref
        .read(mainDBProvider)
        .isar
        .frostWalletInfo
        .getByWalletIdSync(widget.walletId)!;

    final myOldIndex = frostInfo.participants.indexOf(frostInfo.myName);

    iAmInvolved = ref
        .read(pFrostResharingData)
        .configData!
        .resharers
        .contains(myOldIndex);
    super.initState();
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
                "Resharer config",
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
            const SizedBox(
              height: 16,
            ),
            const FrostStepUserSteps(
              userSteps: info,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  QrImageView(
                    data: ref.watch(pFrostResharingData).resharerConfig!,
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
              height: 32,
            ),
            DetailItem(
              title: "Config",
              detail: ref.watch(pFrostResharingData).resharerConfig!,
              button: Util.isDesktop
                  ? IconCopyButton(
                      data: ref.watch(pFrostResharingData).resharerConfig!,
                    )
                  : SimpleCopyButton(
                      data: ref.watch(pFrostResharingData).resharerConfig!,
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
            if (iAmInvolved && !Util.isDesktop) const Spacer(),
            if (iAmInvolved)
              const SizedBox(
                height: 16,
              ),
            if (iAmInvolved)
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
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
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
                          "I have verified that everyone has imported the config",
                          style: STextStyles.w500_14(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (iAmInvolved)
              const SizedBox(
                height: 16,
              ),
            if (iAmInvolved)
              PrimaryButton(
                label: "Start resharing",
                enabled: _userVerifyContinue,
                onPressed: _onPressed,
              ),
          ],
        ),
      ),
    );
  }
}
