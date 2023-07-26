import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stackwallet/pages/monkey/sub_widgets/fetch_monkey_dialog.dart';
import 'package:stackwallet/pages/wallet_view/wallet_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/desktop_wallet_view.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/coins/banano/banano_wallet.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/themes/coin_icon_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

import '../../widgets/desktop/desktop_app_bar.dart';
import '../../widgets/desktop/desktop_scaffold.dart';

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

  void getMonkeyImage(String address) async {
    if (address.isEmpty) {
      //address shouldn't be empty
      return;
    }

    final manager = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(walletId)));

    final http.Response response = await http
        .get(Uri.parse('https://monkey.banano.cc/api/v1/monkey/$address'));

    if (response.statusCode == 200) {
      final decodedResponse = response.bodyBytes;
      await (manager.wallet as BananoWallet)
          .updateMonkeyImageBytes(decodedResponse);
    } else {
      throw Exception("Failed to get MonKey");
    }
  }

  void getMonkeySVG(String address) async {
    if (address.isEmpty) {
      //address shouldn't be empty
      return;
    }

    final http.Response response = await http
        .get(Uri.parse('https://monkey.banano.cc/api/v1/monkey/$address'));

    if (response.statusCode == 200) {
      final decodedResponse = response.bodyBytes;
      Directory directory = await getApplicationDocumentsDirectory();
      late Directory sampleFolder;

      if (Platform.isAndroid) {
        directory = Directory("/storage/emulated/0/");
        sampleFolder = Directory('${directory!.path}Documents');
      } else if (Platform.isIOS) {
        sampleFolder = Directory(directory!.path);
      } else if (Platform.isLinux) {
        sampleFolder = Directory('${directory!.path}Documents');
      } else if (Platform.isWindows) {
        sampleFolder = Directory('${directory!.path}Documents');
      } else if (Platform.isMacOS) {
        sampleFolder = Directory('${directory!.path}Documents');
      }

      try {
        if (!sampleFolder.existsSync()) {
          sampleFolder.createSync(recursive: true);
        }
      } catch (e, s) {
        // todo: come back to this
        debugPrint("$e $s");
      }

      final docPath = sampleFolder.path;
      final filePath = "$docPath/monkey.svg";

      File imgFile = File(filePath);
      await imgFile.writeAsBytes(decodedResponse);
    } else {
      throw Exception("Failed to get MonKey");
    }
  }

  void getMonkeyPNG(String address) async {
    if (address.isEmpty) {
      //address shouldn't be empty
      return;
    }

    final http.Response response = await http.get(Uri.parse(
        'https://monkey.banano.cc/api/v1/monkey/${address}?format=png&size=512&background=false'));

    if (response.statusCode == 200) {
      if (Platform.isAndroid) {
        await Permission.storage.request();
      }

      final decodedResponse = response.bodyBytes;
      Directory directory = await getApplicationDocumentsDirectory();
      late Directory sampleFolder;

      if (Platform.isAndroid) {
        directory = Directory("/storage/emulated/0/");
        sampleFolder = Directory('${directory!.path}Documents');
      } else if (Platform.isIOS) {
        sampleFolder = Directory(directory!.path);
      } else if (Platform.isLinux) {
        sampleFolder = Directory('${directory!.path}Documents');
      } else if (Platform.isWindows) {
        sampleFolder = Directory('${directory!.path}Documents');
      } else if (Platform.isMacOS) {
        sampleFolder = Directory('${directory!.path}Documents');
      }

      try {
        if (!sampleFolder.existsSync()) {
          sampleFolder.createSync(recursive: true);
        }
      } catch (e, s) {
        // todo: come back to this
        debugPrint("$e $s");
      }

      final docPath = sampleFolder.path;
      final filePath = "$docPath/monkey.png";

      File imgFile = File(filePath);
      await imgFile.writeAsBytes(decodedResponse);
    } else {
      throw Exception("Failed to get MonKey");
    }
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
    final manager = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(widget.walletId)));

    final bool isDesktop = Util.isDesktop;

    List<int>? imageBytes;
    imageBytes = (manager.wallet as BananoWallet).getMonkeyImageBytes();

    //edit for desktop
    return Background(
      child: Stack(
        children: [
          ConditionalParent(
            condition: isDesktop,
            builder: (child) => DesktopScaffold(
              appBar: DesktopAppBar(
                background: Theme.of(context).extension<StackColors>()!.popupBG,
                leading: Expanded(
                  child: Row(
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
                        onPressed: () {
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                      Text(
                        "MonKey",
                        style: STextStyles.navBarTitle(context),
                      ),
                    ],
                  ),
                ),
                trailing: AspectRatio(
                  aspectRatio: 1,
                  child: AppBarIconButton(
                      icon: SvgPicture.asset(Assets.svg.circleQuestion),
                      onPressed: () {
                        showDialog<dynamic>(
                            context: context,
                            useSafeArea: false,
                            barrierDismissible: true,
                            builder: (context) {
                              return const StackDialog(
                                title: "About MonKeys",
                                message:
                                    "A MonKey is a visual representation of your Banano address.",
                              );
                            });
                      }),
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
                  title: Text(
                    "MonKey",
                    style: STextStyles.navBarTitle(context),
                  ),
                  actions: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: AppBarIconButton(
                          icon: SvgPicture.asset(
                            Assets.svg.circleQuestion,
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .infoItemText,
                          ),
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
                                });
                          }),
                    ),
                  ],
                ),
                body: child,
              ),
              child: ConditionalParent(
                condition: isDesktop,
                builder: (child) => SizedBox(
                  width: 300,
                  height: 300,
                  child: child,
                ),
                child: ConditionalParent(
                  condition: imageBytes != null,
                  builder: (child) => Column(
                    children: [
                      const Spacer(
                        flex: 1,
                      ),
                      if (imageBytes != null)
                        Container(
                          child: SvgPicture.memory(
                              Uint8List.fromList(imageBytes!)),
                          width: 300,
                          height: 300,
                        ),
                      const Spacer(
                        flex: 1,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            SecondaryButton(
                              label: "Download as SVG",
                              onPressed: () async {
                                getMonkeySVG(receivingAddress);
                              },
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
                      // child,
                    ],
                  ),
                  child: Column(
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
                          onPressed: () async {
                            getMonkeyImage(receivingAddress);

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

                            await Future<void>.delayed(
                                const Duration(seconds: 2));

                            if (isDesktop) {
                              Navigator.of(context).popUntil(
                                ModalRoute.withName(
                                    DesktopWalletView.routeName),
                              );
                            } else {
                              Navigator.of(context).popUntil(
                                ModalRoute.withName(WalletView.routeName),
                              );
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
        ],
      ),
    );
  }
}
