import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../frost_route_generator.dart';
import '../../../../pages_desktop_specific/desktop_home_view.dart';
import '../../../../pages_desktop_specific/my_stack_view/wallet_view/desktop_wallet_view.dart';
import '../../../../providers/db/main_db_provider.dart';
import '../../../../providers/frost_wallet/frost_wallet_providers.dart';
import '../../../../providers/global/node_service_provider.dart';
import '../../../../providers/global/prefs_provider.dart';
import '../../../../providers/global/secure_store_provider.dart';
import '../../../../providers/global/wallets_provider.dart';
import '../../../../utilities/logger.dart';
import '../../../../utilities/show_loading.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../utilities/util.dart';
import '../../../../wallets/wallet/impl/bitcoin_frost_wallet.dart';
import '../../../../widgets/custom_buttons/simple_copy_button.dart';
import '../../../../widgets/desktop/primary_button.dart';
import '../../../../widgets/detail_item.dart';
import '../../../../widgets/dialogs/frost/frost_error_dialog.dart';
import '../../../home_view/home_view.dart';
import '../../../wallet_view/transaction_views/transaction_details_view.dart';
import '../../../wallet_view/wallet_view.dart';

// was VerifyUpdatedWalletView
class FrostReshareStep5 extends ConsumerStatefulWidget {
  const FrostReshareStep5({super.key});

  static const String routeName = "/frostReshareStep5";
  static const String title = "Verify";

  @override
  ConsumerState<FrostReshareStep5> createState() => _FrostReshareStep5State();
}

class _FrostReshareStep5State extends ConsumerState<FrostReshareStep5> {
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
        wallet = ref
                .read(pWallets)
                .getWallet(ref.read(pFrostScaffoldArgs)!.walletId!)
            as BitcoinFrostWallet;
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
          rootNavigator: true,
          onException: (e) => ex = e,
        );

        if (ex != null) {
          throw ex!;
        }

        if (mounted) {
          ref.read(pFrostResharingData).reset();
          ref.read(pFrostScaffoldCanPopDesktop.notifier).state = true;
          ref.read(pFrostScaffoldArgs)?.parentNav.popUntil(
                ModalRoute.withName(
                  _popUntilPath,
                ),
              );
        }
      }
    } catch (e, s) {
      Logging.instance.f("$e\n$s", error: e, stackTrace: s,);
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => FrostErrorDialog(
            title: "Error",
            message: e.toString(),
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
            ref.read(pFrostScaffoldArgs)!.walletId!;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            "Ensure your reshare ID matches that of each other participant",
            style: STextStyles.pageTitleH2(context),
          ),
          const SizedBox(
            height: 12,
          ),
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
          const SizedBox(
            height: 12,
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            "Back up your keys and config",
            style: STextStyles.pageTitleH2(context),
          ),
          const SizedBox(
            height: 12,
          ),
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
          const SizedBox(
            height: 12,
          ),
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
          const SizedBox(
            height: 12,
          ),
          PrimaryButton(
            label: "Confirm",
            onPressed: _onPressed,
          ),
        ],
      ),
    );
  }
}
