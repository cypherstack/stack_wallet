import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/dialogs/cancel_stack_restore_dialog.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/helpers/restore_create_backup.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/restore_from_encrypted_string_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/stack_backup_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/sub_widgets/restoring_item_card.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/sub_widgets/restoring_wallet_card.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_home_view.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_menu.dart';
import 'package:stackwallet/providers/desktop/current_desktop_menu_item.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/providers/stack_restore/stack_restoring_ui_state_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/stack_restoring_status.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/addressbook_icon.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

class StackRestoreProgressView extends ConsumerStatefulWidget {
  const StackRestoreProgressView({
    Key? key,
    required this.jsonString,
    this.fromFile = false,
    this.shouldPushToHome = false,
  }) : super(key: key);

  final String jsonString;
  final bool fromFile;
  final bool shouldPushToHome;

  @override
  ConsumerState<StackRestoreProgressView> createState() =>
      _StackRestoreProgressViewState();
}

class _StackRestoreProgressViewState
    extends ConsumerState<StackRestoreProgressView> {
  bool isDesktop = Util.isDesktop;

  Future<void> _cancel() async {
    bool shouldPop = false;
    unawaited(showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (_) => WillPopScope(
        onWillPop: () async {
          return shouldPop;
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Material(
              color: Colors.transparent,
              child: Center(
                child: Text(
                  "Cancelling restore. Please wait.",
                  style: STextStyles.pageTitleH2(context).copyWith(
                    color:
                        Theme.of(context).extension<StackColors>()!.textWhite,
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 64,
            ),
            const Center(
              child: LoadingIndicator(
                width: 100,
              ),
            ),
          ],
        ),
      ),
    ));

    await SWB.cancelRestore();
    shouldPop = true;

    int count = 0;

    if (mounted) {
      !isDesktop
          ? Navigator.of(context).popUntil(ModalRoute.withName(widget.fromFile
              ? RestoreFromEncryptedStringView.routeName
              : StackBackupView.routeName))
          : Navigator.of(context).popUntil((_) => count++ >= 2);
    }
  }

  Future<bool> _requestCancel() async {
    final result = await showDialog<dynamic>(
      barrierDismissible: false,
      context: context,
      builder: (_) => const CancelStackRestoreDialog(),
    );
    // : await Row(
    //     children: [
    //       SecondaryButton(
    //         width: 248,
    //          buttonHeight: ButtonHeight.l,
    //         enabled: true,
    //         label: "Keep restoring",
    //         onPressed: () {
    //           false;
    //         },
    //       ),
    //       const SizedBox(width: 16),
    //       PrimaryButton(
    //         width: 248,
    //          buttonHeight: ButtonHeight.l,
    //         enabled: true,
    //         label: "Cancel anyway",
    //         onPressed: () {
    //           true;
    //         },
    //       )
    //     ],
    //   );

    if (result is bool && result) {
      return true;
    }
    return false;
  }

  Future<void> _restore() async {
    ref.refresh(stackRestoringUIStateProvider);
    final uiState = ref.read(stackRestoringUIStateProvider);

    bool? finished;
    try {
      finished = await SWB.restoreStackWalletJSON(
        widget.jsonString,
        uiState,
        ref.read(secureStoreProvider),
      );
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Warning);
    }

    if (finished != null && finished && uiState.done) {
      setState(() {
        _success = true;
      });
    }
  }

  bool _success = false;
  bool pendingCancel = false;

  Future<bool> _onWillPop() async {
    if (_success) {
      _addWalletsToHomeView();
      return true;
    }

    final shouldCancel = await _requestCancel();
    if (shouldCancel) {
      await _cancel();
      return true;
    } else {
      return false;
    }
  }

  Widget _getIconForState(StackRestoringStatus state) {
    switch (state) {
      case StackRestoringStatus.waiting:
        return SvgPicture.asset(
          Assets.svg.loader,
          color:
              Theme.of(context).extension<StackColors>()!.buttonBackSecondary,
        );
      case StackRestoringStatus.restoring:
        return SvgPicture.asset(
          Assets.svg.loader,
          color: Theme.of(context).extension<StackColors>()!.accentColorGreen,
        );
      case StackRestoringStatus.success:
        return SvgPicture.asset(
          Assets.svg.checkCircle,
          color: Theme.of(context).extension<StackColors>()!.accentColorGreen,
        );
      case StackRestoringStatus.failed:
        return SvgPicture.asset(
          Assets.svg.circleAlert,
          color: Theme.of(context).extension<StackColors>()!.textError,
        );
    }
  }

  void _addWalletsToHomeView() {
    ref.read(walletsChangeNotifierProvider).loadAfterStackRestore(
          ref.read(prefsChangeNotifierProvider),
          ref.read(stackRestoringUIStateProvider).managers,
        );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _restore();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = Util.isDesktop;

    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) {
        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
            appBar: AppBar(
              leading: AppBarBackButton(
                onPressed: () async {
                  if (FocusScope.of(context).hasFocus) {
                    FocusScope.of(context).unfocus();
                    await Future<void>.delayed(
                        const Duration(milliseconds: 75));
                  }
                  if (_success) {
                    _addWalletsToHomeView();
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  } else {
                    if (await _requestCancel()) {
                      await _cancel();
                    }
                  }
                },
              ),
              title: Text(
                "Restoring Stack wallet",
                style: STextStyles.navBarTitle(context),
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
          ),
        );
      },
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 4,
            top: 4,
            right: 4,
            bottom: 4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Settings",
                style: STextStyles.itemSubtitle(context),
              ),
              const SizedBox(
                height: 12,
              ),
              Consumer(
                builder: (_, ref, __) {
                  final state = ref.watch(stackRestoringUIStateProvider
                      .select((value) => value.preferences));
                  return !isDesktop
                      ? RestoringItemCard(
                          left: SizedBox(
                            width: 32,
                            height: 32,
                            child: RoundedContainer(
                              padding: const EdgeInsets.all(0),
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .buttonBackSecondary,
                              child: Center(
                                child: SvgPicture.asset(
                                  Assets.svg.gear,
                                  width: 16,
                                  height: 16,
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .accentColorDark,
                                ),
                              ),
                            ),
                          ),
                          right: SizedBox(
                            width: 20,
                            height: 20,
                            child: _getIconForState(state),
                          ),
                          title: "Preferences",
                          subTitle: state == StackRestoringStatus.failed
                              ? Text(
                                  "Something went wrong",
                                  style: STextStyles.errorSmall(context),
                                )
                              : null,
                        )
                      : RoundedContainer(
                          padding: EdgeInsets.all(0),
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .popupBG,
                          borderColor: Theme.of(context)
                              .extension<StackColors>()!
                              .background,
                          child: RestoringItemCard(
                            left: SizedBox(
                              width: 32,
                              height: 32,
                              child: RoundedContainer(
                                padding: const EdgeInsets.all(0),
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .buttonBackSecondary,
                                child: Center(
                                  child: SvgPicture.asset(
                                    Assets.svg.gear,
                                    width: 16,
                                    height: 16,
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .accentColorDark,
                                  ),
                                ),
                              ),
                            ),
                            right: SizedBox(
                              width: 20,
                              height: 20,
                              child: _getIconForState(state),
                            ),
                            title: "Preferences",
                            subTitle: state == StackRestoringStatus.failed
                                ? Text(
                                    "Something went wrong",
                                    style: STextStyles.errorSmall(context),
                                  )
                                : null,
                          ),
                        );
                },
              ),
              const SizedBox(
                height: 12,
              ),
              Consumer(
                builder: (_, ref, __) {
                  final state = ref.watch(stackRestoringUIStateProvider
                      .select((value) => value.addressBook));
                  return !isDesktop
                      ? RestoringItemCard(
                          left: SizedBox(
                            width: 32,
                            height: 32,
                            child: RoundedContainer(
                              padding: const EdgeInsets.all(0),
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .buttonBackSecondary,
                              child: Center(
                                child: AddressBookIcon(
                                  width: 16,
                                  height: 16,
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .accentColorDark,
                                ),
                              ),
                            ),
                          ),
                          right: SizedBox(
                            width: 20,
                            height: 20,
                            child: _getIconForState(state),
                          ),
                          title: "Address book",
                          subTitle: state == StackRestoringStatus.failed
                              ? Text(
                                  "Something went wrong",
                                  style: STextStyles.errorSmall(context),
                                )
                              : null,
                        )
                      : RoundedContainer(
                          padding: EdgeInsets.all(0),
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .popupBG,
                          borderColor: Theme.of(context)
                              .extension<StackColors>()!
                              .background,
                          child: RestoringItemCard(
                            left: SizedBox(
                              width: 32,
                              height: 32,
                              child: RoundedContainer(
                                padding: const EdgeInsets.all(0),
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .buttonBackSecondary,
                                child: Center(
                                  child: AddressBookIcon(
                                    width: 16,
                                    height: 16,
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .accentColorDark,
                                  ),
                                ),
                              ),
                            ),
                            right: SizedBox(
                              width: 20,
                              height: 20,
                              child: _getIconForState(state),
                            ),
                            title: "Address book",
                            subTitle: state == StackRestoringStatus.failed
                                ? Text(
                                    "Something went wrong",
                                    style: STextStyles.errorSmall(context),
                                  )
                                : null,
                          ),
                        );
                },
              ),
              const SizedBox(
                height: 12,
              ),
              Consumer(
                builder: (_, ref, __) {
                  final state = ref.watch(stackRestoringUIStateProvider
                      .select((value) => value.nodes));
                  return !isDesktop
                      ? RestoringItemCard(
                          left: SizedBox(
                            width: 32,
                            height: 32,
                            child: RoundedContainer(
                              padding: const EdgeInsets.all(0),
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .buttonBackSecondary,
                              child: Center(
                                child: SvgPicture.asset(
                                  Assets.svg.node,
                                  width: 16,
                                  height: 16,
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .accentColorDark,
                                ),
                              ),
                            ),
                          ),
                          right: SizedBox(
                            width: 20,
                            height: 20,
                            child: _getIconForState(state),
                          ),
                          title: "Nodes",
                          subTitle: state == StackRestoringStatus.failed
                              ? Text(
                                  "Something went wrong",
                                  style: STextStyles.errorSmall(context),
                                )
                              : null,
                        )
                      : RoundedContainer(
                          padding: EdgeInsets.all(0),
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .popupBG,
                          borderColor: Theme.of(context)
                              .extension<StackColors>()!
                              .background,
                          child: RestoringItemCard(
                            left: SizedBox(
                              width: 32,
                              height: 32,
                              child: RoundedContainer(
                                padding: const EdgeInsets.all(0),
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .buttonBackSecondary,
                                child: Center(
                                  child: SvgPicture.asset(
                                    Assets.svg.node,
                                    width: 16,
                                    height: 16,
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .accentColorDark,
                                  ),
                                ),
                              ),
                            ),
                            right: SizedBox(
                              width: 20,
                              height: 20,
                              child: _getIconForState(state),
                            ),
                            title: "Nodes",
                            subTitle: state == StackRestoringStatus.failed
                                ? Text(
                                    "Something went wrong",
                                    style: STextStyles.errorSmall(context),
                                  )
                                : null,
                          ));
                },
              ),
              const SizedBox(
                height: 12,
              ),
              Consumer(
                builder: (_, ref, __) {
                  final state = ref.watch(stackRestoringUIStateProvider
                      .select((value) => value.trades));
                  return !isDesktop
                      ? Container(
                          child: RestoringItemCard(
                            left: SizedBox(
                              width: 32,
                              height: 32,
                              child: RoundedContainer(
                                padding: const EdgeInsets.all(0),
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .buttonBackSecondary,
                                child: Center(
                                  child: SvgPicture.asset(
                                    Assets.svg.arrowsTwoWay,
                                    width: 16,
                                    height: 16,
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .accentColorDark,
                                  ),
                                ),
                              ),
                            ),
                            right: SizedBox(
                              width: 20,
                              height: 20,
                              child: _getIconForState(state),
                            ),
                            title: "Exchange history",
                            subTitle: state == StackRestoringStatus.failed
                                ? Text(
                                    "Something went wrong",
                                    style: STextStyles.errorSmall(context),
                                  )
                                : null,
                          ),
                        )
                      : RoundedContainer(
                          padding: EdgeInsets.all(0),
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .popupBG,
                          borderColor: Theme.of(context)
                              .extension<StackColors>()!
                              .background,
                          child: RestoringItemCard(
                            left: SizedBox(
                              width: 32,
                              height: 32,
                              child: RoundedContainer(
                                padding: const EdgeInsets.all(0),
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .buttonBackSecondary,
                                child: Center(
                                  child: SvgPicture.asset(
                                    Assets.svg.arrowsTwoWay,
                                    width: 16,
                                    height: 16,
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .accentColorDark,
                                  ),
                                ),
                              ),
                            ),
                            right: SizedBox(
                              width: 20,
                              height: 20,
                              child: _getIconForState(state),
                            ),
                            title: "Exchange history",
                            subTitle: state == StackRestoringStatus.failed
                                ? Text(
                                    "Something went wrong",
                                    style: STextStyles.errorSmall(context),
                                  )
                                : null,
                          ),
                        );
                },
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                "Wallets",
                style: STextStyles.itemSubtitle(context),
              ),
              const SizedBox(
                height: 8,
              ),
              ...ref
                  .watch(stackRestoringUIStateProvider
                      .select((value) => value.walletStateProviders))
                  .values
                  .map(
                    (provider) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: RestoringWalletCard(
                        provider: provider,
                      ),
                    ),
                  ),
              const SizedBox(
                height: 30,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width - 32,
                child: !isDesktop
                    ? TextButton(
                        onPressed: () async {
                          if (_success) {
                            Navigator.of(context).pop();
                          } else {
                            if (await _requestCancel()) {
                              await _cancel();
                            }
                          }
                        },
                        style: Theme.of(context)
                            .extension<StackColors>()!
                            .getPrimaryEnabledButtonStyle(context),
                        child: Text(
                          _success ? "OK" : "Cancel restore process",
                          style: STextStyles.button(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .buttonTextPrimary,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _success
                              ? PrimaryButton(
                                  width: 248,
                                  buttonHeight: ButtonHeight.l,
                                  enabled: true,
                                  label: "Done",
                                  onPressed: () async {
                                    DesktopMenuItemId keyID =
                                        DesktopMenuItemId.myStack;

                                    ref
                                        .read(currentDesktopMenuItemProvider
                                            .state)
                                        .state = keyID;

                                    if (widget.shouldPushToHome) {
                                      unawaited(
                                        Navigator.of(context)
                                            .pushNamedAndRemoveUntil(
                                          DesktopHomeView.routeName,
                                          (route) => false,
                                        ),
                                      );
                                    } else {
                                      Navigator.of(context, rootNavigator: true)
                                          .popUntil(
                                        ModalRoute.withName(
                                            DesktopHomeView.routeName),
                                      );
                                    }
                                  },
                                )
                              : SecondaryButton(
                                  width: 248,
                                  buttonHeight: ButtonHeight.l,
                                  enabled: true,
                                  label: "Cancel restore process",
                                  onPressed: () async {
                                    if (await _requestCancel()) {
                                      await _cancel();
                                    }
                                  },
                                ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
