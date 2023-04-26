import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/receive_view/addresses/wallet_addresses_view.dart';
import 'package:stackwallet/pages/receive_view/generate_receiving_uri_qr_code_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/custom_loading_overlay.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class ReceiveView extends ConsumerStatefulWidget {
  const ReceiveView({
    Key? key,
    required this.walletId,
    this.tokenContract,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  static const String routeName = "/receiveView";

  final String walletId;
  final EthContract? tokenContract;
  final ClipboardInterface clipboard;

  @override
  ConsumerState<ReceiveView> createState() => _ReceiveViewState();
}

class _ReceiveViewState extends ConsumerState<ReceiveView> {
  late final Coin coin;
  late final String walletId;
  late final ClipboardInterface clipboard;

  Future<void> generateNewAddress() async {
    bool shouldPop = false;
    unawaited(
      showDialog(
        context: context,
        builder: (_) {
          return WillPopScope(
            onWillPop: () async => shouldPop,
            child: Container(
              color: Theme.of(context)
                  .extension<StackColors>()!
                  .overlay
                  .withOpacity(0.5),
              child: const CustomLoadingOverlay(
                message: "Generating address",
                eventBus: null,
              ),
            ),
          );
        },
      ),
    );

    await ref
        .read(walletsChangeNotifierProvider)
        .getManager(walletId)
        .generateNewAddress();

    shouldPop = true;

    if (mounted) {
      Navigator.of(context)
          .popUntil(ModalRoute.withName(ReceiveView.routeName));
    }
  }

  String receivingAddress = "";

  @override
  void initState() {
    walletId = widget.walletId;
    coin = ref.read(walletsChangeNotifierProvider).getManager(walletId).coin;
    clipboard = widget.clipboard;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final address = await ref
          .read(walletsChangeNotifierProvider)
          .getManager(walletId)
          .currentReceivingAddress;
      setState(() {
        receivingAddress = address;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    ref.listen(
        ref
            .read(walletsChangeNotifierProvider)
            .getManagerProvider(walletId)
            .select((value) => value.currentReceivingAddress),
        (previous, next) {
      if (next is Future<String>) {
        next.then((value) => setState(() => receivingAddress = value));
      }
    });

    final ticker = widget.tokenContract?.symbol ?? coin.ticker;

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
            "Receive $ticker",
            style: STextStyles.navBarTitle(context),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 10,
                right: 10,
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: AppBarIconButton(
                  key: const Key("walletNetworkSettingsAddNewNodeViewButton"),
                  size: 36,
                  shadows: const [],
                  color: Theme.of(context).extension<StackColors>()!.background,
                  icon: SvgPicture.asset(
                    Assets.svg.verticalEllipsis,
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .accentColorDark,
                    width: 20,
                    height: 20,
                  ),
                  onPressed: () {
                    showDialog<dynamic>(
                      barrierColor: Colors.transparent,
                      barrierDismissible: true,
                      context: context,
                      builder: (_) {
                        return Stack(
                          children: [
                            Positioned(
                              top: 9,
                              right: 10,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .popupBG,
                                  borderRadius: BorderRadius.circular(
                                    Constants.size.circularBorderRadius,
                                  ),
                                  // boxShadow: [CFColors.standardBoxShadow],
                                  boxShadow: const [],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        Navigator.of(context).pushNamed(
                                          WalletAddressesView.routeName,
                                          arguments: walletId,
                                        );
                                      },
                                      child: RoundedWhiteContainer(
                                        boxShadow: [
                                          Theme.of(context)
                                              .extension<StackColors>()!
                                              .standardBoxShadow,
                                        ],
                                        child: Material(
                                          color: Colors.transparent,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Text(
                                              "Address list",
                                              style: STextStyles.field(context),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      clipboard.setData(
                        ClipboardData(text: receivingAddress),
                      );
                      showFloatingFlushBar(
                        type: FlushBarType.info,
                        message: "Copied to clipboard",
                        iconAsset: Assets.svg.copy,
                        context: context,
                      );
                    },
                    child: RoundedWhiteContainer(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "Your $ticker address",
                                style: STextStyles.itemSubtitle(context),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    Assets.svg.copy,
                                    width: 10,
                                    height: 10,
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .infoItemIcons,
                                  ),
                                  const SizedBox(
                                    width: 4,
                                  ),
                                  Text(
                                    "Copy",
                                    style: STextStyles.link2(context),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  receivingAddress,
                                  style: STextStyles.itemSubtitle12(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (coin != Coin.epicCash && coin != Coin.ethereum)
                    const SizedBox(
                      height: 12,
                    ),
                  if (coin != Coin.epicCash && coin != Coin.ethereum)
                    TextButton(
                      onPressed: generateNewAddress,
                      style: Theme.of(context)
                          .extension<StackColors>()!
                          .getSecondaryEnabledButtonStyle(context),
                      child: Text(
                        "Generate new address",
                        style: STextStyles.button(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorDark),
                      ),
                    ),
                  const SizedBox(
                    height: 30,
                  ),
                  RoundedWhiteContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Column(
                          children: [
                            QrImage(
                                data: "${coin.uriScheme}:$receivingAddress",
                                size: MediaQuery.of(context).size.width / 2,
                                foregroundColor: Theme.of(context)
                                    .extension<StackColors>()!
                                    .accentColorDark),
                            const SizedBox(
                              height: 20,
                            ),
                            CustomTextButton(
                              text: "Create new QR code",
                              onTap: () async {
                                unawaited(Navigator.of(context).push(
                                  RouteGenerator.getRoute(
                                    shouldUseMaterialRoute:
                                        RouteGenerator.useMaterialPageRoute,
                                    builder: (_) => GenerateUriQrCodeView(
                                      coin: coin,
                                      receivingAddress: receivingAddress,
                                    ),
                                    settings: const RouteSettings(
                                      name: GenerateUriQrCodeView.routeName,
                                    ),
                                  ),
                                ));
                              },
                            ),
                          ],
                        ),
                      ),
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
