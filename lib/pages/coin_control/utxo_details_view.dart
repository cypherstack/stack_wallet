import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_edit_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/utxo_status_icon.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

class UtxoDetailsView extends ConsumerStatefulWidget {
  const UtxoDetailsView({
    Key? key,
    required this.utxoId,
    required this.walletId,
  }) : super(key: key);

  static const routeName = "/utxoDetails";

  final Id utxoId;
  final String walletId;

  @override
  ConsumerState<UtxoDetailsView> createState() => _UtxoDetailsViewState();
}

class _UtxoDetailsViewState extends ConsumerState<UtxoDetailsView> {
  final isDesktop = Util.isDesktop;

  late Stream<UTXO?> streamUTXO;
  UTXO? utxo;

  Stream<AddressLabel?>? streamLabel;
  AddressLabel? label;

  bool _popWithRefresh = false;

  Future<void> _toggleFreeze() async {
    _popWithRefresh = true;
    await MainDB.instance.putUTXO(utxo!.copyWith(isBlocked: !utxo!.isBlocked));
  }

  @override
  void initState() {
    utxo = MainDB.instance.isar.utxos
        .where()
        .idEqualTo(widget.utxoId)
        .findFirstSync()!;

    streamUTXO = MainDB.instance.watchUTXO(id: widget.utxoId);

    if (utxo?.address != null) {
      label = MainDB.instance.getAddressLabelSync(
        widget.walletId,
        utxo!.address!,
      );

      if (label != null) {
        streamLabel = MainDB.instance.watchAddressLabel(id: label!.id);
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final coin = ref.watch(
      walletsChangeNotifierProvider.select(
        (value) => value.getManager(widget.walletId).coin,
      ),
    );

    final currentHeight = ref.watch(
      walletsChangeNotifierProvider.select(
        (value) => value.getManager(widget.walletId).currentHeight,
      ),
    );

    final confirmed = utxo!.isConfirmed(
      currentHeight,
      coin.requiredConfirmations,
    );

    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) => Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
            leading: AppBarBackButton(
              onPressed: () {
                Navigator.of(context).pop(_popWithRefresh ? "refresh" : null);
              },
            ),
            title: Text(
              "Output details",
              style: STextStyles.navBarTitle(context),
            ),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
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
      child: StreamBuilder<UTXO?>(
        stream: streamUTXO,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            utxo = snapshot.data!;
          }
          return ConditionalParent(
            condition: isDesktop,
            builder: (child) {
              return DesktopDialog(
                maxHeight: double.infinity,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: Text(
                            "Output details",
                            style: STextStyles.desktopH3(context),
                          ),
                        ),
                        DesktopDialogCloseButton(
                          onPressedOverride: () {
                            Navigator.of(context)
                                .pop(_popWithRefresh ? "refresh" : null);
                          },
                        ),
                      ],
                    ),
                    IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 32,
                          right: 32,
                          bottom: 32,
                          top: 10,
                        ),
                        child: Column(
                          children: [
                            IntrinsicHeight(
                              child: RoundedContainer(
                                padding: EdgeInsets.zero,
                                color: Colors.transparent,
                                borderColor: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textFieldDefaultBG,
                                child: child,
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            SecondaryButton(
                              buttonHeight: ButtonHeight.l,
                              label: utxo!.isBlocked ? "Unfreeze" : "Freeze",
                              onPressed: _toggleFreeze,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isDesktop)
                  const SizedBox(
                    height: 10,
                  ),
                RoundedContainer(
                  padding: const EdgeInsets.all(12),
                  color: isDesktop
                      ? Colors.transparent
                      : Theme.of(context).extension<StackColors>()!.popupBG,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (isDesktop)
                            UTXOStatusIcon(
                              blocked: utxo!.isBlocked,
                              status: confirmed
                                  ? UTXOStatusIconStatus.confirmed
                                  : UTXOStatusIconStatus.unconfirmed,
                              background: Theme.of(context)
                                  .extension<StackColors>()!
                                  .popupBG,
                              selected: false,
                              width: 32,
                              height: 32,
                            ),
                          if (isDesktop)
                            const SizedBox(
                              width: 16,
                            ),
                          Text(
                            "${Format.satoshisToAmount(
                              utxo!.value,
                              coin: coin,
                            ).toStringAsFixed(
                              coin.decimals,
                            )} ${coin.ticker}",
                            style: STextStyles.pageTitleH2(context),
                          ),
                        ],
                      ),
                      Text(
                        utxo!.isBlocked
                            ? "Frozen"
                            : confirmed
                                ? "Available"
                                : "Unconfirmed",
                        style: STextStyles.w500_14(context).copyWith(
                          color: utxo!.isBlocked
                              ? const Color(0xFF7FA2D4) // todo theme
                              : confirmed
                                  ? Theme.of(context)
                                      .extension<StackColors>()!
                                      .accentColorGreen
                                  : Theme.of(context)
                                      .extension<StackColors>()!
                                      .accentColorYellow,
                        ),
                      ),
                    ],
                  ),
                ),
                const _Div(),
                RoundedContainer(
                  padding: isDesktop
                      ? const EdgeInsets.all(16)
                      : const EdgeInsets.all(12),
                  color: isDesktop
                      ? Colors.transparent
                      : Theme.of(context).extension<StackColors>()!.popupBG,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Label",
                            style: STextStyles.w500_14(context).copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textSubtitle1,
                            ),
                          ),
                          SimpleEditButton(
                            editValue: utxo!.name,
                            editLabel: "label",
                            onValueChanged: (newName) {
                              MainDB.instance.putUTXO(
                                utxo!.copyWith(
                                  name: newName,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        utxo!.name,
                        style: STextStyles.w500_14(context),
                      ),
                    ],
                  ),
                ),
                const _Div(),
                RoundedContainer(
                  padding: isDesktop
                      ? const EdgeInsets.all(16)
                      : const EdgeInsets.all(12),
                  color: isDesktop
                      ? Colors.transparent
                      : Theme.of(context).extension<StackColors>()!.popupBG,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Address",
                            style: STextStyles.w500_14(context).copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textSubtitle1,
                            ),
                          ),
                          isDesktop
                              ? IconCopyButton(
                                  data: utxo!.address!,
                                )
                              : SimpleCopyButton(
                                  data: utxo!.address!,
                                ),
                        ],
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        utxo!.address!,
                        style: STextStyles.w500_14(context),
                      ),
                    ],
                  ),
                ),
                if (label != null && label!.value.isNotEmpty) const _Div(),
                if (label != null && label!.value.isNotEmpty)
                  RoundedContainer(
                    padding: isDesktop
                        ? const EdgeInsets.all(16)
                        : const EdgeInsets.all(12),
                    color: isDesktop
                        ? Colors.transparent
                        : Theme.of(context).extension<StackColors>()!.popupBG,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Address label",
                              style: STextStyles.w500_14(context).copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textSubtitle1,
                              ),
                            ),
                            isDesktop
                                ? IconCopyButton(
                                    data: label!.value,
                                  )
                                : SimpleCopyButton(
                                    data: label!.value,
                                  ),
                          ],
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          label!.value,
                          style: STextStyles.w500_14(context),
                        ),
                      ],
                    ),
                  ),
                const _Div(),
                RoundedContainer(
                  padding: isDesktop
                      ? const EdgeInsets.all(16)
                      : const EdgeInsets.all(12),
                  color: isDesktop
                      ? Colors.transparent
                      : Theme.of(context).extension<StackColors>()!.popupBG,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Transaction ID",
                            style: STextStyles.w500_14(context).copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textSubtitle1,
                            ),
                          ),
                          isDesktop
                              ? IconCopyButton(
                                  data: utxo!.txid,
                                )
                              : SimpleCopyButton(
                                  data: utxo!.txid,
                                ),
                        ],
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        utxo!.txid,
                        style: STextStyles.w500_14(context),
                      ),
                    ],
                  ),
                ),
                const _Div(),
                RoundedContainer(
                  padding: isDesktop
                      ? const EdgeInsets.all(16)
                      : const EdgeInsets.all(12),
                  color: isDesktop
                      ? Colors.transparent
                      : Theme.of(context).extension<StackColors>()!.popupBG,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Confirmations",
                        style: STextStyles.w500_14(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textSubtitle1,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        "${utxo!.getConfirmations(currentHeight)}",
                        style: STextStyles.w500_14(context),
                      ),
                    ],
                  ),
                ),
                if (utxo!.isBlocked) const _Div(),
                if (utxo!.isBlocked)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RoundedContainer(
                        padding: isDesktop
                            ? const EdgeInsets.all(16)
                            : const EdgeInsets.all(12),
                        color: isDesktop
                            ? Colors.transparent
                            : Theme.of(context)
                                .extension<StackColors>()!
                                .popupBG,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Freeze reason",
                                  style: STextStyles.w500_14(context).copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textSubtitle1,
                                  ),
                                ),
                                SimpleEditButton(
                                  editValue: utxo!.blockedReason ?? "",
                                  editLabel: "freeze reason",
                                  onValueChanged: (newReason) {
                                    MainDB.instance.putUTXO(
                                      utxo!.copyWith(
                                        blockedReason: newReason,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              utxo!.blockedReason ?? "",
                              style: STextStyles.w500_14(context),
                            ),
                          ],
                        ),
                      ),
                      if (!isDesktop) const _Div(),
                    ],
                  ),
                if (!isDesktop) const Spacer(),
                if (!isDesktop)
                  SecondaryButton(
                    label: utxo!.isBlocked ? "Unfreeze" : "Freeze",
                    onPressed: _toggleFreeze,
                  ),
                if (!isDesktop)
                  const SizedBox(
                    height: 16,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Div extends StatelessWidget {
  const _Div({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Util.isDesktop) {
      return Container(
        width: double.infinity,
        height: 1.0,
        color: Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
      );
    } else {
      return const SizedBox(
        height: 12,
      );
    }
  }
}
