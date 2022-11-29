import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/enums/sync_type_enum.dart';
import 'package:epicmobile/utilities/format.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/utilities/util.dart';
import 'package:epicmobile/widgets/animated_text.dart';
import 'package:epicmobile/widgets/conditional_parent.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/custom_buttons/draggable_switch_button.dart';
import 'package:epicmobile/widgets/rounded_white_container.dart';

class WalletSyncingOptionsView extends ConsumerWidget {
  const WalletSyncingOptionsView({Key? key}) : super(key: key);

  static const String routeName = "/walletSyncingOptions";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managers = ref
        .watch(walletsChangeNotifierProvider.select((value) => value.managers));

    final isDesktop = Util.isDesktop;
    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) {
        return Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
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
                style: STextStyles.navBarTitle(context),
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.only(
              left: 12,
              top: 12,
              right: 12,
            ),
            child: child,
          ),
        );
      },
      child: ConditionalParent(
        condition: isDesktop,
        builder: (child) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: child,
          );
        },
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
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
                        style: STextStyles.smallMed12(context),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      RoundedWhiteContainer(
                        padding: const EdgeInsets.all(0),
                        borderColor: !isDesktop
                            ? Colors.transparent
                            : Theme.of(context)
                                .extension<StackColors>()!
                                .background,
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
                                                style: STextStyles.itemSubtitle(
                                                    context),
                                              );
                                            } else {
                                              return AnimatedText(
                                                stringsToLoopThrough: const [
                                                  "Loading balance",
                                                  "Loading balance.",
                                                  "Loading balance..",
                                                  "Loading balance..."
                                                ],
                                                style: STextStyles.itemSubtitle(
                                                    context),
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
          );
        }),
      ),
    );
  }
}
