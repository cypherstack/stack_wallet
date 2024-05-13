import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/frost_route_generator.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/frost.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_frost_wallet.dart';
import 'package:stackwallet/widgets/custom_buttons/checkbox_text_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/frost_step_user_steps.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/textfields/frost_step_field.dart';

class FrostSendStep1b extends ConsumerStatefulWidget {
  const FrostSendStep1b({super.key});

  static const String routeName = "/FrostSendStep1b";
  static const String title = "Sign FROST transaction";

  @override
  ConsumerState<FrostSendStep1b> createState() => _FrostSendStep1bState();
}

class _FrostSendStep1bState extends ConsumerState<FrostSendStep1b> {
  static const info = [
    "Scan the config QR code or paste the code provided by the member "
        "initiating this transaction.",
    "Wait for other members to finish entering their information.",
    "Verify that everyone has filled out their forms before continuing. If you "
        "try to continue before everyone is ready, the process will be "
        "canceled.",
    "Check the box and press “Start signing”.",
  ];

  late final TextEditingController configFieldController;
  late final FocusNode configFocusNode;

  bool _configEmpty = true, _userVerifyContinue = false;

  bool _attemptSignLock = false;

  Future<void> _attemptSign() async {
    if (_attemptSignLock) {
      return;
    }

    _attemptSignLock = true;

    try {
      if (FocusScope.of(context).hasFocus) {
        FocusScope.of(context).unfocus();
      }

      final config = configFieldController.text;
      final wallet = ref.read(pWallets).getWallet(
            ref.read(pFrostScaffoldArgs)!.walletId!,
          ) as BitcoinFrostWallet;

      final data = Frost.extractDataFromSignConfig(
        signConfig: config,
        coin: wallet.cryptoCurrency,
      );

      final utxos = await ref
          .read(mainDBProvider)
          .getUTXOs(wallet.walletId)
          .filter()
          .anyOf(
              data.inputs,
              (q, e) => q
                  .txidEqualTo(Format.uint8listToString(e.hash))
                  .and()
                  .valueEqualTo(e.value)
                  .and()
                  .voutEqualTo(e.vout))
          .findAll();

      // TODO add more data from 'data' and display to user ?
      ref.read(pFrostTxData.notifier).state = TxData(
        frostMSConfig: config,
        recipients: data.recipients
            .map((e) => (address: e.address, amount: e.amount, isChange: false))
            .toList(),
        utxos: utxos.toSet(),
      );

      final attemptSignRes = await wallet.frostAttemptSignConfig(
        config: ref.read(pFrostTxData.state).state!.frostMSConfig!,
      );

      ref.read(pFrostAttemptSignData.notifier).state = attemptSignRes;

      ref.read(pFrostCreateCurrentStep.state).state = 2;
      await Navigator.of(context).pushNamed(
        ref
            .read(pFrostScaffoldArgs)!
            .stepRoutes[ref.read(pFrostCreateCurrentStep) - 1]
            .routeName,
      );
    } catch (e, s) {
      Logging.instance.log(
        "$e\n$s",
        level: LogLevel.Error,
      );
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => StackOkDialog(
            title: "Import and attempt sign config failed",
            message: e.toString(),
            desktopPopRootNavigator: Util.isDesktop,
          ),
        );
      }
    } finally {
      _attemptSignLock = false;
    }
  }

  @override
  void initState() {
    configFieldController = TextEditingController();
    configFocusNode = FocusNode();
    final wallet = ref.read(pWallets).getWallet(
          ref.read(pFrostScaffoldArgs)!.walletId!,
        ) as BitcoinFrostWallet;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pFrostMyName.state).state = wallet.frostInfo.myName;
    });
    super.initState();
  }

  @override
  void dispose() {
    configFieldController.dispose();
    configFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FrostStepUserSteps(
            userSteps: info,
          ),
          const SizedBox(height: 20),
          FrostStepField(
            controller: configFieldController,
            focusNode: configFocusNode,
            showQrScanOption: true,
            label: "Import sign config",
            hint: "Enter config",
            onChanged: (_) {
              setState(() {
                _configEmpty = configFieldController.text.isEmpty;
              });
            },
          ),
          if (!Util.isDesktop) const Spacer(),
          const SizedBox(
            height: 12,
          ),
          CheckboxTextButton(
            label: "I have verified that everyone has imported he config and"
                " is ready to sign",
            onChanged: (value) {
              setState(() {
                _userVerifyContinue = value;
              });
            },
          ),
          const SizedBox(
            height: 12,
          ),
          PrimaryButton(
            label: "Start signing",
            enabled: !_configEmpty && _userVerifyContinue,
            onPressed: () {
              _attemptSign();
            },
          ),
        ],
      ),
    );
  }
}
