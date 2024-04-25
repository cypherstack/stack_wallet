import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/home_view/home_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/pages/wallet_view/wallet_view.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_home_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/desktop_wallet_view.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/providers/global/node_service_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/show_loading.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_frost_wallet.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/detail_item.dart';
import 'package:stackwallet/widgets/dialogs/frost/frost_interruption_dialog.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class VerifyUpdatedWalletView extends ConsumerStatefulWidget {
  const VerifyUpdatedWalletView({
    super.key,
    required this.walletId,
  });

  static const String routeName = "/verifyUpdatedWalletView";

  final String walletId;

  @override
  ConsumerState<VerifyUpdatedWalletView> createState() =>
      _VerifyUpdatedWalletViewState();
}

class _VerifyUpdatedWalletViewState
    extends ConsumerState<VerifyUpdatedWalletView> {
  late final String config;
  late final String serializedKeys;
  late final String reshareId;

  late final bool isNew;

  bool _buttonLock = false;
  Future<void> _onPressed() async {
    if (_buttonLock) {
      return;
    }
    _buttonLock = true;

    try {
      Exception? ex;

      final BitcoinFrostWallet wallet;

      if (isNew) {
        wallet = await ref
            .read(pFrostResharingData)
            .incompleteWallet!
            .toBitcoinFrostWallet(
              mainDB: ref.read(mainDBProvider),
              secureStorageInterface: ref.read(secureStoreProvider),
              nodeService: ref.read(nodeServiceChangeNotifierProvider),
              prefs: ref.read(prefsChangeNotifierProvider),
            );

        await wallet.info.setMnemonicVerified(
          isar: ref.read(mainDBProvider).isar,
        );

        ref.read(pWallets).addWallet(wallet);
      } else {
        wallet =
            ref.read(pWallets).getWallet(widget.walletId) as BitcoinFrostWallet;
      }

      if (mounted) {
        await showLoading(
          whileFuture: wallet.updateWithResharedData(
            serializedKeys: serializedKeys,
            multisigConfig: config,
            isNewWallet: isNew,
          ),
          context: context,
          message: isNew ? "Creating wallet" : "Updating wallet data",
          isDesktop: Util.isDesktop,
          onException: (e) => ex = e,
        );

        if (ex != null) {
          throw ex!;
        }

        if (mounted) {
          ref.read(pFrostResharingData).reset();

          Navigator.of(context).popUntil(
            ModalRoute.withName(
              _popUntilPath,
            ),
          );
        }
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
            title: "Error",
            message: e.toString(),
            desktopPopRootNavigator: Util.isDesktop,
          ),
        );
      }
    } finally {
      _buttonLock = false;
    }
  }

  String get _popUntilPath => isNew
      ? Util.isDesktop
          ? DesktopHomeView.routeName
          : HomeView.routeName
      : Util.isDesktop
          ? DesktopWalletView.routeName
          : WalletView.routeName;

  @override
  void initState() {
    config = ref.read(pFrostResharingData).newWalletData!.multisigConfig;
    serializedKeys =
        ref.read(pFrostResharingData).newWalletData!.serializedKeys;
    reshareId = ref.read(pFrostResharingData).newWalletData!.resharedId;

    isNew = ref.read(pFrostResharingData).incompleteWallet != null &&
        ref.read(pFrostResharingData).incompleteWallet!.walletId ==
            widget.walletId;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await showDialog<void>(
          context: context,
          builder: (_) => FrostInterruptionDialog(
            type: FrostInterruptionDialogType.resharing,
            popUntilOnYesRouteName: _popUntilPath,
          ),
        );
        return false;
      },
      child: ConditionalParent(
        condition: Util.isDesktop,
        builder: (child) => DesktopScaffold(
          background: Theme.of(context).extension<StackColors>()!.background,
          appBar: DesktopAppBar(
            isCompactHeight: false,
            leading: AppBarBackButton(
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  builder: (_) => FrostInterruptionDialog(
                    type: FrostInterruptionDialogType.resharing,
                    popUntilOnYesRouteName: _popUntilPath,
                  ),
                );
              },
            ),
            trailing: ExitToMyStackButton(
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  builder: (_) => FrostInterruptionDialog(
                    type: FrostInterruptionDialogType.resharing,
                    popUntilOnYesRouteName: _popUntilPath,
                  ),
                );
              },
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
                  onPressed: () async {
                    await showDialog<void>(
                      context: context,
                      builder: (_) => FrostInterruptionDialog(
                        type: FrostInterruptionDialogType.resharing,
                        popUntilOnYesRouteName: _popUntilPath,
                      ),
                    );
                  },
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
              Text(
                "Ensure your reshare ID matches that of each other participant",
                style: STextStyles.pageTitleH2(context),
              ),
              const _Div(),
              DetailItem(
                title: "ID",
                detail: reshareId,
                button: Util.isDesktop
                    ? IconCopyButton(
                        data: reshareId,
                      )
                    : SimpleCopyButton(
                        data: reshareId,
                      ),
              ),
              const _Div(),
              const _Div(),
              Text(
                "Back up your keys and config",
                style: STextStyles.pageTitleH2(context),
              ),
              const _Div(),
              DetailItem(
                title: "Config",
                detail: config,
                button: Util.isDesktop
                    ? IconCopyButton(
                        data: config,
                      )
                    : SimpleCopyButton(
                        data: config,
                      ),
              ),
              const _Div(),
              DetailItem(
                title: "Keys",
                detail: serializedKeys,
                button: Util.isDesktop
                    ? IconCopyButton(
                        data: serializedKeys,
                      )
                    : SimpleCopyButton(
                        data: serializedKeys,
                      ),
              ),
              if (!Util.isDesktop) const Spacer(),
              const _Div(),
              PrimaryButton(
                label: "Confirm",
                onPressed: _onPressed,
              ),
            ],
          ),
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
