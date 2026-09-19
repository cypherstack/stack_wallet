import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../notifications/show_flush_bar.dart';
import '../../../../providers/providers.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/assets.dart';
import '../../../../utilities/default_epicboxes.dart';
import '../../../../utilities/test_epicbox_server_connection.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../wallets/wallet/impl/epiccash_wallet.dart';
import '../../../../widgets/background.dart';
import '../../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../../widgets/epicbox_card.dart';
import 'add_edit_epicbox_mobile_view.dart';

class ManageEpicboxView extends ConsumerStatefulWidget {
  const ManageEpicboxView({super.key, required this.walletId});

  static const routeName = "/manageEpicbox";

  final String walletId;

  @override
  ConsumerState<ManageEpicboxView> createState() => _ManageEpicboxViewState();
}

class _ManageEpicboxViewState extends ConsumerState<ManageEpicboxView> {
  Future<void> _onConnect(String epicBoxId) async {
    final epicBox =
        ref
            .read(nodeServiceChangeNotifierProvider)
            .getEpicBoxById(id: epicBoxId) ??
        DefaultEpicBoxes.all.firstWhere((e) => e.id == epicBoxId);

    final data = EpicBoxFormData()
      ..host = epicBox.host
      ..port = epicBox.port ?? 443
      ..useSSL = epicBox.useSSL;

    final canConnect = await testEpicBoxServerConnection(data) != null;

    if (!canConnect && mounted) {
      unawaited(
        showFloatingFlushBar(
          type: FlushBarType.warning,
          iconAsset: Assets.svg.circleAlert,
          message: "Could not connect to server",
          context: context,
        ),
      );
      return;
    }

    await ref
        .read(nodeServiceChangeNotifierProvider)
        .setPrimaryEpicBox(epicBox: epicBox, shouldNotifyListeners: true);

    // update wallet's epicbox config
    final wallet =
        ref.read(pWallets).getWallet(widget.walletId) as EpiccashWallet;
    await wallet.updateEpicboxConfig(epicBox.host, epicBox.port ?? 443);

    if (mounted) {
      unawaited(
        showFloatingFlushBar(
          type: FlushBarType.success,
          message: "Connected to ${epicBox.name}",
          context: context,
        ),
      );
    }
  }

  void _onEdit(String epicBoxId) {
    Navigator.of(context).pushNamed(
      AddEditEpicboxMobileView.routeName,
      arguments: (
        viewType: AddEditEpicboxMobileViewType.edit,
        epicBoxId: epicBoxId,
        routeOnSuccessOrDelete: ManageEpicboxView.routeName,
      ),
    );
  }

  void _onAdd() {
    Navigator.of(context).pushNamed(
      AddEditEpicboxMobileView.routeName,
      arguments: (
        viewType: AddEditEpicboxMobileViewType.add,
        epicBoxId: null,
        routeOnSuccessOrDelete: ManageEpicboxView.routeName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final epicBoxes = ref.watch(
      nodeServiceChangeNotifierProvider.select((value) => value.getEpicBoxes()),
    );
    final primaryEpicBox = ref.watch(
      nodeServiceChangeNotifierProvider.select(
        (value) => value.getPrimaryEpicBox(),
      ),
    );

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            "Epicbox Servers",
            style: STextStyles.navBarTitle(context),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: AspectRatio(
                aspectRatio: 1,
                child: AppBarIconButton(
                  icon: SizedBox(
                    width: 20,
                    height: 20,
                    child: Center(
                      child: Icon(
                        Icons.add,
                        color: Theme.of(
                          context,
                        ).extension<StackColors>()!.topNavIconPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  onPressed: _onAdd,
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      "Default servers",
                      style: STextStyles.smallMed12(context).copyWith(
                        color: Theme.of(
                          context,
                        ).extension<StackColors>()!.textDark3,
                      ),
                    ),
                  ),
                  ...DefaultEpicBoxes.all.map(
                    (epicBox) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: EpicBoxCard(
                        key: Key("${epicBox.id}_card_key"),
                        epicBoxId: epicBox.id,
                        onConnect: () => _onConnect(epicBox.id),
                        onEdit: () {},
                        testOnInit: primaryEpicBox?.id == epicBox.id,
                      ),
                    ),
                  ),
                ],
                if (epicBoxes.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      "Custom servers",
                      style: STextStyles.smallMed12(context).copyWith(
                        color: Theme.of(
                          context,
                        ).extension<StackColors>()!.textDark3,
                      ),
                    ),
                  ),
                  ...epicBoxes.map(
                    (epicBox) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: EpicBoxCard(
                        key: Key("${epicBox.id}_card_key"),
                        epicBoxId: epicBox.id,
                        onConnect: () => _onConnect(epicBox.id),
                        onEdit: () => _onEdit(epicBox.id),
                        testOnInit: primaryEpicBox?.id == epicBox.id,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
