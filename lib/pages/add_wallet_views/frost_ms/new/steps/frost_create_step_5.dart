import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/frost_route_generator.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/tx_v2/transaction_v2_details_view.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/providers/global/node_service_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/frost.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_frost_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/widgets/custom_buttons/checkbox_text_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/detail_item.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

class FrostCreateStep5 extends ConsumerStatefulWidget {
  const FrostCreateStep5({super.key});

  static const String routeName = "/frostCreateStep5";
  static const String title = "Back up your keys";

  @override
  ConsumerState<FrostCreateStep5> createState() => _FrostCreateStep5State();
}

class _FrostCreateStep5State extends ConsumerState<FrostCreateStep5> {
  static const _warning = "These are your private keys. Please back them up, "
      "keep them safe and never share it with anyone. Your private keys are the"
      " only way you can access your funds if you forget PIN, lose your phone, "
      "etc. Stack Wallet does not keep nor is able to restore your private keys"
      ".";

  late final String seed, recoveryString, serializedKeys, multisigConfig;
  late final Uint8List multisigId;

  bool _userVerifyContinue = false;

  @override
  void initState() {
    seed = ref.read(pFrostStartKeyGenData.state).state!.seed;
    serializedKeys =
        ref.read(pFrostCompletedKeyGenData.state).state!.serializedKeys;
    recoveryString =
        ref.read(pFrostCompletedKeyGenData.state).state!.recoveryString;
    multisigConfig = ref.read(pFrostMultisigConfig.state).state!;
    multisigId = ref.read(pFrostCompletedKeyGenData.state).state!.multisigId;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          RoundedContainer(
            color:
                Theme.of(context).extension<StackColors>()!.warningBackground,
            child: Text(
              _warning,
              style: STextStyles.w500_14(context).copyWith(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .warningForeground,
              ),
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          CheckboxTextButton(
            label: "I have backed up my keys and the config",
            onChanged: (value) {
              setState(() {
                _userVerifyContinue = value;
              });
            },
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: "Continue",
            enabled: _userVerifyContinue,
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

                final data = ref.read(pFrostScaffoldArgs)!;

                final info = WalletInfo.createNew(
                  coin: data.info.frostCurrency.coin,
                  name: data.info.walletName,
                );

                final wallet = await Wallet.create(
                  walletInfo: info,
                  mainDB: ref.read(mainDBProvider),
                  secureStorageInterface: ref.read(secureStoreProvider),
                  nodeService: ref.read(nodeServiceChangeNotifierProvider),
                  prefs: ref.read(prefsChangeNotifierProvider),
                  mnemonic: seed,
                  mnemonicPassphrase: "",
                );

                await (wallet as BitcoinFrostWallet).initializeNewFrost(
                  multisigConfig: multisigConfig,
                  recoveryString: recoveryString,
                  serializedKeys: serializedKeys,
                  multisigId: multisigId,
                  myName: ref.read(pFrostMyName.state).state!,
                  participants: Frost.getParticipants(
                    multisigConfig: ref.read(pFrostMultisigConfig.state).state!,
                  ),
                  threshold: Frost.getThreshold(
                    multisigConfig: ref.read(pFrostMultisigConfig.state).state!,
                  ),
                );

                await info.setMnemonicVerified(
                  isar: ref.read(mainDBProvider).isar,
                );

                ref.read(pWallets).addWallet(wallet);

                // pop progress dialog
                if (context.mounted) {
                  Navigator.pop(context);
                  progressPopped = true;
                }

                if (mounted) {
                  ref.read(pFrostScaffoldCanPopDesktop.notifier).state = true;
                  ref.read(pFrostScaffoldArgs)!.onSuccess();
                }
              } catch (e, s) {
                Logging.instance.log(
                  "$e\n$s",
                  level: LogLevel.Fatal,
                );

                // pop progress dialog
                if (context.mounted && !progressPopped) {
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
    );
  }
}
