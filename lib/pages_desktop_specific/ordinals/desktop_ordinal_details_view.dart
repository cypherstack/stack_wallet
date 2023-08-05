import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/models/isar/ordinal.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/show_loading.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class DesktopOrdinalDetailsView extends ConsumerStatefulWidget {
  const DesktopOrdinalDetailsView({
    Key? key,
    required this.walletId,
    required this.ordinal,
  }) : super(key: key);

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
    final response = await get(Uri.parse(widget.ordinal.content));

    if (response.statusCode != 200) {
      throw Exception(
          "statusCode=${response.statusCode} body=${response.bodyBytes}");
    }

    final bytes = response.bodyBytes;

    if (Platform.isAndroid) {
      await Permission.storage.request();
    }

    final dir = Platform.isAndroid
        ? Directory("/storage/emulated/0/Documents")
        : await getApplicationDocumentsDirectory();

    final docPath = dir.path;
    final filePath = "$docPath/ordinal_${widget.ordinal.inscriptionNumber}.png";

    File imgFile = File(filePath);

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
    final coin = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(widget.walletId).coin));

    return DesktopScaffold(
      appBar: DesktopAppBar(
        background: Theme.of(context).extension<StackColors>()!.popupBG,
        leading: Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                width: 32,
              ),
              AppBarIconButton(
                size: 32,
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldDefaultBG,
                shadows: const [],
                icon: SvgPicture.asset(
                  Assets.svg.arrowLeft,
                  width: 18,
                  height: 18,
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .topNavIconPrimary,
                ),
                onPressed: Navigator.of(context).pop,
              ),
              const SizedBox(
                width: 18,
              ),
              Text(
                "Ordinal details",
                style: STextStyles.desktopH3(context),
              ),
            ],
          ),
        ),
        useSpacers: false,
        isCompactHeight: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 24,
          top: 24,
          right: 24,
        ),
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
                child: Image.network(
                  widget.ordinal
                      .content, // Use the preview URL as the image source
                  fit: BoxFit.cover,
                  filterQuality:
                      FilterQuality.none, // Set the filter mode to nearest
                ),
              ),
            ),
            const SizedBox(
              width: 16,
            ),
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
                            const SizedBox(
                              width: 16,
                            ),
                            // PrimaryButton(
                            //   width: 150,
                            //   label: "Send",
                            //   icon: SvgPicture.asset(
                            //     Assets.svg.send,
                            //     width: 18,
                            //     height: 18,
                            //     color: Theme.of(context)
                            //         .extension<StackColors>()!
                            //         .buttonTextPrimary,
                            //   ),
                            //   buttonHeight: ButtonHeight.l,
                            //   iconSpacing: 8,
                            //   onPressed: () async {
                            //     final response = await showDialog<String?>(
                            //       context: context,
                            //       builder: (_) =>
                            //           const SendOrdinalUnfreezeDialog(),
                            //     );
                            //     if (response == "unfreeze") {
                            //       // TODO: unfreeze and go to send ord screen
                            //     }
                            //   },
                            // ),
                            // const SizedBox(
                            //   width: 16,
                            // ),
                            SecondaryButton(
                              width: 150,
                              label: "Download",
                              icon: SvgPicture.asset(
                                Assets.svg.arrowDown,
                                width: 13,
                                height: 18,
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .buttonTextSecondary,
                              ),
                              buttonHeight: ButtonHeight.l,
                              iconSpacing: 8,
                              onPressed: () async {
                                bool didError = false;
                                final path = await showLoading<String>(
                                  whileFuture: _savePngToFile(),
                                  context: context,
                                  isDesktop: true,
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
                      const SizedBox(
                        height: 16,
                      ),
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
                            _DetailsItemWCopy(
                              title: "Amount",
                              data: utxo == null
                                  ? "ERROR"
                                  : ref.watch(pAmountFormatter(coin)).format(
                                        Amount(
                                          rawValue: BigInt.from(utxo!.value),
                                          fractionDigits: coin.decimals,
                                        ),
                                      ),
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
  const _Divider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
      ),
      child: Container(
        height: 1,
        color: Theme.of(context).extension<StackColors>()!.backgroundAppBar,
      ),
    );
  }
}

class _DetailsItemWCopy extends StatelessWidget {
  const _DetailsItemWCopy({
    Key? key,
    required this.title,
    required this.data,
  }) : super(key: key);

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
            Text(
              title,
              style: STextStyles.itemSubtitle(context),
            ),
            IconCopyButton(
              data: data,
            ),
          ],
        ),
        const SizedBox(
          height: 4,
        ),
        SelectableText(
          data,
          style: STextStyles.itemSubtitle12(context),
        ),
      ],
    );
  }
}
