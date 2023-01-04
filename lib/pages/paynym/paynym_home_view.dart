import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/paynym/add_new_paynym_follow_view.dart';
import 'package:stackwallet/pages/paynym/dialogs/paynym_qr_popup.dart';
import 'package:stackwallet/pages/paynym/subwidgets/paynym_bot.dart';
import 'package:stackwallet/providers/wallet/my_paynym_account_state_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/copy_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/qrcode_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/share_icon.dart';
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
  bool showFollowing = false;
  int secretCount = 0;
  Timer? timer;

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
      appBar: AppBar(
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
                  color: Theme.of(context).extension<StackColors>()!.textDark,
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
                  color: Theme.of(context).extension<StackColors>()!.textDark,
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                ref.watch(myPaynymAccountStateProvider.state).state!.nymName,
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
                style: STextStyles.label(context),
              ),
              const SizedBox(
                height: 11,
              ),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: "Copy",
                      buttonHeight: ButtonHeight.l,
                      iconSpacing: 4,
                      icon: CopyIcon(
                        width: 10,
                        height: 10,
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
                  ),
                  const SizedBox(
                    width: 13,
                  ),
                  Expanded(
                    child: SecondaryButton(
                      label: "Share",
                      buttonHeight: ButtonHeight.l,
                      iconSpacing: 4,
                      icon: ShareIcon(
                        width: 10,
                        height: 10,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textDark,
                      ),
                      onPressed: () {
                        // copy to clipboard
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 13,
                  ),
                  Expanded(
                    child: SecondaryButton(
                      label: "Address",
                      buttonHeight: ButtonHeight.l,
                      iconSpacing: 4,
                      icon: QrCodeIcon(
                        width: 10,
                        height: 10,
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
                  ),
                ],
              ),
              const SizedBox(
                height: 24,
              ),
              SizedBox(
                height: 40,
                child: Toggle(
                  onColor: Theme.of(context).extension<StackColors>()!.popupBG,
                  onText: "Following",
                  offColor: Theme.of(context)
                      .extension<StackColors>()!
                      .textFieldDefaultBG,
                  offText: "Followers",
                  isOn: showFollowing,
                  onValueChanged: (value) {
                    setState(() {
                      showFollowing = value;
                    });
                  },
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              RoundedWhiteContainer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Your PayNym contacts will appear here",
                      style: STextStyles.label(context),
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
