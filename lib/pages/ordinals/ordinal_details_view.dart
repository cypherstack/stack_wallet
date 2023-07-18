import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/models/ordinal.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';

class OrdinalDetailsView extends StatefulWidget {
  const OrdinalDetailsView({
    super.key,
    required this.walletId,
    required this.ordinal,
  });

  final String walletId;
  final Ordinal ordinal;

  static const routeName = "/ordinalDetailsView";

  @override
  State<OrdinalDetailsView> createState() => _OrdinalDetailsViewState();
}

class _OrdinalDetailsViewState extends State<OrdinalDetailsView> {
  @override
  Widget build(BuildContext context) {
    return Background(
      child: SafeArea(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
            leading: const AppBarBackButton(),
            title: Text(
              "Ordinal details",
              style: STextStyles.navBarTitle(context),
            ),
          ),
          body: Column(),
        ),
      ),
    );
  }
}

class _OrdinalImageGroup extends StatelessWidget {
  const _OrdinalImageGroup({
    super.key,
    required this.ordinal,
  });

  final Ordinal ordinal;

  static const _spacing = 12.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          ordinal.name,
          style: STextStyles.w600_16(context),
        ),
        const SizedBox(
          height: _spacing,
        ),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            color: Colors.red,
          ),
        ),
        const SizedBox(
          height: _spacing,
        ),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: "Download",
                icon: SvgPicture.asset(Assets.svg.arrowDown),
                buttonHeight: ButtonHeight.s,
                onPressed: () {
                  // TODO: save and download image to device
                },
              ),
            ),
            const SizedBox(
              width: _spacing,
            ),
            Expanded(
              child: PrimaryButton(
                label: "Send",
                icon: SvgPicture.asset(
                  Assets.svg.star,
                ),
                buttonHeight: ButtonHeight.s,
                onPressed: () {
                  // TODO: try send
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
