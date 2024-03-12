import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/home_view/home_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_home_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/providers/global/node_service_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/frost.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_frost_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/detail_item.dart';
import 'package:stackwallet/widgets/dialogs/frost_interruption_dialog.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';

import '../../../../wallets/isar/models/wallet_info.dart';

class ConfirmNewFrostMSWalletCreationView extends ConsumerStatefulWidget {
  const ConfirmNewFrostMSWalletCreationView({
    super.key,
    required this.walletName,
    required this.coin,
  });

  static const String routeName = "/confirmNewFrostMSWalletCreationView";

  final String walletName;
  final Coin coin;

  @override
  ConsumerState<ConfirmNewFrostMSWalletCreationView> createState() =>
      _ConfirmNewFrostMSWalletCreationViewState();
}

class _ConfirmNewFrostMSWalletCreationViewState
    extends ConsumerState<ConfirmNewFrostMSWalletCreationView> {
  late final String seed, recoveryString, serializedKeys, multisigConfig;
  late final Uint8List multisigId;

  @override
  void initState() {
    seed = ref.read(pFrostStartKeyGenData.state).state!.seed;
    serializedKeys =
        ref.read(pFrostCompletedKeyGenData.state).state!.serializedKeys;
    recoveryString =
        ref.read(pFrostCompletedKeyGenData.state).state!.recoveryString;
    multisigId = ref.read(pFrostCompletedKeyGenData.state).state!.multisigId;
    multisigConfig = ref.read(pFrostMultisigConfig.state).state!;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await showDialog<void>(
          context: context,
          builder: (_) => FrostInterruptionDialog(
            type: FrostInterruptionDialogType.walletCreation,
            popUntilOnYesRouteName:
                Util.isDesktop ? DesktopHomeView.routeName : HomeView.routeName,
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
                  builder: (_) => const FrostInterruptionDialog(
                    type: FrostInterruptionDialogType.walletCreation,
                    popUntilOnYesRouteName: DesktopHomeView.routeName,
                  ),
                );
              },
            ),
            trailing: ExitToMyStackButton(
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  builder: (_) => const FrostInterruptionDialog(
                    type: FrostInterruptionDialogType.walletCreation,
                    popUntilOnYesRouteName: DesktopHomeView.routeName,
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
                      builder: (_) => const FrostInterruptionDialog(
                        type: FrostInterruptionDialogType.walletCreation,
                        popUntilOnYesRouteName: HomeView.routeName,
                      ),
                    );
                  },
                ),
                title: Text(
                  "Finalize FROST multisig wallet",
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
              Text(
                "Ensure your multisig ID matches that of each other participant",
                style: STextStyles.pageTitleH2(context),
              ),
              const _Div(),
              DetailItem(
                title: "ID",
                detail: multisigId.toString(),
                button: Util.isDesktop
                    ? IconCopyButton(
                        data: multisigId.toString(),
                      )
                    : SimpleCopyButton(
                        data: multisigId.toString(),
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
                title: "Multisig Config",
                detail: multisigConfig,
                button: Util.isDesktop
                    ? IconCopyButton(
                        data: multisigConfig,
                      )
                    : SimpleCopyButton(
                        data: multisigConfig,
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
                onPressed: () async {
                  bool progressPopped = false;
                  try {
                    unawaited(
                      showDialog<dynamic>(
                        context: context,
                        barrierDismissible: false,
                        useSafeArea: true,
                        builder: (ctx) {
                          return const Center(
                            child: LoadingIndicator(
                              width: 50,
                              height: 50,
                            ),
                          );
                        },
                      ),
                    );

                    final info = WalletInfo.createNew(
                      coin: widget.coin,
                      name: widget.walletName,
                    );

                    final wallet = await Wallet.create(
                      walletInfo: info,
                      mainDB: ref.read(mainDBProvider),
                      secureStorageInterface: ref.read(secureStoreProvider),
                      nodeService: ref.read(nodeServiceChangeNotifierProvider),
                      prefs: ref.read(prefsChangeNotifierProvider),
                    );

                    await (wallet as BitcoinFrostWallet).initializeNewFrost(
                      mnemonic: seed,
                      multisigConfig: multisigConfig,
                      recoveryString: recoveryString,
                      serializedKeys: serializedKeys,
                      multisigId: multisigId,
                      myName: ref.read(pFrostMyName.state).state!,
                      participants: Frost.getParticipants(
                        multisigConfig:
                            ref.read(pFrostMultisigConfig.state).state!,
                      ),
                      threshold: Frost.getThreshold(
                        multisigConfig:
                            ref.read(pFrostMultisigConfig.state).state!,
                      ),
                    );

                    await info.setMnemonicVerified(
                      isar: ref.read(mainDBProvider).isar,
                    );

                    ref.read(pWallets).addWallet(wallet);

                    // pop progress dialog
                    if (mounted) {
                      Navigator.pop(context);
                      progressPopped = true;
                    }

                    if (mounted) {
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

                      unawaited(
                        showFloatingFlushBar(
                          type: FlushBarType.success,
                          message: "Your wallet is set up.",
                          iconAsset: Assets.svg.check,
                          context: context,
                        ),
                      );
                    }
                  } catch (e, s) {
                    Logging.instance.log(
                      "$e\n$s",
                      level: LogLevel.Fatal,
                    );

                    // pop progress dialog
                    if (mounted && !progressPopped) {
                      Navigator.pop(context);
                      progressPopped = true;
                    }
                    // TODO: handle gracefully
                    rethrow;
                  }
                },
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
