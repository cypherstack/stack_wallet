import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../themes/stack_colors.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import 'sub_widgets/register_masternode_form.dart';

class CreateMasternodeView extends ConsumerStatefulWidget {
  const CreateMasternodeView({
    super.key,
    required this.firoWalletId,
    required this.collateralTxid,
    required this.collateralVout,
    required this.collateralAddress,
    this.popTxidOnSuccess = true,
  });

  static const routeName = "/createMasternodeView";

  final String firoWalletId;
  final String collateralTxid;
  final int collateralVout;
  final String collateralAddress;
  final bool popTxidOnSuccess;

  @override
  ConsumerState<CreateMasternodeView> createState() =>
      _CreateMasternodeDialogState();
}

class _CreateMasternodeDialogState extends ConsumerState<CreateMasternodeView> {
  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: Util.isDesktop,
      builder: (child) => SizedBox(
        width: 660,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    "Create masternode",
                    style: STextStyles.desktopH3(context),
                  ),
                ),
                const DesktopDialogCloseButton(),
              ],
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 32,
                  bottom: 32,
                  right: 32,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
      child: ConditionalParent(
        condition: !Util.isDesktop,
        builder: (child) => Background(
          child: Scaffold(
            backgroundColor: Theme.of(
              context,
            ).extension<StackColors>()!.background,
            appBar: AppBar(
              backgroundColor: Theme.of(
                context,
              ).extension<StackColors>()!.background,
              leading: AppBarBackButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                },
              ),
              title: Text(
                "Create masternode",
                style: STextStyles.navBarTitle(context),
              ),
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: child,
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
        child: RegisterMasternodeForm(
          firoWalletId: widget.firoWalletId,
          collateralTxid: widget.collateralTxid,
          collateralVout: widget.collateralVout,
          collateralAddress: widget.collateralAddress,
          onRegistrationSuccess: (txid) {
            if (widget.popTxidOnSuccess && mounted) {
              Navigator.of(context, rootNavigator: Util.isDesktop).pop(txid);
            }
          },
        ),
      ),
    );
  }
}
