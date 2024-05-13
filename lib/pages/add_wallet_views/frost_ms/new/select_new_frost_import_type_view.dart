import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/frost_route_generator.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/frost_currency.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/dialogs/simple_mobile_dialog.dart';
import 'package:stackwallet/widgets/frost_scaffold.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class SelectNewFrostImportTypeView extends ConsumerStatefulWidget {
  const SelectNewFrostImportTypeView({
    super.key,
    required this.walletName,
    required this.frostCurrency,
  });

  static const String routeName = "/selectNewFrostImportTypeView";

  final String walletName;
  final FrostCurrency frostCurrency;

  @override
  ConsumerState<SelectNewFrostImportTypeView> createState() =>
      _SelectNewFrostImportTypeViewState();
}

class _SelectNewFrostImportTypeViewState
    extends ConsumerState<SelectNewFrostImportTypeView> {
  _ImportOption _selectedOption = _ImportOption.multisigNew;

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: Util.isDesktop,
      builder: (content) => DesktopScaffold(
        appBar: const DesktopAppBar(
          leading: AppBarBackButton(),
          trailing: ExitToMyStackButton(),
          isCompactHeight: false,
        ),
        body: SizedBox(
          width: 480,
          child: content,
        ),
      ),
      child: ConditionalParent(
        condition: !Util.isDesktop,
        builder: (content) => Background(
          child: Scaffold(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
            appBar: AppBar(
              leading: AppBarBackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              actions: [
                AspectRatio(
                  aspectRatio: 1,
                  child: AppBarIconButton(
                    size: 36,
                    icon: SvgPicture.asset(
                      Assets.svg.circleQuestion,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context)
                            .extension<StackColors>()!
                            .topNavIconPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                    onPressed: () async {
                      await showDialog<void>(
                        context: context,
                        builder: (_) => const _FrostJoinInfoDialog(),
                      );
                    },
                  ),
                ),
              ],
            ),
            body: Container(
              color: Theme.of(context).extension<StackColors>()!.background,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: content,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        child: Column(
          children: [
            ..._ImportOption.values.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ImportOptionCard(
                  onPressed: () => setState(() => _selectedOption = e),
                  title: e.info,
                  description: e.description,
                  value: e,
                  groupValue: _selectedOption,
                ),
              ),
            ),
            const Spacer(),
            PrimaryButton(
              label: "Continue",
              onPressed: () async {
                switch (_selectedOption) {
                  case _ImportOption.multisigNew:
                    ref.read(pFrostScaffoldArgs.state).state = (
                      info: (
                        walletName: widget.walletName,
                        frostCurrency: widget.frostCurrency,
                      ),
                      walletId: null, // no wallet id yet
                      stepRoutes: FrostRouteGenerator.importNewConfigStepRoutes,
                      parentNav: Navigator.of(context),
                      frostInterruptionDialogType:
                          FrostInterruptionDialogType.walletCreation,
                      callerRouteName: SelectNewFrostImportTypeView.routeName,
                    );
                    break;

                  case _ImportOption.resharerExisting:
                    ref.read(pFrostScaffoldArgs.state).state = (
                      info: (
                        walletName: widget.walletName,
                        frostCurrency: widget.frostCurrency,
                      ),
                      walletId: null, // no wallet id yet
                      stepRoutes: FrostRouteGenerator.joinReshareStepRoutes,
                      parentNav: Navigator.of(context),
                      frostInterruptionDialogType:
                          FrostInterruptionDialogType.resharing,
                      callerRouteName: SelectNewFrostImportTypeView.routeName,
                    );
                    break;
                }

                await Navigator.of(context).pushNamed(
                  FrostStepScaffold.routeName,
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

enum _ImportOption {
  multisigNew,
  resharerExisting;

  String get info {
    switch (this) {
      case _ImportOption.multisigNew:
        return "I want to join a new group";
      case _ImportOption.resharerExisting:
        return "I want to join an existing group";
    }
  }

  String get description {
    switch (this) {
      case _ImportOption.multisigNew:
        return "You are currently participating in the process of creating a new group";
      case _ImportOption.resharerExisting:
        return "You are joining an existing group through the process of resharing";
    }
  }
}

class _ImportOptionCard extends StatefulWidget {
  const _ImportOptionCard({
    super.key,
    required this.onPressed,
    required this.title,
    required this.description,
    required this.value,
    required this.groupValue,
  });

  final VoidCallback onPressed;
  final String title;
  final String description;
  final _ImportOption value;
  final _ImportOption groupValue;

  @override
  State<_ImportOptionCard> createState() => _ImportOptionCardState();
}

class _ImportOptionCardState extends State<_ImportOptionCard> {
  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(0),
      onPressed: widget.onPressed,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Radio(
              value: widget.value,
              groupValue: widget.groupValue,
              activeColor: Theme.of(context)
                  .extension<StackColors>()!
                  .radioButtonIconEnabled,
              onChanged: (_) => widget.onPressed(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 12.0,
                right: 12.0,
                bottom: 12.0,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: STextStyles.w600_16(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.description,
                          style: STextStyles.w500_14(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textSubtitle1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FrostJoinInfoDialog extends StatelessWidget {
  const _FrostJoinInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleMobileDialog(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Join a group",
            style: STextStyles.w600_20(context),
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            "You should select 'Join a new group' if you are creating a brand "
            "new wallet with other people.",
            style: STextStyles.w600_16(context),
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            "You should select 'Join an existing group' if you an existing "
            "group is being edited and you are being added as a participant.",
            style: STextStyles.w600_16(context),
          ),
        ],
      ),
    );
  }
}
