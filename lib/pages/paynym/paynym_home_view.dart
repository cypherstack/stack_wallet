import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/paynym/add_new_paynym_follow_view.dart';
import 'package:stackwallet/pages/paynym/dialogs/paynym_qr_popup.dart';
import 'package:stackwallet/pages/paynym/subwidgets/desktop_paynym_details.dart';
import 'package:stackwallet/pages/paynym/subwidgets/paynym_bot.dart';
import 'package:stackwallet/pages/paynym/subwidgets/paynym_followers_list.dart';
import 'package:stackwallet/pages/paynym/subwidgets/paynym_following_list.dart';
import 'package:stackwallet/providers/ui/selected_paynym_details_item_Provider.dart';
import 'package:stackwallet/providers/wallet/my_paynym_account_state_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/copy_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/qrcode_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/share_icon.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/toggle.dart';

class PaynymHomeView extends ConsumerStatefulWidget {
  const PaynymHomeView({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  static const String routeName = "/paynymHome";

  @override
  ConsumerState<PaynymHomeView> createState() => _PaynymHomeViewState();
}

class _PaynymHomeViewState extends ConsumerState<PaynymHomeView> {
  bool showFollowers = false;
  int secretCount = 0;
  Timer? timer;

  bool _followButtonHoverState = false;

  @override
  void dispose() {
    timer?.cancel();
    timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    final isDesktop = Util.isDesktop;

    return MasterScaffold(
      isDesktop: isDesktop,
      appBar: isDesktop
          ? DesktopAppBar(
              isCompactHeight: true,
              background: Theme.of(context).extension<StackColors>()!.popupBG,
              leading: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 20,
                    ),
                    child: AppBarIconButton(
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
                      onPressed: Navigator.of(context).pop,
                    ),
                  ),
                  SvgPicture.asset(
                    Assets.svg.user,
                    width: 32,
                    height: 32,
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    "PayNym",
                    style: STextStyles.desktopH3(context),
                  )
                ],
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  height: 56,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() {
                      _followButtonHoverState = true;
                    }),
                    onExit: (_) => setState(() {
                      _followButtonHoverState = false;
                    }),
                    child: GestureDetector(
                      onTap: () {
                        showDialog<void>(
                          context: context,
                          builder: (context) => AddNewPaynymFollowView(
                            walletId: widget.walletId,
                          ),
                        );
                      },
                      child: RoundedContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        color: _followButtonHoverState
                            ? Theme.of(context)
                                .extension<StackColors>()!
                                .highlight
                            : Colors.transparent,
                        radiusMultiplier: 100,
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              Assets.svg.plus,
                              width: 16,
                              height: 16,
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textDark,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Follow",
                                  style:
                                      STextStyles.desktopButtonSecondaryEnabled(
                                              context)
                                          .copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(
                                  height: 2,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : AppBar(
              leading: AppBarBackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              titleSpacing: 0,
              title: Text(
                "PayNym",
                style: STextStyles.navBarTitle(context),
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: AppBarIconButton(
                      icon: SvgPicture.asset(
                        Assets.svg.circlePlusFilled,
                        width: 20,
                        height: 20,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorDark,
                      ),
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          AddNewPaynymFollowView.routeName,
                          arguments: widget.walletId,
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: AppBarIconButton(
                      icon: SvgPicture.asset(
                        Assets.svg.circleQuestion,
                        width: 20,
                        height: 20,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorDark,
                      ),
                      onPressed: () {
                        // todo info ?
                      },
                    ),
                  ),
                ),
                const SizedBox(
                  width: 4,
                ),
              ],
            ),
      body: ConditionalParent(
        condition: !isDesktop,
        builder: (child) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            if (!isDesktop)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      secretCount++;
                      if (secretCount > 5) {
                        debugPrint(
                            "My Account: ${ref.read(myPaynymAccountStateProvider.state).state}");
                        debugPrint(
                            "My Account: ${ref.read(myPaynymAccountStateProvider.state).state!.following}");
                        secretCount = 0;
                      }

                      timer ??= Timer(
                        const Duration(milliseconds: 1500),
                        () {
                          secretCount = 0;
                          timer = null;
                        },
                      );
                    },
                    child: PayNymBot(
                      paymentCodeString: ref
                          .watch(myPaynymAccountStateProvider.state)
                          .state!
                          .codes
                          .first
                          .code,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    ref
                        .watch(myPaynymAccountStateProvider.state)
                        .state!
                        .nymName,
                    style: STextStyles.desktopMenuItemSelected(context),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    Format.shorten(
                        ref
                            .watch(myPaynymAccountStateProvider.state)
                            .state!
                            .codes
                            .first
                            .code,
                        12,
                        5),
                    style: STextStyles.label(context).copyWith(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(
                    height: 11,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: "Copy",
                          buttonHeight: ButtonHeight.xl,
                          iconSpacing: 8,
                          icon: CopyIcon(
                            width: 12,
                            height: 12,
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .buttonTextSecondary,
                          ),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(
                                text: ref
                                    .read(myPaynymAccountStateProvider.state)
                                    .state!
                                    .codes
                                    .first
                                    .code,
                              ),
                            );
                            unawaited(
                              showFloatingFlushBar(
                                type: FlushBarType.info,
                                message: "Copied to clipboard",
                                iconAsset: Assets.svg.copy,
                                context: context,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 13,
                      ),
                      Expanded(
                        child: SecondaryButton(
                          label: "Share",
                          buttonHeight: ButtonHeight.xl,
                          iconSpacing: 8,
                          icon: ShareIcon(
                            width: 12,
                            height: 12,
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .buttonTextSecondary,
                          ),
                          onPressed: () async {
                            Rect? sharePositionOrigin;
                            if (await Util.isIPad) {
                              final box =
                                  context.findRenderObject() as RenderBox?;
                              if (box != null) {
                                sharePositionOrigin =
                                    box.localToGlobal(Offset.zero) & box.size;
                              }
                            }

                            await Share.share(
                                ref
                                    .read(myPaynymAccountStateProvider.state)
                                    .state!
                                    .codes
                                    .first
                                    .code,
                                sharePositionOrigin: sharePositionOrigin);
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 13,
                      ),
                      Expanded(
                        child: SecondaryButton(
                          label: "Address",
                          buttonHeight: ButtonHeight.xl,
                          iconSpacing: 8,
                          icon: QrCodeIcon(
                            width: 12,
                            height: 12,
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .buttonTextSecondary,
                          ),
                          onPressed: () {
                            showDialog<void>(
                              context: context,
                              builder: (context) => PaynymQrPopup(
                                paynymAccount: ref
                                    .read(myPaynymAccountStateProvider.state)
                                    .state!,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            if (isDesktop)
              Padding(
                padding: const EdgeInsets.all(24),
                child: RoundedWhiteContainer(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 4,
                      ),
                      GestureDetector(
                        onTap: () {
                          secretCount++;
                          if (secretCount > 5) {
                            debugPrint(
                                "My Account: ${ref.read(myPaynymAccountStateProvider.state).state}");
                            debugPrint(
                                "My Account: ${ref.read(myPaynymAccountStateProvider.state).state!.following}");
                            secretCount = 0;
                          }

                          timer ??= Timer(
                            const Duration(milliseconds: 1500),
                            () {
                              secretCount = 0;
                              timer = null;
                            },
                          );
                        },
                        child: PayNymBot(
                          paymentCodeString: ref
                              .watch(myPaynymAccountStateProvider.state)
                              .state!
                              .codes
                              .first
                              .code,
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ref
                                .watch(myPaynymAccountStateProvider.state)
                                .state!
                                .nymName,
                            style: STextStyles.desktopH3(context),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            Format.shorten(
                                ref
                                    .watch(myPaynymAccountStateProvider.state)
                                    .state!
                                    .codes
                                    .first
                                    .code,
                                12,
                                5),
                            style:
                                STextStyles.desktopTextExtraExtraSmall(context),
                          ),
                        ],
                      ),
                      const Spacer(),
                      SecondaryButton(
                        label: "Copy",
                        buttonHeight: ButtonHeight.l,
                        width: 160,
                        icon: CopyIcon(
                          width: 18,
                          height: 18,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textDark,
                        ),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(
                              text: ref
                                  .read(myPaynymAccountStateProvider.state)
                                  .state!
                                  .codes
                                  .first
                                  .code,
                            ),
                          );
                          unawaited(
                            showFloatingFlushBar(
                              type: FlushBarType.info,
                              message: "Copied to clipboard",
                              iconAsset: Assets.svg.copy,
                              context: context,
                            ),
                          );
                        },
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      SecondaryButton(
                        label: "Address",
                        width: 160,
                        buttonHeight: ButtonHeight.l,
                        icon: QrCodeIcon(
                          width: 18,
                          height: 18,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textDark,
                        ),
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            builder: (context) => PaynymQrPopup(
                              paynymAccount: ref
                                  .read(myPaynymAccountStateProvider.state)
                                  .state!,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            if (!isDesktop)
              const SizedBox(
                height: 24,
              ),
            ConditionalParent(
              condition: isDesktop,
              builder: (child) => Padding(
                padding: const EdgeInsets.only(left: 24),
                child: child,
              ),
              child: SizedBox(
                height: isDesktop ? 56 : 48,
                width: isDesktop ? 490 : null,
                child: Toggle(
                  onColor: Theme.of(context).extension<StackColors>()!.popupBG,
                  onText:
                      "Following (${ref.watch(myPaynymAccountStateProvider.state).state?.following.length ?? 0})",
                  offColor: Theme.of(context)
                      .extension<StackColors>()!
                      .textFieldDefaultBG,
                  offText:
                      "Followers (${ref.watch(myPaynymAccountStateProvider.state).state?.followers.length ?? 0})",
                  isOn: showFollowers,
                  onValueChanged: (value) {
                    setState(() {
                      showFollowers = value;
                    });
                  },
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: isDesktop ? 20 : 16,
            ),
            Expanded(
              child: ConditionalParent(
                condition: isDesktop,
                builder: (child) => Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 490,
                        child: child,
                      ),
                      const SizedBox(
                        width: 24,
                      ),
                      if (ref
                              .watch(selectedPaynymDetailsItemProvider.state)
                              .state !=
                          null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 600,
                                ),
                                child: DesktopPaynymDetails(
                                  walletId: widget.walletId,
                                  accountLite: ref
                                      .watch(selectedPaynymDetailsItemProvider
                                          .state)
                                      .state!,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (ref
                              .watch(selectedPaynymDetailsItemProvider.state)
                              .state !=
                          null)
                        const SizedBox(
                          width: 24,
                        ),
                    ],
                  ),
                ),
                child: ConditionalParent(
                  condition: !isDesktop,
                  builder: (child) => Container(
                    child: child,
                  ),
                  child: !showFollowers
                      ? PaynymFollowingList(
                          walletId: widget.walletId,
                        )
                      : PaynymFollowersList(
                          walletId: widget.walletId,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
