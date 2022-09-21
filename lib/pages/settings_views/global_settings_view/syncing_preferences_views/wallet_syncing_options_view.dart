import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/sync_type_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/animated_text.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/draggable_switch_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class WalletSyncingOptionsView extends ConsumerWidget {
  const WalletSyncingOptionsView({Key? key}) : super(key: key);

  static const String routeName = "/walletSyncingOptions";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managers = ref
        .watch(walletsChangeNotifierProvider.select((value) => value.managers));

    return Scaffold(
      backgroundColor: StackTheme.instance.color.background,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "Sync only selected wallets at startup",
            style: STextStyles.navBarTitle,
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
                        "Choose the wallets to sync automatically at startup",
                        style: STextStyles.smallMed12,
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
                                      "syncingPrefsSelectedWalletIdGroupKey_${manager.walletId}"),
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: CFColors.coin
                                            .forCoin(manager.coin)
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
                                          style: STextStyles.titleBold12,
                                        ),
                                        const SizedBox(
                                          height: 2,
                                        ),
                                        FutureBuilder(
                                          future: manager.totalBalance,
                                          builder: (builderContext,
                                              AsyncSnapshot<Decimal> snapshot) {
                                            if (snapshot.connectionState ==
                                                    ConnectionState.done &&
                                                snapshot.hasData) {
                                              return Text(
                                                "${Format.localizedStringAsFixed(
                                                  value: snapshot.data!,
                                                  locale: ref.watch(
                                                      localeServiceChangeNotifierProvider
                                                          .select((value) =>
                                                              value.locale)),
                                                  decimalPlaces: 8,
                                                )} ${manager.coin.ticker}",
                                                style: STextStyles.itemSubtitle,
                                              );
                                            } else {
                                              return AnimatedText(
                                                stringsToLoopThrough: const [
                                                  "Loading balance",
                                                  "Loading balance.",
                                                  "Loading balance..",
                                                  "Loading balance..."
                                                ],
                                                style: STextStyles.itemSubtitle,
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      height: 20,
                                      width: 40,
                                      child: DraggableSwitchButton(
                                        isOn: ref
                                            .watch(prefsChangeNotifierProvider
                                                .select((value) => value
                                                    .walletIdsSyncOnStartup))
                                            .contains(manager.walletId),
                                        onValueChanged: (value) {
                                          final syncType = ref
                                              .read(prefsChangeNotifierProvider)
                                              .syncType;
                                          final ids = ref
                                              .read(prefsChangeNotifierProvider)
                                              .walletIdsSyncOnStartup
                                              .toList();
                                          if (value) {
                                            ids.add(manager.walletId);
                                          } else {
                                            ids.remove(manager.walletId);
                                          }

                                          switch (syncType) {
                                            case SyncingType.currentWalletOnly:
                                              if (manager.isActiveWallet) {
                                                manager.shouldAutoSync = value;
                                              }
                                              break;
                                            case SyncingType
                                                .selectedWalletsAtStartup:
                                            case SyncingType
                                                .allWalletsOnStartup:
                                              manager.shouldAutoSync = value;
                                              break;
                                          }

                                          ref
                                              .read(prefsChangeNotifierProvider)
                                              .walletIdsSyncOnStartup = ids;
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
