import 'dart:async';

import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/clipboard_interface.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/custom_loading_overlay.dart';
import 'package:epicmobile/widgets/rounded_white_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ReceiveView extends ConsumerStatefulWidget {
  const ReceiveView({
    Key? key,
    required this.coin,
    required this.walletId,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  static const String routeName = "/receiveView";

  final Coin coin;
  final String walletId;
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

    await ref.read(walletProvider)!.generateNewAddress();

    shouldPop = true;

    if (mounted) {
      Navigator.of(context)
          .popUntil(ModalRoute.withName(ReceiveView.routeName));
    }
  }

  String receivingAddress = "";

  String assetName = Assets.svg.copy;
  void onCopy() {
    setState(() {
      assetName = Assets.svg.check;
    });
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          assetName = Assets.svg.copy;
        });
      }
    });
  }

  @override
  void initState() {
    walletId = widget.walletId;
    coin = widget.coin;
    clipboard = widget.clipboard;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final address = await ref.read(walletProvider)!.currentReceivingAddress;
      setState(() {
        receivingAddress = address;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    ref.listen(walletProvider.select((value) => value!.currentReceivingAddress),
        (previous, next) {
      if (next is Future<String>) {
        next.then((value) => setState(() => receivingAddress = value));
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text(
          "My Wallet",
          style: STextStyles.titleH3(context).copyWith(
              color: Theme.of(context)
                  .extension<StackColors>()!
                  .buttonBackPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: 8,
        ),
        Text(
          "Receive Epic to this address:",
          style: STextStyles.smallMed14(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: 30,
        ),
        Padding(
          padding: const EdgeInsets.all(0),
          child: Center(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: QrImage(
                      data: "${coin.uriScheme}:$receivingAddress",
                      size: MediaQuery.of(context).size.width / 2,
                      foregroundColor: Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorDark),
                ),
                const SizedBox(
                  height: 50,
                ),
                GestureDetector(
                  onTap: () {
                    clipboard.setData(
                      ClipboardData(text: receivingAddress),
                    );
                    onCopy();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: RoundedWhiteContainer(
                      child: Row(
                        // crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  receivingAddress,
                                  style: STextStyles.itemSubtitle12(context),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          SvgPicture.asset(
                            assetName,
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textMedium,
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
        const Spacer(
          flex: 2,
        ),
      ],
    );
  }
}
