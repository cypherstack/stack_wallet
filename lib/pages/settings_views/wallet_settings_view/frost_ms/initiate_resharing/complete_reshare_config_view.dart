import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frostdart/frostdart.dart';
import '../../../../../frost_route_generator.dart';
import '../../../../../pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import '../../../../../providers/db/main_db_provider.dart';
import '../../../../../providers/frost_wallet/frost_wallet_providers.dart';
import '../../../../../providers/global/wallets_provider.dart';
import '../../../../../services/frost.dart';
import '../../../../../themes/stack_colors.dart';
import '../../../../../utilities/format.dart';
import '../../../../../utilities/logger.dart';
import '../../../../../utilities/text_styles.dart';
import '../../../../../utilities/util.dart';
import '../../../../../wallets/isar/models/frost_wallet_info.dart';
import '../../../../../wallets/wallet/impl/bitcoin_frost_wallet.dart';
import '../../../../../widgets/background.dart';
import '../../../../../widgets/conditional_parent.dart';
import '../../../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../../../widgets/desktop/desktop_app_bar.dart';
import '../../../../../widgets/desktop/desktop_scaffold.dart';
import '../../../../../widgets/desktop/primary_button.dart';
import '../../../../../widgets/frost_scaffold.dart';
import '../../../../../widgets/rounded_white_container.dart';
import '../../../../../widgets/stack_dialog.dart';

final class CompleteReshareConfigView extends ConsumerStatefulWidget {
  const CompleteReshareConfigView({
    super.key,
    required this.walletId,
    required this.resharers,
  });

  static const String routeName = "/completeReshareConfigView";

  final String walletId;
  final Map<String, int> resharers;

  @override
  ConsumerState<CompleteReshareConfigView> createState() =>
      _CompleteReshareConfigViewState();
}

class _CompleteReshareConfigViewState
    extends ConsumerState<CompleteReshareConfigView> {
  final _newThresholdController = TextEditingController();
  final _newParticipantsCountController = TextEditingController();

  final List<TextEditingController> controllers = [];

  late final String myName;

  int _participantsCount = 0;

  bool _buttonLock = false;
  bool _includeMeInReshare = false;

  Future<void> _onPressed() async {
    if (_buttonLock) {
      return;
    }
    _buttonLock = true;

    try {
      // TODO: optimize this by creating watcher providers (similar to normal WalletInfo)
      final frostInfo = ref
          .read(mainDBProvider)
          .isar
          .frostWalletInfo
          .getByWalletIdSync(widget.walletId)!;
      final validationMessage = _validateInputData();

      if (validationMessage != "valid") {
        return await showDialog<void>(
          context: context,
          builder: (_) => StackOkDialog(
            title: validationMessage,
            desktopPopRootNavigator: Util.isDesktop,
          ),
        );
      }

      final List<String> newParticipants =
          controllers.map((e) => e.text.trim()).toList();
      if (_includeMeInReshare) {
        newParticipants.insert(0, myName);
      }

      final config = Frost.createResharerConfig(
        newThreshold: int.parse(_newThresholdController.text),
        resharers: widget.resharers.values.toList(),
        newParticipants: newParticipants,
      );

      final salt = Format.uint8listToString(
        resharerSalt(resharerConfig: config),
      );

      if (frostInfo.knownSalts.contains(salt)) {
        return await showDialog<void>(
          context: context,
          builder: (_) => StackOkDialog(
            title: "Duplicate config salt",
            desktopPopRootNavigator: Util.isDesktop,
          ),
        );
      } else {
        final salts = frostInfo.knownSalts; // Fixed length list.
        final newSalts = List<String>.from(salts)..add(salt);
        final mainDB = ref.read(mainDBProvider);
        await mainDB.isar.writeTxn(() async {
          final info = frostInfo;
          await mainDB.isar.frostWalletInfo.delete(info.id);
          await mainDB.isar.frostWalletInfo.put(
            info.copyWith(knownSalts: newSalts),
          );
        });
      }

      ref.read(pFrostResharingData).myName = myName;
      ref.read(pFrostResharingData).resharerRConfig = Frost.encodeRConfig(
        config,
        widget.resharers,
      );

      final wallet =
          ref.read(pWallets).getWallet(widget.walletId) as BitcoinFrostWallet;

      if (mounted) {
        ref.read(pFrostScaffoldArgs.state).state = (
          info: (
            walletName: wallet.info.name,
            frostCurrency: wallet.cryptoCurrency,
          ),
          walletId: wallet.walletId,
          stepRoutes: FrostRouteGenerator.initiateReshareStepRoutes,
          parentNav: Navigator.of(context),
          frostInterruptionDialogType: FrostInterruptionDialogType.resharing,
          callerRouteName: CompleteReshareConfigView.routeName,
        );

        await Navigator.of(context).pushNamed(
          FrostStepScaffold.routeName,
        );
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
            title: e.toString(),
            desktopPopRootNavigator: Util.isDesktop,
          ),
        );
      }
    } finally {
      _buttonLock = false;
    }
  }

  String _validateInputData() {
    final threshold = int.tryParse(_newThresholdController.text);
    if (threshold == null) {
      return "Choose a threshold";
    }

    final partsCount = int.tryParse(_newParticipantsCountController.text);
    if (partsCount == null) {
      return "Choose total number of participants";
    }

    if (threshold > partsCount) {
      return "Threshold cannot be greater than the number of participants";
    }

    if (partsCount < 2) {
      return "At least two participants required";
    }

    final newParticipants = controllers.map((e) => e.text.trim()).toList();

    if (newParticipants.contains(myName)) {
      return "Using your own name should be done using the checkbox to include"
          " yourself";
    }

    if (_includeMeInReshare) {
      newParticipants.add(myName);
    }

    if (newParticipants.length != partsCount) {
      return "Participants count error";
    }

    final hasEmptyParticipants = newParticipants
        .map((e) => e.trim().isEmpty)
        .reduce((value, element) => value |= element);
    if (hasEmptyParticipants) {
      return "Participants must not be empty";
    }

    if (newParticipants.length != newParticipants.toSet().length) {
      return "Duplicate participant name found";
    }

    return "valid";
  }

  void _participantsCountChanged(String newValue) {
    int? count = int.tryParse(newValue);
    if (count != null) {
      if (_includeMeInReshare) {
        count = max(0, count - 1);
      }

      if (count > _participantsCount) {
        for (int i = _participantsCount; i < count; i++) {
          controllers.add(TextEditingController());
        }

        _participantsCount = count;
        setState(() {});
      } else if (count < _participantsCount) {
        for (int i = _participantsCount; i > count; i--) {
          final last = controllers.removeLast();
          last.dispose();
        }

        _participantsCount = count;
        setState(() {});
      }
    }
  }

  @override
  void initState() {
    final frostInfo = ref
        .read(mainDBProvider)
        .isar
        .frostWalletInfo
        .getByWalletIdSync(widget.walletId)!;
    myName = frostInfo.myName;
    super.initState();
  }

  @override
  void dispose() {
    _newThresholdController.dispose();
    _newParticipantsCountController.dispose();
    for (final e in controllers) {
      e.dispose();
    }
    super.dispose();
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
              title: Text(
                "Edit group details",
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: Util.isDesktop
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              height: 8,
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _includeMeInReshare = !_includeMeInReshare;
                });
                _participantsCountChanged(_newParticipantsCountController.text);
              },
              child: Container(
                color: Colors.transparent,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 26,
                      child: Checkbox(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        value: _includeMeInReshare,
                        onChanged: (value) {
                          setState(
                            () => _includeMeInReshare = value == true,
                          );
                          _participantsCountChanged(
                            _newParticipantsCountController.text,
                          );
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child: Text(
                        "I will be a signer in the new config",
                        style: STextStyles.w500_14(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              "New threshold",
              style: STextStyles.w500_14(context).copyWith(
                color:
                    Theme.of(context).extension<StackColors>()!.textSubtitle1,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              controller: _newThresholdController,
              decoration: InputDecoration(
                hintText: "Enter number of signatures",
                hintStyle: STextStyles.fieldLabel(context),
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            RoundedWhiteContainer(
              child: Text(
                "Enter number of signatures required for fund management.",
                style: STextStyles.w500_12(context).copyWith(
                  color:
                      Theme.of(context).extension<StackColors>()!.textSubtitle2,
                ),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              "New number of participants",
              style: STextStyles.w500_14(context).copyWith(
                color:
                    Theme.of(context).extension<StackColors>()!.textSubtitle1,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              controller: _newParticipantsCountController,
              onChanged: _participantsCountChanged,
              decoration: InputDecoration(
                hintText: "Enter number of participants",
                hintStyle: STextStyles.fieldLabel(context),
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            RoundedWhiteContainer(
              child: Text(
                "The number of participants must be equal to or less than the"
                " number of required signatures.",
                style: STextStyles.w500_12(context).copyWith(
                  color:
                      Theme.of(context).extension<StackColors>()!.textSubtitle2,
                ),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            if (controllers.isNotEmpty)
              Text(
                "Participants",
                style: STextStyles.w500_14(context).copyWith(
                  color:
                      Theme.of(context).extension<StackColors>()!.textSubtitle1,
                ),
              ),
            if (controllers.isNotEmpty)
              const SizedBox(
                height: 10,
              ),
            if (controllers.isNotEmpty)
              RoundedWhiteContainer(
                child: Text(
                  "Type each name in one word without spaces.",
                  style: STextStyles.w500_12(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textSubtitle2,
                  ),
                ),
              ),
            if (controllers.isNotEmpty)
              Column(
                children: [
                  for (int i = 0; i < controllers.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 10,
                      ),
                      child: TextField(
                        controller: controllers[i],
                        decoration: InputDecoration(
                          hintText: "Enter name",
                          hintStyle: STextStyles.fieldLabel(context),
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
              label: "Generate config",
              onPressed: () async {
                if (FocusScope.of(context).hasFocus) {
                  FocusScope.of(context).unfocus();
                }
                await _onPressed();
              },
            ),
          ],
        ),
      ),
    );
  }
}
