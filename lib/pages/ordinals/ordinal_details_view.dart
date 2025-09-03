import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../models/isar/models/blockchain_data/utxo.dart';
import '../../models/isar/ordinal.dart';
import '../../networking/http.dart';
import '../../notifications/show_flush_bar.dart';
import '../../providers/db/main_db_provider.dart';
import '../../providers/global/prefs_provider.dart';
import '../../services/tor_service.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/amount/amount_formatter.dart';
import '../../utilities/assets.dart';
import '../../utilities/constants.dart';
import '../../utilities/show_loading.dart';
import '../../utilities/stack_file_system.dart';
import '../../utilities/text_styles.dart';
import '../../wallets/isar/providers/wallet_info_provider.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/rounded_white_container.dart';

class OrdinalDetailsView extends ConsumerStatefulWidget {
  const OrdinalDetailsView({
    super.key,
    required this.walletId,
    required this.ordinal,
  });

  final String walletId;
  final Ordinal ordinal;

  static const routeName = "/ordinalDetailsView";

  @override
  ConsumerState<OrdinalDetailsView> createState() => _OrdinalDetailsViewState();
}

class _OrdinalDetailsViewState extends ConsumerState<OrdinalDetailsView> {
  static const _spacing = 12.0;

  late final UTXO? utxo;

  @override
  void initState() {
    utxo = widget.ordinal.getUTXO(ref.read(mainDBProvider));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final coin = ref.watch(pWalletCoin(widget.walletId));

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          leading: const AppBarBackButton(),
          title: Text(
            "Ordinal details",
            style: STextStyles.navBarTitle(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 39,
                    ),
                    child: _OrdinalImageGroup(
                      ordinal: widget.ordinal,
                      walletId: widget.walletId,
                    ),
                  ),
                  _DetailsItemWCopy(
                    title: "Inscription number",
                    data: widget.ordinal.inscriptionNumber.toString(),
                  ),
                  const SizedBox(height: _spacing),
                  _DetailsItemWCopy(
                    title: "Inscription ID",
                    data: widget.ordinal.inscriptionId,
                  ),
                  // const SizedBox(
                  //   height: _spacing,
                  // ),
                  // // todo: add utxo status
                  const SizedBox(height: _spacing),
                  _DetailsItemWCopy(
                    title: "Amount",
                    data:
                        utxo == null
                            ? "ERROR"
                            : ref
                                .watch(pAmountFormatter(coin))
                                .format(
                                  Amount(
                                    rawValue: BigInt.from(utxo!.value),
                                    fractionDigits: coin.fractionDigits,
                                  ),
                                ),
                  ),
                  const SizedBox(height: _spacing),
                  _DetailsItemWCopy(
                    title: "Owner address",
                    data: utxo?.address ?? "ERROR",
                  ),
                  const SizedBox(height: _spacing),
                  _DetailsItemWCopy(
                    title: "Transaction ID",
                    data: widget.ordinal.utxoTXID,
                  ),
                  const SizedBox(height: _spacing),
                ],
              ),
            ),
          ),
        ),
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
    return RoundedWhiteContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: STextStyles.itemSubtitle(context)),
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: data));
                  if (context.mounted) {
                    unawaited(
                      showFloatingFlushBar(
                        type: FlushBarType.info,
                        message: "Copied to clipboard",
                        context: context,
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    SvgPicture.asset(
                      Assets.svg.copy,
                      color:
                          Theme.of(
                            context,
                          ).extension<StackColors>()!.infoItemIcons,
                      width: 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Copy",
                      style: STextStyles.infoSmall(context).copyWith(
                        color:
                            Theme.of(
                              context,
                            ).extension<StackColors>()!.infoItemIcons,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(data, style: STextStyles.itemSubtitle12(context)),
        ],
      ),
    );
  }
}

class _OrdinalImageGroup extends ConsumerWidget {
  const _OrdinalImageGroup({
    super.key,
    required this.walletId,
    required this.ordinal,
  });

  final String walletId;
  final Ordinal ordinal;

  static const _spacing = 12.0;

  Future<String> _savePngToFile(WidgetRef ref) async {
    final HTTP client = HTTP();

    final response = await client.get(
      url: Uri.parse(ordinal.content),
      proxyInfo:
          ref.read(prefsChangeNotifierProvider).useTor
              ? ref.read(pTorService).getProxyInfo()
              : null,
    );

    if (response.code != 200) {
      throw Exception(
        "OrdinalDetailsView _savePngToFile statusCode=${response.code} body=${response.bodyBytes}",
      );
    }

    final bytes = response.bodyBytes;

    final dir =
        Platform.isAndroid
            ? await StackFileSystem.wtfAndroidDocumentsPath()
            : await getApplicationDocumentsDirectory();
    final filePath = path.join(
      dir.path,
      "ordinal_${ordinal.inscriptionNumber}.png",
    );

    final File imgFile = File(filePath);

    if (imgFile.existsSync()) {
      throw Exception("File already exists");
    }

    await imgFile.writeAsBytes(bytes);
    return filePath;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Text(
        //   "${ordinal.inscriptionId}", // Use any other property you want
        //   style: STextStyles.w600_16(context),
        // ),
        // const SizedBox(
        //   height: _spacing,
        // ),
        ClipRRect(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              color: Colors.transparent,
              child: Image.network(
                ordinal.content, // Use the preview URL as the image source
                fit: BoxFit.cover,
                filterQuality:
                    FilterQuality.none, // Set the filter mode to nearest
              ),
            ),
          ),
        ),
        const SizedBox(height: _spacing),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: "Download",
                icon: SvgPicture.asset(
                  Assets.svg.arrowDown,
                  width: 10,
                  height: 12,
                  color:
                      Theme.of(
                        context,
                      ).extension<StackColors>()!.buttonTextSecondary,
                ),
                buttonHeight: ButtonHeight.l,
                iconSpacing: 4,
                onPressed: () async {
                  bool didError = false;
                  final filePath = await showLoading<String>(
                    whileFuture: _savePngToFile(ref),
                    context: context,
                    rootNavigator: true,
                    message: "Saving ordinal image",
                    onException: (e) {
                      didError = true;
                      String msg = e.toString();
                      while (msg.isNotEmpty && msg.startsWith("Exception:")) {
                        msg = msg.substring(10).trim();
                      }
                      showFloatingFlushBar(
                        type: FlushBarType.warning,
                        message: msg,
                        context: context,
                      );
                    },
                  );

                  if (!didError && context.mounted) {
                    await showFloatingFlushBar(
                      type: FlushBarType.success,
                      message: "Image saved to $filePath",
                      context: context,
                    );
                  }
                },
              ),
            ),
            // const SizedBox(
            //   width: _spacing,
            // ),
            // Expanded(
            //   child: PrimaryButton(
            //     label: "Send",
            //     icon: SvgPicture.asset(
            //       Assets.svg.send,
            //       width: 10,
            //       height: 10,
            //       color: Theme.of(context)
            //           .extension<StackColors>()!
            //           .buttonTextPrimary,
            //     ),
            //     buttonHeight: ButtonHeight.l,
            //     iconSpacing: 4,
            //     onPressed: () async {
            //       final response = await showDialog<String?>(
            //         context: context,
            //         builder: (_) => const SendOrdinalUnfreezeDialog(),
            //       );
            //       if (response == "unfreeze") {
            //         // TODO: unfreeze and go to send ord screen
            //       }
            //     },
            //   ),
            // ),
          ],
        ),
      ],
    );
  }
}
