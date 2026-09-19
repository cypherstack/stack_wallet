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
import '../../../../widgets/custom_buttons/blue_text_button.dart';
import '../../../../widgets/desktop/desktop_dialog.dart';
import '../../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../../widgets/epicbox_card.dart';
import 'add_edit_epicbox_view.dart';

class DesktopManageEpicBoxDialog extends ConsumerStatefulWidget {
  const DesktopManageEpicBoxDialog({super.key, required this.walletId});

  final String walletId;

  @override
  ConsumerState<DesktopManageEpicBoxDialog> createState() =>
      _DesktopManageEpicBoxDialogState();
}

class _DesktopManageEpicBoxDialogState
    extends ConsumerState<DesktopManageEpicBoxDialog> {
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
    showDialog<void>(
      context: context,
      builder: (_) => AddEditEpicBoxView(
        viewType: AddEditEpicBoxViewType.edit,
        epicBoxId: epicBoxId,
        onSave: () {},
      ),
    );
  }

  void _onAdd() {
    showDialog<void>(
      context: context,
      builder: (_) => AddEditEpicBoxView(
        viewType: AddEditEpicBoxViewType.add,
        onSave: () {},
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

    return DesktopDialog(
      maxHeight: double.infinity,
      maxWidth: 580,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Epic Box", style: STextStyles.desktopH3(context)),
                const DesktopDialogCloseButton(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 32, right: 32, top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Servers",
                  style: STextStyles.desktopTextExtraExtraSmall(context),
                ),
                CustomTextButton(text: "Add new", onTap: _onAdd),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 32, right: 32, bottom: 32),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          onEdit: () {}, // do nothing for defaults
                          testOnInit: primaryEpicBox?.id == epicBox.id,
                        ),
                      ),
                    ),
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
        ],
      ),
    );
  }
}
