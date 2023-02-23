import 'package:epicpay/pages/settings_views/epicbox_settings_view/manage_epicbox_views/add_edit_epicbox_view.dart';
import 'package:epicpay/pages/settings_views/epicbox_settings_view/sub_widgets/epicbox_list.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/widgets/background.dart';
import 'package:epicpay/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicpay/widgets/icon_widgets/plus_icon.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';

/// [eventBus] should only be set during testing
class EpicBoxSettingsView extends ConsumerStatefulWidget {
  const EpicBoxSettingsView({
    Key? key,
    this.eventBus,
  }) : super(key: key);

  final EventBus? eventBus;

  static const String routeName = "/walletEpicBoxSelect";

  @override
  ConsumerState<EpicBoxSettingsView> createState() =>
      _WalletEpicBoxSettingsViewState();
}

class _WalletEpicBoxSettingsViewState
    extends ConsumerState<EpicBoxSettingsView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          centerTitle: true,
          title: Text(
            "Epic Box Server",
            style: STextStyles.titleH4(context),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                splashRadius: 20,
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AddEditEpicBoxView.routeName,
                    arguments: Tuple3(
                      AddEditEpicBoxViewType.add,
                      null,
                      EpicBoxSettingsView.routeName,
                    ),
                  );
                },
                icon: const PlusIcon(
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 24,
              top: 24,
              bottom: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        EpicBoxList(
                          popBackToRoute: EpicBoxSettingsView.routeName,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
