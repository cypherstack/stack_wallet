import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/settings_views/wallet_settings_view/frost_ms/initiate_resharing/complete_reshare_config_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/isar/models/frost_wallet_info.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

final class InitiateResharingView extends ConsumerStatefulWidget {
  const InitiateResharingView({
    super.key,
    required this.walletId,
  });

  static const String routeName = "/beginReshareConfigView";

  final String walletId;

  @override
  ConsumerState<InitiateResharingView> createState() =>
      _BeginReshareConfigViewState();
}

class _BeginReshareConfigViewState
    extends ConsumerState<InitiateResharingView> {
  late final String myName;
  late final int currentThreshold;
  late final List<String> originalParticipants;
  late final List<String> currentParticipantsWithoutMe;

  final Set<String> selectedParticipants = {};

  @override
  void initState() {
    ref.read(pFrostResharingData).reset();

    // TODO: optimize this by creating watcher providers (similar to normal WalletInfo)
    final frostInfo = ref
        .read(mainDBProvider)
        .isar
        .frostWalletInfo
        .getByWalletIdSync(widget.walletId)!;

    currentThreshold = frostInfo.threshold;
    originalParticipants = frostInfo.participants.toList(growable: false);
    currentParticipantsWithoutMe = originalParticipants.toList();

    // sanity check (should never actually fail, but very bad if it does)
    assert(originalParticipants.length == currentParticipantsWithoutMe.length);

    myName = frostInfo.myName;
    currentParticipantsWithoutMe.remove(myName);

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
              leading: AppBarBackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Text(
                "Initiate resharing",
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RoundedWhiteContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Select group members who will participate in resharing.",
                    style: STextStyles.w600_12(context),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    "You must have the threshold number of members (including you) to initiate resharing.",
                    style: STextStyles.w600_12(context).copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .customTextButtonEnabledText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Column(
              children: [
                for (int i = 0; i < currentParticipantsWithoutMe.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                    ),
                    child: RoundedWhiteContainer(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        if (selectedParticipants
                            .contains(currentParticipantsWithoutMe[i])) {
                          selectedParticipants
                              .remove(currentParticipantsWithoutMe[i]);
                        } else {
                          selectedParticipants
                              .add(currentParticipantsWithoutMe[i]);
                        }

                        setState(() {});
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: IgnorePointer(
                          child: Row(
                            children: [
                              Checkbox(
                                value: selectedParticipants
                                    .contains(currentParticipantsWithoutMe[i]),
                                onChanged: (_) {},
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Text(
                                currentParticipantsWithoutMe[i],
                                style: STextStyles.itemSubtitle12(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (!Util.isDesktop) const Spacer(),
            const SizedBox(
              height: 16,
            ),
            RoundedWhiteContainer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Required members",
                    style: STextStyles.w500_14(context).copyWith(
                      color:
                          Theme.of(context).extension<StackColors>()!.textDark3,
                    ),
                  ),
                  Text(
                    // +1 is included as the initiator who will also take part
                    "${selectedParticipants.length + 1} / $currentThreshold",
                    style: STextStyles.w500_14(context).copyWith(
                      color: selectedParticipants.length + 1 >= currentThreshold
                          ? Theme.of(context)
                              .extension<StackColors>()!
                              .accentColorGreen
                          : Theme.of(context)
                              .extension<StackColors>()!
                              .accentColorRed,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            PrimaryButton(
              label: "Continue",
              // +1 is included as the initiator who will also take part
              enabled: selectedParticipants.length + 1 >= currentThreshold,
              onPressed: () async {
                // include self now
                selectedParticipants.add(myName);

                final Map<String, int> resharers = {};

                for (final name in selectedParticipants) {
                  resharers[name] = originalParticipants.indexOf(name);
                }

                await Navigator.of(context).pushNamed(
                  CompleteReshareConfigView.routeName,
                  arguments: (
                    walletId: widget.walletId,
                    resharers: resharers,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
