import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/settings_views/wallet_settings_view/frost_ms/resharing/involved/step_1a/complete_reshare_config_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/isar/models/frost_wallet_info.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';

final class BeginReshareConfigView extends ConsumerStatefulWidget {
  const BeginReshareConfigView({
    super.key,
    required this.walletId,
  });

  static const String routeName = "/beginReshareConfigView";

  final String walletId;

  @override
  ConsumerState<BeginReshareConfigView> createState() =>
      _BeginReshareConfigViewState();
}

class _BeginReshareConfigViewState
    extends ConsumerState<BeginReshareConfigView> {
  late final int currentThreshold;
  late final List<String> currentParticipants;

  final Map<String, int> pFrostResharersMap = {};

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
    currentParticipants = frostInfo.participants;

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
              // title: Text(
              //   "Modify Participants",
              //   style: STextStyles.navBarTitle(context),
              // ),
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
            Text(
              "Select participants for resharing",
              style: STextStyles.label(context),
            ),
            const SizedBox(
              height: 16,
            ),
            Column(
              children: [
                for (int i = 0; i < currentParticipants.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                    ),
                    child: RawMaterialButton(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          Constants.size.circularBorderRadius,
                        ),
                      ),
                      onPressed: () {
                        if (pFrostResharersMap[currentParticipants[i]] ==
                            null) {
                          pFrostResharersMap[currentParticipants[i]] = i;
                        } else {
                          pFrostResharersMap.remove(currentParticipants[i]);
                        }

                        setState(() {});
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: IgnorePointer(
                          child: Row(
                            children: [
                              Checkbox(
                                value: pFrostResharersMap[
                                        currentParticipants[i]] ==
                                    i,
                                onChanged: (bool? value) {},
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Text(
                                currentParticipants[i],
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
            PrimaryButton(
              label: "Continue",
              enabled: pFrostResharersMap.length >= currentThreshold,
              onPressed: () async {
                await Navigator.of(context).pushNamed(
                  CompleteReshareConfigView.routeName,
                  arguments: (
                    walletId: widget.walletId,
                    resharers:
                        pFrostResharersMap.values.toList(growable: false),
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
