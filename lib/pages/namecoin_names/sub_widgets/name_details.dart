import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:namecoin/namecoin.dart';

import '../../../models/isar/models/isar_models.dart';
import '../../../providers/db/main_db_provider.dart';
import '../../../providers/global/secure_store_provider.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/isar/providers/wallet_info_provider.dart';
import '../../../wallets/wallet/impl/namecoin_wallet.dart';
import '../../../widgets/background.dart';
import '../../../widgets/conditional_parent.dart';
import '../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../widgets/custom_buttons/simple_copy_button.dart';
import '../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../widgets/rounded_container.dart';
import '../../wallet_view/transaction_views/transaction_details_view.dart';

class NameDetailsView extends ConsumerStatefulWidget {
  const NameDetailsView({
    super.key,
    required this.utxoId,
    required this.walletId,
  });

  static const routeName = "/namecoinNameDetails";

  final Id utxoId;
  final String walletId;

  @override
  ConsumerState<NameDetailsView> createState() => _ManageDomainsWidgetState();
}

class _ManageDomainsWidgetState extends ConsumerState<NameDetailsView> {
  late Stream<UTXO?> streamUTXO;
  UTXO? utxo;
  OpNameData? opNameData;

  String? constructedName, value;

  Stream<AddressLabel?>? streamLabel;
  AddressLabel? label;

  void setUtxo(UTXO? utxo, int currentHeight) {
    if (utxo != null) {
      this.utxo = utxo;
      final data = jsonDecode(utxo.otherData!) as Map;

      final nameData = jsonDecode(data["nameOpData"] as String) as Map;
      opNameData =
          OpNameData(nameData.cast(), utxo.blockHeight ?? currentHeight);

      _setName();
    }
  }

  void _setName() {
    try {
      constructedName = opNameData!.constructedName;
      value = opNameData!.value;
    } catch (_) {
      if (opNameData?.op == OpName.nameNew) {
        ref
            .read(secureStoreProvider)
            .read(
              key: nameSaltKeyBuilder(
                utxo!.txid,
                widget.walletId,
                utxo!.vout,
              ),
            )
            .then((onValue) {
          if (onValue != null) {
            final data = (jsonDecode(onValue) as Map).cast<String, String>();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              constructedName = data["name"]!;
              value = data["value"]!;
              if (mounted) {
                setState(() {});
              }
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              constructedName = "UNKNOWN";
              value = "";
              if (mounted) {
                setState(() {});
              }
            });
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    setUtxo(
      ref
          .read(mainDBProvider)
          .isar
          .utxos
          .where()
          .idEqualTo(widget.utxoId)
          .findFirstSync(),
      ref.read(pWalletChainHeight(widget.walletId)),
    );

    _setName();

    if (utxo?.address != null) {
      label = ref.read(mainDBProvider).getAddressLabelSync(
            widget.walletId,
            utxo!.address!,
          );

      if (label != null) {
        streamLabel = ref.read(mainDBProvider).watchAddressLabel(id: label!.id);
      }
    }

    streamUTXO = ref.read(mainDBProvider).watchUTXO(id: widget.utxoId);
  }

  @override
  Widget build(BuildContext context) {
    final currentHeight = ref.watch(pWalletChainHeight(widget.walletId));

    final isExpired = opNameData?.expired(currentHeight) == true;
    final isSemiExpired = opNameData?.expired(currentHeight, true) == true;

    return ConditionalParent(
      condition: !Util.isDesktop,
      builder: (child) => Background(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            // Theme.of(context).extension<StackColors>()!.background,
            leading: const AppBarBackButton(),
            title: Text(
              "Domain details",
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
      child: ConditionalParent(
        condition: Util.isDesktop,
        builder: (child) {
          return SizedBox(
            width: 641,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Text(
                        "Domain details",
                        style: STextStyles.desktopH3(context),
                      ),
                    ),
                    const DesktopDialogCloseButton(),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 32,
                    right: 32,
                    bottom: 32,
                    top: 10,
                  ),
                  child: RoundedContainer(
                    padding: EdgeInsets.zero,
                    color: Colors.transparent,
                    borderColor: Theme.of(context)
                        .extension<StackColors>()!
                        .textFieldDefaultBG,
                    child: child,
                  ),
                ),
              ],
            ),
          );
        },
        child: StreamBuilder(
          stream: streamUTXO,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              setUtxo(snapshot.data!, currentHeight);
            }

            return utxo == null
                ? Center(
                    child: Text(
                      "Missing output. Was it used recently?",
                      style: STextStyles.w500_14(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorRed,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // if (!isDesktop)
                      //   const SizedBox(
                      //     height: 10,
                      //   ),
                      RoundedContainer(
                        padding: const EdgeInsets.all(12),
                        color: Util.isDesktop
                            ? Colors.transparent
                            : Theme.of(context)
                                .extension<StackColors>()!
                                .popupBG,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                // if (isDesktop)
                                //   UTXOStatusIcon(
                                //     blocked: utxo!.isBlocked,
                                //     status: confirmed
                                //         ? UTXOStatusIconStatus.confirmed
                                //         : UTXOStatusIconStatus.unconfirmed,
                                //     background: Theme.of(context)
                                //         .extension<StackColors>()!
                                //         .popupBG,
                                //     selected: false,
                                //     width: 32,
                                //     height: 32,
                                //   ),
                                // if (isDesktop)
                                //   const SizedBox(
                                //     width: 16,
                                //   ),

                                SelectableText(
                                  constructedName ?? "",
                                  style: STextStyles.pageTitleH2(context),
                                ),
                              ],
                            ),
                            SelectableText(
                              opNameData!.op.name,
                              style: STextStyles.w500_14(context),
                            ),
                          ],
                        ),
                      ),
                      const _Div(),
                      RoundedContainer(
                        padding: Util.isDesktop
                            ? const EdgeInsets.all(16)
                            : const EdgeInsets.all(12),
                        color: Util.isDesktop
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
                                  "Value",
                                  style: STextStyles.w500_14(context).copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textSubtitle1,
                                  ),
                                ),

                                // TODO: edit value
                                // SimpleEditButton(
                                //   editValue: utxo!.name,
                                //   editLabel: "label",
                                //   onValueChanged: (newName) {
                                //     MainDB.instance.putUTXO(
                                //       utxo!.copyWith(
                                //         name: newName,
                                //       ),
                                //     );
                                //   },
                                // ),
                              ],
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            SelectableText(
                              value ?? "",
                              style: STextStyles.w500_14(context),
                            ),
                          ],
                        ),
                      ),
                      const _Div(),
                      RoundedContainer(
                        padding: Util.isDesktop
                            ? const EdgeInsets.all(16)
                            : const EdgeInsets.all(12),
                        color: Util.isDesktop
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
                                  "Address",
                                  style: STextStyles.w500_14(context).copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textSubtitle1,
                                  ),
                                ),
                                Util.isDesktop
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
                            SelectableText(
                              utxo!.address!,
                              style: STextStyles.w500_14(context),
                            ),
                          ],
                        ),
                      ),
                      if (label != null && label!.value.isNotEmpty)
                        const _Div(),
                      if (label != null && label!.value.isNotEmpty)
                        RoundedContainer(
                          padding: Util.isDesktop
                              ? const EdgeInsets.all(16)
                              : const EdgeInsets.all(12),
                          color: Util.isDesktop
                              ? Colors.transparent
                              : Theme.of(context)
                                  .extension<StackColors>()!
                                  .popupBG,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Address label",
                                    style:
                                        STextStyles.w500_14(context).copyWith(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .textSubtitle1,
                                    ),
                                  ),
                                  Util.isDesktop
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
                              SelectableText(
                                label!.value,
                                style: STextStyles.w500_14(context),
                              ),
                            ],
                          ),
                        ),
                      const _Div(),
                      RoundedContainer(
                        padding: Util.isDesktop
                            ? const EdgeInsets.all(16)
                            : const EdgeInsets.all(12),
                        color: Util.isDesktop
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
                                  "Transaction ID",
                                  style: STextStyles.w500_14(context).copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textSubtitle1,
                                  ),
                                ),
                                Util.isDesktop
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
                            SelectableText(
                              utxo!.txid,
                              style: STextStyles.w500_14(context),
                            ),
                          ],
                        ),
                      ),
                      const _Div(),
                      RoundedContainer(
                        padding: Util.isDesktop
                            ? const EdgeInsets.all(16)
                            : const EdgeInsets.all(12),
                        color: Util.isDesktop
                            ? Colors.transparent
                            : Theme.of(context)
                                .extension<StackColors>()!
                                .popupBG,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Expiry",
                              style: STextStyles.w500_14(context).copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textSubtitle1,
                              ),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Row(
                              children: [
                                SelectableText(
                                  isExpired
                                      ? "Expired"
                                      : "${opNameData!.expiredBlockLeft(currentHeight)!}",
                                  style: STextStyles.w500_14(context).copyWith(
                                    color: isExpired
                                        ? Theme.of(context)
                                            .extension<StackColors>()!
                                            .accentColorRed
                                        : isSemiExpired
                                            ? Theme.of(context)
                                                .extension<StackColors>()!
                                                .accentColorYellow
                                            : Theme.of(context)
                                                .extension<StackColors>()!
                                                .accentColorGreen,
                                  ),
                                ),
                                if (!isExpired)
                                  Text(
                                    " blocks remaining",
                                    style:
                                        STextStyles.w500_14(context).copyWith(
                                      color: isExpired
                                          ? Theme.of(context)
                                              .extension<StackColors>()!
                                              .accentColorRed
                                          : isSemiExpired
                                              ? Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .accentColorYellow
                                              : Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .accentColorGreen,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const _Div(),
                      RoundedContainer(
                        padding: Util.isDesktop
                            ? const EdgeInsets.all(16)
                            : const EdgeInsets.all(12),
                        color: Util.isDesktop
                            ? Colors.transparent
                            : Theme.of(context)
                                .extension<StackColors>()!
                                .popupBG,
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
                            SelectableText(
                              "${utxo!.getConfirmations(currentHeight)}",
                              style: STextStyles.w500_14(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class _Div extends StatelessWidget {
  const _Div({super.key});

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
