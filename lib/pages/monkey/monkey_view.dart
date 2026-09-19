import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';

import '../../notifications/show_flush_bar.dart';
import '../../providers/global/wallets_provider.dart';
import '../../services/monkey_service.dart';
import '../../themes/coin_icon_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/fs.dart';
import '../../utilities/show_loading.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../wallets/isar/providers/wallet_info_provider.dart';
import '../../wallets/wallet/impl/banano_wallet.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_app_bar.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/desktop_scaffold.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/stack_dialog.dart';

class MonkeyView extends ConsumerStatefulWidget {
  const MonkeyView({super.key, required this.walletId});

  static const String routeName = "/monkey";
  static const double navBarHeight = 65.0;

  final String walletId;

  @override
  ConsumerState<MonkeyView> createState() => _MonkeyViewState();
}

class _MonkeyViewState extends ConsumerState<MonkeyView> {
  late final String walletId;
  List<int>? imageBytes;

  Future<void> _updateWalletMonKey(Uint8List monKeyBytes) async {
    await (ref.read(pWallets).getWallet(walletId) as BananoWallet)
        .updateMonkeyImageBytes(monKeyBytes.toList());
  }

  Future<String?> _getDocsDir() async {
    try {
      if (Platform.isAndroid) {
        return await FS.pickDirectory();
      }

      return (await getApplicationDocumentsDirectory()).path;
    } catch (_) {
      return null;
    }
  }

  String _monkeyPath = "";

  Future<void> _saveMonKeyToFile({
    required Uint8List bytes,
    bool isPNG = false,
    bool overwrite = false,
  }) async {
    final dirPath = await _getDocsDir();
    if (dirPath == null) {
      throw Exception("Failed to get directory path to save monKey image");
    }

    final address = await ref
        .read(pWallets)
        .getWallet(walletId)
        .getCurrentReceivingAddress();

    final fileName = "monkey_${address?.value}${isPNG ? ".png" : ".svg"}";
    final filePath = path.join(dirPath, fileName);

    if (Platform.isAndroid) {
      if (!overwrite && await SafUtil().exists(filePath, false)) {
        throw Exception("File already exists");
      }

      await SafStream().writeFileBytes(
        dirPath,
        fileName,
        isPNG ? "png" : "svg",
        bytes,
      );
    } else {
      final File imgFile = File(filePath);

      if (imgFile.existsSync() && !overwrite) {
        throw Exception("File already exists");
      }

      await imgFile.writeAsBytes(bytes);
    }

    _monkeyPath = filePath;
  }

  @override
  void initState() {
    walletId = widget.walletId;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(pWallets).getWallet(widget.walletId);
    final coin = ref.watch(pWalletCoin(widget.walletId));

    final bool isDesktop = Util.isDesktop;

    imageBytes ??= (wallet as BananoWallet).getMonkeyImageBytes();

    return Background(
      child: ConditionalParent(
        condition: isDesktop,
        builder: (child) => DesktopScaffold(
          appBar: DesktopAppBar(
            background: Theme.of(context).extension<StackColors>()!.popupBG,
            leading: Expanded(
              child: Row(
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
                  const SizedBox(width: 15),
                  SvgPicture.asset(
                    Assets.svg.monkey,
                    width: 32,
                    height: 32,
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.textSubtitle1,
                  ),
                  const SizedBox(width: 12),
                  Text("MonKey", style: STextStyles.desktopH3(context)),
                ],
              ),
            ),
            trailing: RawMaterialButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(1000),
              ),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  useSafeArea: false,
                  barrierDismissible: true,
                  builder: (context) {
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
                                  "About MonKeys",
                                  style: STextStyles.desktopH3(context),
                                ),
                              ),
                              const DesktopDialogCloseButton(),
                            ],
                          ),
                          Text(
                            "A MonKey is a visual representation of your Banano address.",
                            style: STextStyles.desktopTextMedium(context)
                                .copyWith(
                                  color: Theme.of(
                                    context,
                                  ).extension<StackColors>()!.textDark3,
                                ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(32),
                                child: PrimaryButton(
                                  width: 272.5,
                                  label: "OK",
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 19,
                  horizontal: 32,
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      Assets.svg.circleQuestion,
                      width: 20,
                      height: 20,
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.customTextButtonEnabledText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "What is MonKey?",
                      style: STextStyles.desktopMenuItemSelected(context)
                          .copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .customTextButtonEnabledText,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            useSpacers: false,
            isCompactHeight: true,
          ),
          body: child,
        ),
        child: ConditionalParent(
          condition: !isDesktop,
          builder: (child) => Scaffold(
            appBar: AppBar(
              leading: AppBarBackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Text("MonKey", style: STextStyles.navBarTitle(context)),
              actions: [
                AspectRatio(
                  aspectRatio: 1,
                  child: AppBarIconButton(
                    icon: SvgPicture.asset(Assets.svg.circleQuestion),
                    onPressed: () {
                      showDialog<dynamic>(
                        context: context,
                        useSafeArea: false,
                        barrierDismissible: true,
                        builder: (context) {
                          return const StackOkDialog(
                            title: "About MonKeys",
                            message:
                                "A MonKey is a visual representation of your Banano address.",
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            body: SafeArea(child: child),
          ),
          child: ConditionalParent(
            condition: isDesktop,
            builder: (child) => SizedBox(width: 318, child: child),
            child: ConditionalParent(
              condition: imageBytes != null,
              builder: (_) => Column(
                children: [
                  isDesktop
                      ? const SizedBox(height: 50)
                      : const Spacer(flex: 1),
                  if (imageBytes != null)
                    SizedBox(
                      width: 300,
                      height: 300,
                      child: SvgPicture.memory(Uint8List.fromList(imageBytes!)),
                    ),
                  isDesktop
                      ? const SizedBox(height: 50)
                      : const Spacer(flex: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        SecondaryButton(
                          label: "Save as SVG",
                          onPressed: () async {
                            bool didError = false;
                            await showLoading(
                              whileFuture: Future.wait([
                                _saveMonKeyToFile(
                                  bytes: Uint8List.fromList(
                                    (wallet as BananoWallet)
                                        .getMonkeyImageBytes()!,
                                  ),
                                ),
                                Future<void>.delayed(
                                  const Duration(seconds: 2),
                                ),
                              ]),
                              context: context,
                              rootNavigator: Util.isDesktop,
                              message: "Saving MonKey svg",
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
                                message:
                                    "SVG MonKey image saved to $_monkeyPath",
                                context: context,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        SecondaryButton(
                          label: "Download as PNG",
                          onPressed: () async {
                            bool didError = false;
                            await showLoading(
                              whileFuture: Future.wait([
                                wallet.getCurrentReceivingAddress().then(
                                  (address) async => await ref
                                      .read(pMonKeyService)
                                      .fetchMonKey(
                                        address: address!.value,
                                        png: true,
                                      )
                                      .then(
                                        (monKeyBytes) async =>
                                            await _saveMonKeyToFile(
                                              bytes: monKeyBytes,
                                              isPNG: true,
                                            ),
                                      ),
                                ),
                                Future<void>.delayed(
                                  const Duration(seconds: 2),
                                ),
                              ]),
                              context: context,
                              rootNavigator: Util.isDesktop,
                              message: "Downloading MonKey png",
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
                                message:
                                    "PNG MonKey image saved to $_monkeyPath",
                                context: context,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  // child,
                ],
              ),
              child: Column(
                children: [
                  isDesktop
                      ? const SizedBox(height: 100)
                      : const Spacer(flex: 4),
                  Center(
                    child: Column(
                      children: [
                        Opacity(
                          opacity: 0.2,
                          child: SvgPicture.file(
                            File(ref.watch(coinIconProvider(coin))),
                            width: 200,
                            height: 200,
                          ),
                        ),
                        const SizedBox(height: 70),
                        Text(
                          "You do not have a MonKey yet. \nFetch yours now!",
                          style: STextStyles.smallMed14(context).copyWith(
                            color: Theme.of(
                              context,
                            ).extension<StackColors>()!.textDark3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  isDesktop
                      ? const SizedBox(height: 50)
                      : const Spacer(flex: 6),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: PrimaryButton(
                      label: "Fetch MonKey",
                      onPressed: () async {
                        await showLoading(
                          whileFuture: Future.wait([
                            wallet.getCurrentReceivingAddress().then(
                              (address) async => await ref
                                  .read(pMonKeyService)
                                  .fetchMonKey(address: address!.value)
                                  .then(
                                    (monKeyBytes) async =>
                                        await _updateWalletMonKey(monKeyBytes),
                                  ),
                            ),
                            Future<void>.delayed(const Duration(seconds: 2)),
                          ]),
                          context: context,
                          rootNavigator: Util.isDesktop,
                          message: "Fetching MonKey",
                          subMessage: "We are fetching your MonKey",
                          onException: (e) {
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

                        imageBytes = (wallet as BananoWallet)
                            .getMonkeyImageBytes();

                        if (imageBytes != null) {
                          setState(() {});
                        }
                      },
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
