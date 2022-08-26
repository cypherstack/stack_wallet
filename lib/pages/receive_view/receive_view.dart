import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/receive_view/generate_receiving_uri_qr_code_view.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';

class ReceiveView extends StatelessWidget {
  const ReceiveView({
    Key? key,
    required this.coin,
    required this.receivingAddress,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  static const String routeName = "/receiveView";

  final Coin coin;
  final String receivingAddress;
  final ClipboardInterface clipboard;

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return Scaffold(
      backgroundColor: CFColors.almostWhite,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "Receive ${coin.ticker}",
          style: STextStyles.navBarTitle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: CFColors.white,
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              "Your ${coin.ticker} address",
                              style: STextStyles.itemSubtitle,
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
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
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    Assets.svg.copy,
                                    width: 10,
                                    height: 10,
                                    color: CFColors.link2,
                                  ),
                                  const SizedBox(
                                    width: 4,
                                  ),
                                  Text(
                                    "Copy",
                                    style: STextStyles.link2,
                                  ),
                                ],
                              ),
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
                                style: STextStyles.itemSubtitle12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                Center(
                  child: QrImage(
                    data: "${coin.uriScheme}:$receivingAddress",
                    size: MediaQuery.of(context).size.width / 2,
                    foregroundColor: CFColors.stackAccent,
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                // Spacer(
                //   flex: 7,
                // ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
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
                    );
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      CFColors.buttonGray,
                    ),
                  ),
                  child: Text(
                    "Generate QR Code",
                    style: STextStyles.button.copyWith(
                      color: CFColors.stackAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
