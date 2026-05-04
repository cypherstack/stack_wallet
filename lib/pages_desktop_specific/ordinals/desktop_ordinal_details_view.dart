import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../app_config.dart';
import '../../models/isar/models/blockchain_data/utxo.dart';
import '../../models/isar/ordinal.dart';
import '../../networking/http.dart';
import '../../notifications/show_flush_bar.dart';
import '../../pages/ordinals/widgets/dialogs.dart';
import '../../pages/send_view/confirm_transaction_view.dart';
import '../../pages/wallet_view/transaction_views/transaction_details_view.dart';
import '../../providers/db/main_db_provider.dart';
import '../../providers/global/wallets_provider.dart';
import '../../services/tor_service.dart';
import '../desktop_home_view.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/amount/amount_formatter.dart';
import '../../utilities/assets.dart';
import '../../utilities/constants.dart';
import '../../utilities/prefs.dart';
import '../../utilities/show_loading.dart';
import '../../utilities/text_styles.dart';
import '../../wallets/wallet/wallet_mixin_interfaces/ordinals_interface.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_app_bar.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_scaffold.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/ordinal_image.dart';
import '../../widgets/rounded_white_container.dart';

class DesktopOrdinalDetailsView extends ConsumerStatefulWidget {
  const DesktopOrdinalDetailsView({
    super.key,
    required this.walletId,
    required this.ordinal,
  });

  final String walletId;
  final Ordinal ordinal;

  static const routeName = "/desktopOrdinalDetailsView";

  @override
  ConsumerState<DesktopOrdinalDetailsView> createState() =>
      _DesktopOrdinalDetailsViewState();
}

class _DesktopOrdinalDetailsViewState
    extends ConsumerState<DesktopOrdinalDetailsView> {
  static const _spacing = 12.0;

  late final UTXO? utxo;

  Future<String> _savePngToFile() async {
    final HTTP client = HTTP();

    final response = await client.get(
      url: Uri.parse(widget.ordinal.content),
      proxyInfo: !AppConfig.hasFeature(AppFeature.tor)
          ? null
          : Prefs.instance.useTor
          ? TorService.sharedInstance.getProxyInfo()
          : null,
    );

    if (response.code != 200) {
      throw Exception(
        "DesktopOrdinalDetailsView _savePngToFile statusCode=${response.code} body=${response.bodyBytes}",
      );
    }

    final bytes = response.bodyBytes;

    final dir = await getApplicationDocumentsDirectory();

    final filePath = path.join(
      dir.path,
      "ordinal_${widget.ordinal.inscriptionNumber}.png",
    );

    final File imgFile = File(filePath);

    if (imgFile.existsSync()) {
      throw Exception("File already exists");
    }

    await imgFile.writeAsBytes(bytes);
    return filePath;
  }

  @override
  void initState() {
    utxo = widget.ordinal.getUTXO(ref.read(mainDBProvider));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      appBar: DesktopAppBar(
        background: Theme.of(context).extension<StackColors>()!.popupBG,
        leading: Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 32),
              AppBarIconButton(
                size: 32,
                color: Theme.of(
                  context,
                ).extension<StackColors>()!.textFieldDefaultBG,
                shadows: const [],
                icon: SvgPicture.asset(
                  Assets.svg.arrowLeft,
                  width: 18,
                  height: 18,
                  color: Theme.of(
                    context,
                  ).extension<StackColors>()!.topNavIconPrimary,
                ),
                onPressed: Navigator.of(context).pop,
              ),
              const SizedBox(width: 18),
              Text("Ordinal details", style: STextStyles.desktopH3(context)),
            ],
          ),
        ),
        useSpacers: false,
        isCompactHeight: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 24, top: 24, right: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 300,
              height: 300,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
                child: OrdinalImage(url: widget.ordinal.content),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      RoundedWhiteContainer(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SelectableText(
                                    "INSC. ${widget.ordinal.inscriptionNumber}",
                                    style: STextStyles.w600_20(context),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            PrimaryButton(
                              width: 150,
                              label: "Send",
                              icon: SvgPicture.asset(
                                Assets.svg.send,
                                width: 18,
                                height: 18,
                                color: Theme.of(
                                  context,
                                ).extension<StackColors>()!.buttonTextPrimary,
                              ),
                              buttonHeight: ButtonHeight.l,
                              iconSpacing: 8,
                              onPressed: () async {
                                final utxo = widget.ordinal.getUTXO(
                                  ref.read(mainDBProvider),
                                );
                                if (utxo == null) {
                                  unawaited(
                                    showFloatingFlushBar(
                                      type: FlushBarType.warning,
                                      message: "Could not find ordinal UTXO",
                                      context: context,
                                    ),
                                  );
                                  return;
                                }

                                if (utxo.isBlocked) {
                                  final unfreezeResponse =
                                      await showDialog<String?>(
                                        context: context,
                                        builder: (_) =>
                                            const SendOrdinalUnfreezeDialog(),
                                      );
                                  if (unfreezeResponse != "unfreeze") return;
                                }

                                if (!context.mounted) return;

                                final address = await showDialog<String?>(
                                  context: context,
                                  builder: (_) => OrdinalRecipientAddressDialog(
                                    inscriptionNumber:
                                        widget.ordinal.inscriptionNumber,
                                  ),
                                );
                                if (address == null || address.isEmpty) return;

                                final wallet = ref
                                    .read(pWallets)
                                    .getWallet(widget.walletId);
                                if (!wallet.cryptoCurrency.validateAddress(
                                  address,
                                )) {
                                  if (context.mounted) {
                                    unawaited(
                                      showFloatingFlushBar(
                                        type: FlushBarType.warning,
                                        message: "Invalid address",
                                        context: context,
                                      ),
                                    );
                                  }
                                  return;
                                }

                                if (!context.mounted) return;

                                final OrdinalsInterface? ordinalsWallet =
                                    wallet is OrdinalsInterface ? wallet : null;
                                if (ordinalsWallet == null) {
                                  unawaited(
                                    showFloatingFlushBar(
                                      type: FlushBarType.warning,
                                      message:
                                          "Wallet does not support ordinals",
                                      context: context,
                                    ),
                                  );
                                  return;
                                }

                                bool didError = false;
                                final txData = await showLoading(
                                  whileFuture: ordinalsWallet
                                      .prepareOrdinalSend(
                                        ordinalUtxo: utxo,
                                        recipientAddress: address,
                                      ),
                                  context: context,
                                  rootNavigator: true,
                                  message: "Preparing transaction...",
                                  onException: (e) {
                                    didError = true;
                                    String msg = e.toString();
                                    while (msg.isNotEmpty &&
                                        msg.startsWith("Exception:")) {
                                      msg = msg.substring(10).trim();
                                    }
                                    if (context.mounted) {
                                      showFloatingFlushBar(
                                        type: FlushBarType.warning,
                                        message: msg,
                                        context: context,
                                      );
                                    }
                                  },
                                );

                                if (didError ||
                                    txData == null ||
                                    !context.mounted) {
                                  return;
                                }

                                await showDialog<void>(
                                  context: context,
                                  builder: (context) => DesktopDialog(
                                    maxHeight:
                                        MediaQuery.of(context).size.height - 64,
                                    maxWidth: 580,
                                    child: ConfirmTransactionView(
                                      walletId: widget.walletId,
                                      txData: txData,
                                      routeOnSuccessName:
                                          DesktopHomeView.routeName,
                                      onSuccess: () {},
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            SecondaryButton(
                              width: 150,
                              label: "Download",
                              icon: SvgPicture.asset(
                                Assets.svg.arrowDown,
                                width: 13,
                                height: 18,
                                color: Theme.of(
                                  context,
                                ).extension<StackColors>()!.buttonTextSecondary,
                              ),
                              buttonHeight: ButtonHeight.l,
                              iconSpacing: 8,
                              onPressed: () async {
                                bool didError = false;
                                final path = await showLoading<String>(
                                  whileFuture: _savePngToFile(),
                                  context: context,
                                  rootNavigator: true,
                                  message: "Saving ordinal image",
                                  onException: (e) {
                                    didError = true;
                                    String msg = e.toString();
                                    while (msg.isNotEmpty &&
                                        msg.startsWith("Exception:")) {
                                      msg = msg.substring(10).trim();
                                    }
                                    showFloatingFlushBar(
                                      type: FlushBarType.warning,
                                      message: msg,
                                      context: context,
                                    );
                                  },
                                );

                                if (!didError && mounted) {
                                  await showFloatingFlushBar(
                                    type: FlushBarType.success,
                                    message: "Image saved to $path",
                                    context: context,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      RoundedWhiteContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _DetailsItemWCopy(
                              title: "Inscription number",
                              data: widget.ordinal.inscriptionNumber.toString(),
                            ),
                            const _Divider(),
                            _DetailsItemWCopy(
                              title: "Inscription ID",
                              data: widget.ordinal.inscriptionId,
                            ),
                            // const SizedBox(
                            //   height: _spacing,
                            // ),
                            // // todo: add utxo status
                            const _Divider(),
                            Consumer(
                              builder: (context, ref, _) {
                                final coin = ref
                                    .watch(pWallets)
                                    .getWallet(widget.walletId)
                                    .info
                                    .coin;
                                return _DetailsItemWCopy(
                                  title: "Amount",
                                  data: utxo == null
                                      ? "ERROR"
                                      : ref
                                            .watch(pAmountFormatter(coin))
                                            .format(
                                              Amount(
                                                rawValue: BigInt.from(
                                                  utxo!.value,
                                                ),
                                                fractionDigits:
                                                    coin.fractionDigits,
                                              ),
                                            ),
                                );
                              },
                            ),
                            const _Divider(),
                            _DetailsItemWCopy(
                              title: "Owner address",
                              data: utxo?.address ?? "ERROR",
                            ),
                            const _Divider(),
                            _DetailsItemWCopy(
                              title: "Transaction ID",
                              data: widget.ordinal.utxoTXID,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        height: 1,
        color: Theme.of(context).extension<StackColors>()!.backgroundAppBar,
      ),
    );
  }
}

class _DetailsItemWCopy extends StatelessWidget {
  const _DetailsItemWCopy({super.key, required this.title, required this.data});

  final String title;
  final String data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: STextStyles.itemSubtitle(context)),
            IconCopyButton(data: data),
          ],
        ),
        const SizedBox(height: 4),
        SelectableText(data, style: STextStyles.itemSubtitle12(context)),
      ],
    );
  }
}
