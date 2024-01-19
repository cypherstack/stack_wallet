import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frostdart/frostdart.dart';
import 'package:stackwallet/pages/settings_views/wallet_settings_view/frost_ms/resharing/involved/step_1a/display_reshare_config_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/services/frost.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/isar/models/frost_wallet_info.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

final class CompleteReshareConfigView extends ConsumerStatefulWidget {
  const CompleteReshareConfigView({
    super.key,
    required this.walletId,
    required this.resharers,
  });

  static const String routeName = "/completeReshareConfigView";

  final String walletId;
  final List<int> resharers;

  @override
  ConsumerState<CompleteReshareConfigView> createState() =>
      _CompleteReshareConfigViewState();
}

class _CompleteReshareConfigViewState
    extends ConsumerState<CompleteReshareConfigView> {
  final _newThresholdController = TextEditingController();
  final _newParticipantsCountController = TextEditingController();

  final List<TextEditingController> controllers = [];

  int _participantsCount = 0;

  bool _buttonLock = false;

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

      final config = Frost.createResharerConfig(
        newThreshold: int.parse(_newThresholdController.text),
        resharers: widget.resharers,
        newParticipants: controllers.map((e) => e.text).toList(),
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
        final salts = frostInfo.knownSalts;
        salts.add(salt);
        final mainDB = ref.read(mainDBProvider);
        await mainDB.isar.writeTxn(() async {
          final info = frostInfo;
          await mainDB.isar.frostWalletInfo.delete(info.id);
          await mainDB.isar.frostWalletInfo.put(
            info.copyWith(knownSalts: salts),
          );
        });
      }

      ref.read(pFrostResharingData).myName = frostInfo.myName;
      ref.read(pFrostResharingData).resharerConfig = config;

      if (mounted) {
        await Navigator.of(context).pushNamed(
          DisplayReshareConfigView.routeName,
          arguments: widget.walletId,
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

    if (controllers.length != partsCount) {
      return "Participants count error";
    }

    final hasEmptyParticipants = controllers
        .map((e) => e.text.isEmpty)
        .reduce((value, element) => value |= element);
    if (hasEmptyParticipants) {
      return "Participants must not be empty";
    }

    if (controllers.length != controllers.map((e) => e.text).toSet().length) {
      return "Duplicate participant name found";
    }

    return "valid";
  }

  void _participantsCountChanged(String newValue) {
    final count = int.tryParse(newValue);
    if (count != null) {
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
                "Modify Participants",
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "New threshold",
              style: STextStyles.label(context),
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              controller: _newThresholdController,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              "Number of participants",
              style: STextStyles.label(context),
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              controller: _newParticipantsCountController,
              onChanged: _participantsCountChanged,
            ),
            const SizedBox(
              height: 16,
            ),
            if (controllers.isNotEmpty)
              Text(
                "Participants",
                style: STextStyles.label(context),
              ),
            if (controllers.isNotEmpty)
              const SizedBox(
                height: 10,
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
