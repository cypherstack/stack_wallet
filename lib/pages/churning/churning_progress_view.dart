import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../providers/churning/churning_service_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/text_styles.dart';
import '../../widgets/background.dart';
import '../../widgets/churning/churn_progress_item.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/rounded_container.dart';
import '../../widgets/stack_dialog.dart';
import 'churn_error_dialog.dart';

class ChurningProgressView extends ConsumerStatefulWidget {
  const ChurningProgressView({
    super.key,
    required this.walletId,
  });

  static const routeName = "/churningProgressView";

  final String walletId;
  @override
  ConsumerState<ChurningProgressView> createState() =>
      _ChurningProgressViewState();
}

class _ChurningProgressViewState extends ConsumerState<ChurningProgressView> {
  Future<bool> _requestAndProcessCancel() async {
    final shouldCancel = await showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StackDialog(
        title: "Cancel churning?",
        leftButton: SecondaryButton(
          label: "No",
          buttonHeight: null,
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        rightButton: PrimaryButton(
          label: "Yes",
          buttonHeight: null,
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ),
    );

    if (shouldCancel == true && mounted) {
      ref.read(pChurningService(widget.walletId)).stopChurning();

      await WakelockPlus.disable();

      return true;
    } else {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(pChurningService(widget.walletId)).churn();
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool _succeeded = ref.watch(
      pChurningService(widget.walletId).select((s) => s.done),
    );

    final int _roundsCompleted = ref.watch(
      pChurningService(widget.walletId).select((s) => s.roundsCompleted),
    );

    WakelockPlus.enable();

    ref.listen(
      pChurningService(widget.walletId).select((s) => s.lastSeenError),
      (p, n) {
        if (!ref.read(pChurningService(widget.walletId)).ignoreErrors &&
            n != null) {
          if (context.mounted) {
            showDialog<void>(
              context: context,
              builder: (context) => ChurnErrorDialog(
                error: n.toString(),
                walletId: widget.walletId,
              ),
            );
          }
        }
      },
    );

    return WillPopScope(
      onWillPop: () async {
        return await _requestAndProcessCancel();
      },
      child: Background(
        child: SafeArea(
          child: Scaffold(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: AppBarBackButton(
                onPressed: () async {
                  if (await _requestAndProcessCancel()) {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
              title: Text(
                "Churning progress",
                style: STextStyles.navBarTitle(context),
              ),
              titleSpacing: 0,
            ),
            body: LayoutBuilder(
              builder: (builderContext, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_roundsCompleted == 0)
                              RoundedContainer(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .snackBarBackError,
                                child: Text(
                                  "Do not close this window. If you exit, "
                                  "the process will be canceled.",
                                  style:
                                      STextStyles.smallMed14(context).copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .snackBarTextError,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            if (_roundsCompleted > 0)
                              RoundedContainer(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .snackBarBackInfo,
                                child: Text(
                                  "Churning rounds completed: $_roundsCompleted",
                                  style: STextStyles.w500_14(context).copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .snackBarTextInfo,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            const SizedBox(
                              height: 20,
                            ),
                            ProgressItem(
                              iconAsset: Assets.svg.peers,
                              label: "Waiting for balance to unlock",
                              status: ref.watch(
                                pChurningService(widget.walletId)
                                    .select((s) => s.waitingForUnlockedBalance),
                              ),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            ProgressItem(
                              iconAsset: Assets.svg.fusing,
                              label: "Creating churn transaction",
                              status: ref.watch(
                                pChurningService(widget.walletId)
                                    .select((s) => s.makingChurnTransaction),
                              ),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            ProgressItem(
                              iconAsset: Assets.svg.checkCircle,
                              label: "Complete",
                              status: ref.watch(
                                pChurningService(widget.walletId)
                                    .select((s) => s.completedStatus),
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(
                              height: 16,
                            ),
                            if (_succeeded)
                              PrimaryButton(
                                label: "Churn again",
                                onPressed: ref
                                    .read(pChurningService(widget.walletId))
                                    .churn,
                              ),
                            if (_succeeded)
                              const SizedBox(
                                height: 16,
                              ),
                            SecondaryButton(
                              label: "Cancel",
                              onPressed: () async {
                                if (await _requestAndProcessCancel()) {
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
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
