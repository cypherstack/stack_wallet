import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/paynym/paynym_account.dart';
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
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/toggle.dart';

class PaynymHomeView extends StatefulWidget {
  const PaynymHomeView({
    Key? key,
    required this.walletId,
    required this.nymAccount,
  }) : super(key: key);

  final String walletId;
  final PaynymAccount nymAccount;

  static const String routeName = "/paynymHome";

  @override
  State<PaynymHomeView> createState() => _PaynymHomeViewState();
}

class _PaynymHomeViewState extends State<PaynymHomeView> {
  bool showFollowing = false;

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
                  // todo add ?
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
                  // todo add ?
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
              PayNymBot(
                paymentCodeString: widget.nymAccount.codes.first.code,
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                widget.nymAccount.nymName,
                style: STextStyles.desktopMenuItemSelected(context),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                Format.shorten(widget.nymAccount.codes.first.code, 12, 5),
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
                        // copy to clipboard
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

class PayNymBot extends StatelessWidget {
  const PayNymBot({
    Key? key,
    required this.paymentCodeString,
    this.size = 60.0,
  }) : super(key: key);

  final String paymentCodeString;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          "https://paynym.is/$paymentCodeString/avatar",
          loadingBuilder: (context, child, event) {
            if (event == null) {
              return child;
            } else {
              return const LoadingIndicator();
            }
          },
        ),
      ),
    );
  }
}
