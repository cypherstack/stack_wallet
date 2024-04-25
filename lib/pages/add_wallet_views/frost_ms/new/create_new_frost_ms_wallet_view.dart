import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/new/share_new_multisig_config_view.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/services/frost.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/frost_currency.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/frost_mascot.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class CreateNewFrostMsWalletView extends ConsumerStatefulWidget {
  const CreateNewFrostMsWalletView({
    super.key,
    required this.walletName,
    required this.frostCurrency,
  });

  static const String routeName = "/createNewFrostMsWalletView";

  final String walletName;
  final FrostCurrency frostCurrency;

  @override
  ConsumerState<CreateNewFrostMsWalletView> createState() =>
      _NewFrostMsWalletViewState();
}

class _NewFrostMsWalletViewState
    extends ConsumerState<CreateNewFrostMsWalletView> {
  final _thresholdController = TextEditingController();
  final _participantsController = TextEditingController();

  final List<TextEditingController> controllers = [];

  int _participantsCount = 0;

  String _validateInputData() {
    final threshold = int.tryParse(_thresholdController.text);
    if (threshold == null) {
      return "Choose a threshold";
    }

    final partsCount = int.tryParse(_participantsController.text);
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
    _thresholdController.dispose();
    _participantsController.dispose();
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
          // TODO: [prio=high] get rid of placeholder text??
          trailing: FrostMascot(
            title: 'Lorem ipsum',
            body:
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam est justo, ',
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
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Text(
                "New FROST multisig config",
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
              "Threshold",
              style: STextStyles.label(context),
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              controller: _thresholdController,
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
              controller: _participantsController,
              onChanged: _participantsCountChanged,
            ),
            const SizedBox(
              height: 16,
            ),
            if (controllers.isNotEmpty)
              Text(
                "My name",
                style: STextStyles.label(context),
              ),
            if (controllers.isNotEmpty)
              const SizedBox(
                height: 10,
              ),
            if (controllers.isNotEmpty)
              TextField(
                controller: controllers.first,
              ),
            if (controllers.length > 1)
              const SizedBox(
                height: 16,
              ),
            if (controllers.length > 1)
              Text(
                "Remaining participants",
                style: STextStyles.label(context),
              ),
            if (controllers.length > 1)
              Column(
                children: [
                  for (int i = 1; i < controllers.length; i++)
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
              label: "Generate",
              onPressed: () async {
                if (FocusScope.of(context).hasFocus) {
                  FocusScope.of(context).unfocus();
                }

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

                final config = Frost.createMultisigConfig(
                  name: controllers.first.text,
                  threshold: int.parse(_thresholdController.text),
                  participants: controllers.map((e) => e.text).toList(),
                );

                ref.read(pFrostMyName.notifier).state = controllers.first.text;
                ref.read(pFrostMultisigConfig.notifier).state = config;

                await Navigator.of(context).pushNamed(
                  ShareNewMultisigConfigView.routeName,
                  arguments: (
                    walletName: widget.walletName,
                    frostCurrency: widget.frostCurrency,
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
