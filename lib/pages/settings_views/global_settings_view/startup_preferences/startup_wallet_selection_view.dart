import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/draggable_switch_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class StartupWalletSelectionView extends ConsumerStatefulWidget {
  const StartupWalletSelectionView({Key? key}) : super(key: key);

  static const String routeName = "/startupWalletSelection";
  @override
  ConsumerState<StartupWalletSelectionView> createState() =>
      _StartupWalletSelectionViewState();
}

class _StartupWalletSelectionViewState
    extends ConsumerState<StartupWalletSelectionView> {
  final Map<String, DSBController> _controllers = {};

  @override
  Widget build(BuildContext context) {
    final managers = ref
        .watch(walletsChangeNotifierProvider.select((value) => value.managers));

    _controllers.clear();
    for (final manager in managers) {
      _controllers[manager.walletId] = DSBController();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).extension<StackColors>()!.background,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "Select startup wallet",
            style: STextStyles.navBarTitle(context),
          ),
        ),
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.only(
            left: 12,
            top: 12,
            right: 12,
          ),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 24,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        "Select a wallet to load into immediately on startup",
                        style: STextStyles.smallMed12(context),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      RoundedWhiteContainer(
                        padding: const EdgeInsets.all(0),
                        child: Column(
                          children: [
                            ...managers.map(
                              (manager) => Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  key: Key(
                                      "startupWalletSelectionGroupKey_${manager.walletId}"),
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .colorForCoin(manager.coin)
                                            .withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(
                                          Constants.size.circularBorderRadius,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: SvgPicture.asset(
                                          Assets.svg
                                              .iconFor(coin: manager.coin),
                                          width: 20,
                                          height: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          manager.walletName,
                                          style:
                                              STextStyles.titleBold12(context),
                                        ),
                                        // const SizedBox(
                                        //   height: 2,
                                        // ),
                                        // FutureBuilder(
                                        //   future: manager.totalBalance,
                                        //   builder: (builderContext,
                                        //       AsyncSnapshot<Decimal> snapshot) {
                                        //     if (snapshot.connectionState ==
                                        //             ConnectionState.done &&
                                        //         snapshot.hasData) {
                                        //       return Text(
                                        //         "${Format.localizedStringAsFixed(
                                        //           value: snapshot.data!,
                                        //           locale: ref.watch(
                                        //               localeServiceChangeNotifierProvider
                                        //                   .select((value) =>
                                        //                       value.locale)),
                                        //           decimalPlaces: 8,
                                        //         )} ${manager.coin.ticker}",
                                        //         style: STextStyles.itemSubtitle(context),
                                        //       );
                                        //     } else {
                                        //       return AnimatedText(
                                        //         stringsToLoopThrough: const [
                                        //           "Loading balance",
                                        //           "Loading balance.",
                                        //           "Loading balance..",
                                        //           "Loading balance..."
                                        //         ],
                                        //         style: STextStyles.itemSubtitle(context),
                                        //       );
                                        //     }
                                        //   },
                                        // ),
                                      ],
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: Radio(
                                        activeColor: Theme.of(context)
                                            .extension<StackColors>()!
                                            .radioButtonIconEnabled,
                                        value: manager.walletId,
                                        groupValue: ref.watch(
                                          prefsChangeNotifierProvider.select(
                                              (value) => value.startupWalletId),
                                        ),
                                        onChanged: (value) {
                                          if (value is String) {
                                            ref
                                                .read(
                                                    prefsChangeNotifierProvider)
                                                .startupWalletId = value;
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
