import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/monkey/sub_widgets/fetch_monkey_dialog.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/themes/coin_icon_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';

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

  @override
  void initState() {
    walletId = widget.walletId;
    managerProvider = widget.managerProvider;

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Coin coin = ref.watch(managerProvider.select((value) => value.coin));

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
            ),
            body: Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              // crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                Center(
                  child: Column(
                    children: [
                      SvgPicture.file(
                        File(
                          ref.watch(coinIconProvider(coin)),
                        ),
                        width: 164,
                        height: 164,
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
                const Spacer(),
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
