import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:namecoin/namecoin.dart';

import '../../../models/isar/models/isar_models.dart';
import '../../../providers/db/main_db_provider.dart';
import '../../../providers/global/secure_store_provider.dart';
import '../../../providers/global/wallets_provider.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/isar/providers/wallet_info_provider.dart';
import '../../../wallets/wallet/impl/namecoin_wallet.dart';
import '../../../widgets/background.dart';
import '../../../widgets/conditional_parent.dart';
import '../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../widgets/custom_buttons/blue_text_button.dart';
import '../../../widgets/custom_buttons/simple_copy_button.dart';
import '../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/dialogs/s_dialog.dart';
import '../../../widgets/rounded_container.dart';
import '../../wallet_view/transaction_views/transaction_details_view.dart'
    as tdv;
import '../manage_domain_view.dart';
import 'transfer_option_widget.dart';
import 'update_option_widget.dart';

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
      opNameData = OpNameData(
        nameData.cast(),
        utxo.blockHeight ?? currentHeight,
      );

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
              key: nameSaltKeyBuilder(utxo!.txid, widget.walletId, utxo!.vout),
            )
            .then((onValue) {
              if (onValue != null) {
                final data =
                    (jsonDecode(onValue) as Map).cast<String, String>();
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

  (String, Color) _getExpiry(int currentChainHeight, StackColors theme) {
    final String message;
    final Color color;

    if (utxo?.blockHash == null) {
      message = "Expires in $blocksNameExpiration+ blocks";
      color = theme.accentColorGreen;
    } else {
      final remaining = opNameData?.expiredBlockLeft(currentChainHeight, false);
      final semiRemaining = opNameData?.expiredBlockLeft(
        currentChainHeight,
        true,
      );

      if (remaining == null) {
        color = theme.accentColorRed;
        message = "Expired";
      } else {
        message = "Expires in $remaining blocks";
        if (semiRemaining == null) {
          color = theme.accentColorYellow;
        } else {
          color = theme.accentColorGreen;
        }
      }
    }

    return (message, color);
  }

  bool _checkConfirmedUtxo(int currentHeight) {
    return (ref.read(pWallets).getWallet(widget.walletId) as NamecoinWallet)
        .checkUtxoConfirmed(utxo!, currentHeight);
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
      label = ref
          .read(mainDBProvider)
          .getAddressLabelSync(widget.walletId, utxo!.address!);

      if (label != null) {
        streamLabel = ref.read(mainDBProvider).watchAddressLabel(id: label!.id);
      }
    }

    streamUTXO = ref.read(mainDBProvider).watchUTXO(id: widget.utxoId);
  }

  @override
  Widget build(BuildContext context) {
    final currentHeight = ref.watch(pWalletChainHeight(widget.walletId));

    final (message, color) = _getExpiry(
      currentHeight,
      Theme.of(context).extension<StackColors>()!,
    );

    final canManage =
        utxo != null &&
        _checkConfirmedUtxo(currentHeight) &&
        (opNameData?.op == OpName.nameUpdate ||
            opNameData?.op == OpName.nameFirstUpdate);

    return ConditionalParent(
      condition: !Util.isDesktop,
      builder:
          (child) => Background(
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
                actions:
                    canManage
                        ? [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 10,
                              bottom: 10,
                              right: 10,
                            ),
                            child: CustomTextButton(
                              key: const Key(
                                "addAddressBookEntryFavoriteButtonKey",
                              ),
                              text: "Manage",
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  ManageDomainView.routeName,
                                  arguments: (
                                    walletId: widget.walletId,
                                    utxo: utxo!,
                                  ),
                                );
                              },
                            ),
                          ),
                        ]
                        : null,
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
                          child: IntrinsicHeight(child: child),
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
                    borderColor:
                        Theme.of(
                          context,
                        ).extension<StackColors>()!.textFieldDefaultBG,
                    child: child,
                  ),
                ),
                if (canManage)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: "Transfer",
                            buttonHeight: ButtonHeight.l,
                            onPressed: () {
                              showDialog<void>(
                                context: context,
                                builder: (context) {
                                  return SDialog(
                                    child: SizedBox(
                                      width: 641,
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 32,
                                                ),
                                                child: Text(
                                                  "Transfer domain",
                                                  style: STextStyles.desktopH3(
                                                    context,
                                                  ),
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
                                              top: 16,
                                            ),
                                            child: TransferOptionWidget(
                                              walletId: widget.walletId,
                                              utxo: utxo!,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: SecondaryButton(
                            label: "Update",
                            buttonHeight: ButtonHeight.l,
                            onPressed: () {
                              showDialog<void>(
                                context: context,
                                builder: (context) {
                                  return SDialog(
                                    child: SizedBox(
                                      width: 641,
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 32,
                                                ),
                                                child: Text(
                                                  "Update domain",
                                                  style: STextStyles.desktopH3(
                                                    context,
                                                  ),
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
                                            ),
                                            child: UpdateOptionWidget(
                                              walletId: widget.walletId,
                                              utxo: utxo!,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                if (canManage) const SizedBox(height: 32),
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
                      color:
                          Theme.of(
                            context,
                          ).extension<StackColors>()!.accentColorRed,
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
                      color:
                          Util.isDesktop
                              ? Colors.transparent
                              : Theme.of(
                                context,
                              ).extension<StackColors>()!.popupBG,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(
                                constructedName ?? "",
                                style: STextStyles.pageTitleH2(context),
                              ),
                              if (Util.isDesktop)
                                SelectableText(
                                  opNameData!.op.name,
                                  style: STextStyles.w500_14(context),
                                ),
                            ],
                          ),
                          if (!Util.isDesktop)
                            SelectableText(
                              opNameData!.op.name,
                              style: STextStyles.w500_14(context),
                            ),
                        ],
                      ),
                    ),
                    const _Div(),
                    RoundedContainer(
                      padding:
                          Util.isDesktop
                              ? const EdgeInsets.all(16)
                              : const EdgeInsets.all(12),
                      color:
                          Util.isDesktop
                              ? Colors.transparent
                              : Theme.of(
                                context,
                              ).extension<StackColors>()!.popupBG,
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
                                  color:
                                      Theme.of(
                                        context,
                                      ).extension<StackColors>()!.textSubtitle1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            value ?? "",
                            style: STextStyles.w500_14(context),
                          ),
                        ],
                      ),
                    ),
                    const _Div(),
                    RoundedContainer(
                      padding:
                          Util.isDesktop
                              ? const EdgeInsets.all(16)
                              : const EdgeInsets.all(12),
                      color:
                          Util.isDesktop
                              ? Colors.transparent
                              : Theme.of(
                                context,
                              ).extension<StackColors>()!.popupBG,
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
                                  color:
                                      Theme.of(
                                        context,
                                      ).extension<StackColors>()!.textSubtitle1,
                                ),
                              ),
                              Util.isDesktop
                                  ? tdv.IconCopyButton(data: utxo!.address!)
                                  : SimpleCopyButton(data: utxo!.address!),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            utxo!.address!,
                            style: STextStyles.w500_14(context),
                          ),
                        ],
                      ),
                    ),
                    if (label != null && label!.value.isNotEmpty) const _Div(),
                    if (label != null && label!.value.isNotEmpty)
                      RoundedContainer(
                        padding:
                            Util.isDesktop
                                ? const EdgeInsets.all(16)
                                : const EdgeInsets.all(12),
                        color:
                            Util.isDesktop
                                ? Colors.transparent
                                : Theme.of(
                                  context,
                                ).extension<StackColors>()!.popupBG,
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
                                    color:
                                        Theme.of(context)
                                            .extension<StackColors>()!
                                            .textSubtitle1,
                                  ),
                                ),
                                Util.isDesktop
                                    ? tdv.IconCopyButton(data: label!.value)
                                    : SimpleCopyButton(data: label!.value),
                              ],
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              label!.value,
                              style: STextStyles.w500_14(context),
                            ),
                          ],
                        ),
                      ),
                    const _Div(),
                    RoundedContainer(
                      padding:
                          Util.isDesktop
                              ? const EdgeInsets.all(16)
                              : const EdgeInsets.all(12),
                      color:
                          Util.isDesktop
                              ? Colors.transparent
                              : Theme.of(
                                context,
                              ).extension<StackColors>()!.popupBG,
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
                                  color:
                                      Theme.of(
                                        context,
                                      ).extension<StackColors>()!.textSubtitle1,
                                ),
                              ),
                              Util.isDesktop
                                  ? tdv.IconCopyButton(data: utxo!.txid)
                                  : SimpleCopyButton(data: utxo!.txid),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            utxo!.txid,
                            style: STextStyles.w500_14(context),
                          ),
                        ],
                      ),
                    ),
                    const _Div(),
                    RoundedContainer(
                      padding:
                          Util.isDesktop
                              ? const EdgeInsets.all(16)
                              : const EdgeInsets.all(12),
                      color:
                          Util.isDesktop
                              ? Colors.transparent
                              : Theme.of(
                                context,
                              ).extension<StackColors>()!.popupBG,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Expiry",
                            style: STextStyles.w500_14(context).copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).extension<StackColors>()!.textSubtitle1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            message,
                            style: STextStyles.w500_14(
                              context,
                            ).copyWith(color: color),
                          ),
                        ],
                      ),
                    ),
                    const _Div(),
                    RoundedContainer(
                      padding:
                          Util.isDesktop
                              ? const EdgeInsets.all(16)
                              : const EdgeInsets.all(12),
                      color:
                          Util.isDesktop
                              ? Colors.transparent
                              : Theme.of(
                                context,
                              ).extension<StackColors>()!.popupBG,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Confirmations",
                            style: STextStyles.w500_14(context).copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).extension<StackColors>()!.textSubtitle1,
                            ),
                          ),
                          const SizedBox(height: 4),
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
      return const SizedBox(height: 12);
    }
  }
}
