import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/syncing_preferences_views/wallet_syncing_options_view.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/enums/sync_type_enum.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/utilities/util.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/conditional_parent.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/desktop/desktop_dialog.dart';
import 'package:epicmobile/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:epicmobile/widgets/rounded_white_container.dart';

class SyncingOptionsView extends ConsumerWidget {
  const SyncingOptionsView({Key? key}) : super(key: key);

  static const String routeName = "/syncingOptions";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = Util.isDesktop;
    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) {
        return Background(
          child: Scaffold(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
            appBar: AppBar(
              leading: AppBarBackButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                },
              ),
              title: Text(
                "Syncing",
                style: STextStyles.navBarTitle(context),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: child,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      child: Column(
        children: [
          RoundedWhiteContainer(
            padding: const EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: RawMaterialButton(
                    // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Constants.size.circularBorderRadius,
                      ),
                    ),
                    onPressed: () {
                      final state =
                          ref.read(prefsChangeNotifierProvider).syncType;
                      if (state != SyncingType.currentWalletOnly) {
                        ref.read(prefsChangeNotifierProvider).syncType =
                            SyncingType.currentWalletOnly;

                        // disable auto sync on all wallets that aren't active/current
                        ref
                            .read(walletsChangeNotifierProvider)
                            .managers
                            .forEach((e) {
                          if (!e.isActiveWallet) {
                            e.shouldAutoSync = false;
                          }
                        });
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Radio(
                                activeColor: Theme.of(context)
                                    .extension<StackColors>()!
                                    .radioButtonIconEnabled,
                                value: SyncingType.currentWalletOnly,
                                groupValue: ref.watch(
                                  prefsChangeNotifierProvider
                                      .select((value) => value.syncType),
                                ),
                                onChanged: (value) {
                                  if (value is SyncingType) {
                                    ref
                                        .read(prefsChangeNotifierProvider)
                                        .syncType = value;
                                  }
                                },
                              ),
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Sync only currently open wallet",
                                    style: STextStyles.titleBold12(context),
                                    textAlign: TextAlign.left,
                                  ),
                                  Text(
                                    "Sync only the wallet that you are using",
                                    style: STextStyles.itemSubtitle(context),
                                    textAlign: TextAlign.left,
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
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: RawMaterialButton(
                    // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Constants.size.circularBorderRadius,
                      ),
                    ),
                    onPressed: () {
                      final state =
                          ref.read(prefsChangeNotifierProvider).syncType;
                      if (state != SyncingType.allWalletsOnStartup) {
                        ref.read(prefsChangeNotifierProvider).syncType =
                            SyncingType.allWalletsOnStartup;

                        // enable auto sync on all wallets
                        ref
                            .read(walletsChangeNotifierProvider)
                            .managers
                            .forEach((e) => e.shouldAutoSync = true);
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Radio(
                                activeColor: Theme.of(context)
                                    .extension<StackColors>()!
                                    .radioButtonIconEnabled,
                                value: SyncingType.allWalletsOnStartup,
                                groupValue: ref.watch(
                                  prefsChangeNotifierProvider
                                      .select((value) => value.syncType),
                                ),
                                onChanged: (value) {
                                  if (value is SyncingType) {
                                    ref
                                        .read(prefsChangeNotifierProvider)
                                        .syncType = value;
                                  }
                                },
                              ),
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Sync all wallets at startup",
                                    style: STextStyles.titleBold12(context),
                                    textAlign: TextAlign.left,
                                  ),
                                  Text(
                                    "All of your wallets will start syncing when you open the app",
                                    style: STextStyles.itemSubtitle(context),
                                    textAlign: TextAlign.left,
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
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: RawMaterialButton(
                    // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Constants.size.circularBorderRadius,
                      ),
                    ),
                    onPressed: () {
                      final state =
                          ref.read(prefsChangeNotifierProvider).syncType;
                      if (state != SyncingType.selectedWalletsAtStartup) {
                        ref.read(prefsChangeNotifierProvider).syncType =
                            SyncingType.selectedWalletsAtStartup;

                        final ids = ref
                            .read(prefsChangeNotifierProvider)
                            .walletIdsSyncOnStartup;

                        // enable auto sync on selected wallets only
                        ref
                            .read(walletsChangeNotifierProvider)
                            .managers
                            .forEach((e) =>
                                e.shouldAutoSync = ids.contains(e.walletId));
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Radio(
                                activeColor: Theme.of(context)
                                    .extension<StackColors>()!
                                    .radioButtonIconEnabled,
                                value: SyncingType.selectedWalletsAtStartup,
                                groupValue: ref.watch(
                                  prefsChangeNotifierProvider
                                      .select((value) => value.syncType),
                                ),
                                onChanged: (value) {
                                  if (value is SyncingType) {
                                    ref
                                        .read(prefsChangeNotifierProvider)
                                        .syncType = value;
                                  }
                                },
                              ),
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Sync only selected wallets at startup",
                                    style: STextStyles.titleBold12(context),
                                    textAlign: TextAlign.left,
                                  ),
                                  Text(
                                    "Only the wallets you select will start syncing when you open the app",
                                    style: STextStyles.itemSubtitle(context),
                                    textAlign: TextAlign.left,
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
                if (ref.watch(prefsChangeNotifierProvider
                        .select((value) => value.syncType)) !=
                    SyncingType.selectedWalletsAtStartup)
                  const SizedBox(
                    height: 12,
                  ),
                if (ref.watch(prefsChangeNotifierProvider
                        .select((value) => value.syncType)) ==
                    SyncingType.selectedWalletsAtStartup)
                  Container(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 12.0,
                        right: 12,
                        bottom: 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 12 + 20,
                            height: 12,
                          ),
                          Flexible(
                            child: RawMaterialButton(
                              // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Constants.size.circularBorderRadius,
                                ),
                              ),
                              onPressed: () {
                                !isDesktop
                                    ? Navigator.of(context).pushNamed(
                                        WalletSyncingOptionsView.routeName)
                                    : showDialog(
                                        context: context,
                                        useSafeArea: false,
                                        barrierDismissible: true,
                                        builder: (context) {
                                          return DesktopDialog(
                                            maxWidth: 600,
                                            maxHeight: 800,
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              32),
                                                      child: Text(
                                                        "Select wallets to sync",
                                                        style: STextStyles
                                                            .desktopH3(context),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                    const DesktopDialogCloseButton(),
                                                  ],
                                                ),
                                                const Expanded(
                                                  child:
                                                      WalletSyncingOptionsView(),
                                                ),
                                              ],
                                            ),
                                          );
                                        });
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Select wallets...",
                                    style: STextStyles.link2(context),
                                    textAlign: TextAlign.left,
                                  ),
                                ],
                              ),
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
    );
  }
}
