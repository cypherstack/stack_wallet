import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/new/frost_share_commitments_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/services/frost.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/detail_item.dart';

class ShareNewMultisigConfigView extends ConsumerStatefulWidget {
  const ShareNewMultisigConfigView({
    super.key,
    required this.walletName,
    required this.coin,
  });

  static const String routeName = "/shareNewMultisigConfigView";

  final String walletName;
  final Coin coin;

  @override
  ConsumerState<ShareNewMultisigConfigView> createState() =>
      _ShareNewMultisigConfigViewState();
}

class _ShareNewMultisigConfigViewState
    extends ConsumerState<ShareNewMultisigConfigView> {
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
                "Multisig config",
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
            if (!Util.isDesktop) const Spacer(),
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
              height: 32,
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
            if (!Util.isDesktop)
              const Spacer(
                flex: 2,
              ),
            PrimaryButton(
              label: "Start key generation",
              onPressed: () async {
                ref.read(pFrostStartKeyGenData.notifier).state =
                    Frost.startKeyGeneration(
                  multisigConfig: ref.watch(pFrostMultisigConfig.state).state!,
                  myName: ref.read(pFrostMyName.state).state!,
                );

                await Navigator.of(context).pushNamed(
                  FrostShareCommitmentsView.routeName,
                  arguments: (
                    walletName: widget.walletName,
                    coin: widget.coin,
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
