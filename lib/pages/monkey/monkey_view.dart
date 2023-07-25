import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:stackwallet/pages/monkey/sub_widgets/fetch_monkey_dialog.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/themes/coin_icon_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';

class MonkeyView extends ConsumerStatefulWidget {
  const MonkeyView({
    Key? key,
    required this.walletId,
    required this.managerProvider,
  }) : super(key: key);

  static const String routeName = "/monkey";
  static const double navBarHeight = 65.0;

  final String walletId;
  final ChangeNotifierProvider<Manager> managerProvider;

  @override
  ConsumerState<MonkeyView> createState() => _MonkeyViewState();
}

class _MonkeyViewState extends ConsumerState<MonkeyView> {
  late final String walletId;
  late final ChangeNotifierProvider<Manager> managerProvider;

  String receivingAddress = "";

  void getMonkeySVG(String address) async {
    if (address.isEmpty) {
      //address shouldn't be empty
      return;
    }

    final http.Response response = await http
        .get(Uri.parse('https://monkey.banano.cc/api/v1/monkey/$address'));
    final decodedResponse = SvgPicture.memory(response.bodyBytes);
    // final decodedResponse = json.decode(response.body);
    // return decodedResponse;
    debugPrint("$decodedResponse");
  }

  void getMonkeyPNG(String address) async {
    if (address.isEmpty) {
      //address shouldn't be empty
      return;
    }

    final http.Response response = await http.get(Uri.parse(
        'https://monkey.banano.cc/api/v1/monkey/${address}?format=png&size=512&background=false'));

    if (response.statusCode == 200) {
      final decodedResponse = response.bodyBytes;
      final directory = await getApplicationDocumentsDirectory();
      // Directory appDir = await getTemporaryDirectory();
      final docPath = directory.path;
      final filePath = "$docPath/monkey.png";

      File imgFile = File(filePath);
      await imgFile.writeAsBytes(decodedResponse);
      print("$imgFile");

      // final directory = await getApplicationDocumentsDirectory();
      // final docPath = directory.path;
      // final filePath = "$do/monkey.png";
    } else {
      throw Exception("Failed to get MonKey");
    }

    // final decodedResponse = json.decode(response.body);
    // return decodedResponse;
    // debugPrint("$decodedResponse");
  }

  @override
  void initState() {
    walletId = widget.walletId;
    managerProvider = widget.managerProvider;

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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Coin coin = ref.watch(managerProvider.select((value) => value.coin));
    bool isMonkey = true;

    return Background(
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              leading: AppBarBackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Text(
                "MonKey",
                style: STextStyles.navBarTitle(context),
              ),
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
                              return Dialog(
                                child: Material(
                                  borderRadius: BorderRadius.circular(
                                    20,
                                  ),
                                  child: Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .popupBG,
                                      borderRadius: BorderRadius.circular(
                                        20,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Center(
                                          child: Text(
                                            "Help",
                                            style: STextStyles.pageTitleH2(
                                                context),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            });
                      }),
                )
              ],
            ),
            body: isMonkey
                ? Column(
                    children: [
                      Spacer(
                        flex: 1,
                      ),
                      Image.network(
                        'https://monkey.banano.cc/api/v1/monkey/$receivingAddress?format=png&size=512',
                      ),
                      Spacer(
                        flex: 1,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            SecondaryButton(
                              label: "Download as SVG",
                              onPressed: () async {},
                            ),
                            const SizedBox(height: 12),
                            SecondaryButton(
                              label: "Download as PNG",
                              onPressed: () {
                                getMonkeyPNG(receivingAddress);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const Spacer(
                        flex: 4,
                      ),
                      Center(
                        child: Column(
                          children: [
                            Opacity(
                              opacity: 0.2,
                              child: SvgPicture.file(
                                File(
                                  ref.watch(coinIconProvider(coin)),
                                ),
                                width: 200,
                                height: 200,
                              ),
                            ),
                            const SizedBox(
                              height: 40,
                            ),
                            Text(
                              "You do not have a MonKey yet. \nFetch yours now!",
                              style: STextStyles.smallMed14(context).copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textDark3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(
                        flex: 6,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: PrimaryButton(
                          label: "Fetch MonKey",
                          onPressed: () {
                            showDialog<dynamic>(
                              context: context,
                              useSafeArea: false,
                              barrierDismissible: false,
                              builder: (context) {
                                return FetchMonkeyDialog(
                                  onCancel: () async {
                                    Navigator.of(context).pop();
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
