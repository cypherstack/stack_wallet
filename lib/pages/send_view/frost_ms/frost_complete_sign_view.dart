import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/pages/wallet_view/wallet_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/my_stack_view.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/show_loading.dart';
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
import 'package:stackwallet/widgets/stack_dialog.dart';

class FrostCompleteSignView extends ConsumerStatefulWidget {
  const FrostCompleteSignView({
    super.key,
    required this.walletId,
  });

  static const String routeName = "/frostCompleteSignView";

  final String walletId;

  @override
  ConsumerState<FrostCompleteSignView> createState() =>
      _FrostCompleteSignViewState();
}

class _FrostCompleteSignViewState extends ConsumerState<FrostCompleteSignView> {
  bool _broadcastLock = false;

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
                "Preview transaction",
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  QrImageView(
                    data: ref.watch(pFrostTxData.state).state!.raw!,
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
            const _Div(),
            DetailItem(
              title: "Raw transaction hex",
              detail: ref.watch(pFrostTxData.state).state!.raw!,
              button: Util.isDesktop
                  ? IconCopyButton(
                      data: ref.watch(pFrostTxData.state).state!.raw!,
                    )
                  : SimpleCopyButton(
                      data: ref.watch(pFrostTxData.state).state!.raw!,
                    ),
            ),
            const _Div(),
            if (!Util.isDesktop) const Spacer(),
            const _Div(),
            PrimaryButton(
              label: "Broadcast Transaction",
              onPressed: () async {
                if (_broadcastLock) {
                  return;
                }
                _broadcastLock = true;

                try {
                  Exception? ex;
                  final txData = await showLoading(
                    whileFuture: ref
                        .read(walletsChangeNotifierProvider)
                        .getManager(widget.walletId)
                        .confirmSend(
                          txData: ref.read(pFrostTxData.state).state!,
                        ),
                    context: context,
                    message: "Broadcasting transaction to network",
                    isDesktop: Util.isDesktop,
                    onException: (e) {
                      ex = e;
                    },
                  );

                  if (ex != null) {
                    throw ex!;
                  }

                  if (mounted) {
                    if (txData != null) {
                      ref.read(pFrostTxData.state).state = txData;
                      Navigator.of(context).popUntil(
                        ModalRoute.withName(
                          Util.isDesktop
                              ? MyStackView.routeName
                              : WalletView.routeName,
                        ),
                      );
                    }
                  }
                } catch (e, s) {
                  Logging.instance.log(
                    "$e\n$s",
                    level: LogLevel.Fatal,
                  );

                  return await showDialog<void>(
                    context: context,
                    builder: (_) => StackOkDialog(
                      title: "Broadcast error",
                      message: e.toString(),
                      desktopPopRootNavigator: Util.isDesktop,
                    ),
                  );
                } finally {
                  _broadcastLock = false;
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Div extends StatelessWidget {
  const _Div({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 12,
    );
  }
}
