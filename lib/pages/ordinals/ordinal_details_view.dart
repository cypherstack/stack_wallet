import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/dto/ordinals/inscription_data.dart';
import 'package:stackwallet/models/ordinal.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/ordinals/widgets/dialogs.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class OrdinalDetailsView extends StatefulWidget {
  const OrdinalDetailsView({
    Key? key,
    required this.walletId,
    required this.ordinal,
  }) : super(key: key);

  final String walletId;
  final Ordinal ordinal;

  static const routeName = "/ordinalDetailsView";

  @override
  _OrdinalDetailsViewState createState() => _OrdinalDetailsViewState();
}

class _OrdinalDetailsViewState extends State<OrdinalDetailsView> {
  static const _spacing = 12.0;

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
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 39,
                    ),
                    child: _OrdinalImageGroup(
                      ordinal: widget.ordinal,
                      walletId: widget.walletId,
                    ),
                  ),
                  _DetailsItemWCopy(
                    title: "Inscription number",
                    data: widget.ordinal.inscriptionNumber.toString(),
                  ),
                  const SizedBox(
                    height: _spacing,
                  ),
                  _DetailsItemWCopy(
                    title: "ID",
                    data: widget.ordinal.inscriptionId,
                  ),
                  const SizedBox(
                    height: _spacing,
                  ),
                  // todo: add utxo status
                  const SizedBox(
                    height: _spacing,
                  ),
                  const _DetailsItemWCopy(
                    title: "Amount",
                    data: "TODO", // TODO infer from utxo utxoTXID:utxoVOUT
                  ),
                  const SizedBox(
                    height: _spacing,
                  ),
                  const _DetailsItemWCopy(
                    title: "Owner address",
                    data: "TODO", // infer from address associated w utxoTXID
                  ),
                  const SizedBox(
                    height: _spacing,
                  ),
                  _DetailsItemWCopy(
                    title: "Transaction ID",
                    data: widget.ordinal.utxoTXID,
                  ),
                  const SizedBox(
                    height: _spacing,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailsItemWCopy extends StatelessWidget {
  const _DetailsItemWCopy({
    Key? key,
    required this.title,
    required this.data,
  }) : super(key: key);

  final String title;
  final String data;

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: STextStyles.itemSubtitle(context),
              ),
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: data));
                  if (context.mounted) {
                    unawaited(
                      showFloatingFlushBar(
                        type: FlushBarType.info,
                        message: "Copied to clipboard",
                        context: context,
                      ),
                    );
                  }
                },
                child: SvgPicture.asset(
                  Assets.svg.copy,
                  color:
                  Theme.of(context).extension<StackColors>()!.infoItemIcons,
                  width: 12,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 4,
          ),
          SelectableText(
            data,
            style: STextStyles.itemSubtitle12(context),
          ),
        ],
      ),
    );
  }
}

class _OrdinalImageGroup extends StatelessWidget {
  const _OrdinalImageGroup({
    Key? key,
    required this.walletId,
    required this.ordinal,
  }) : super(key: key);

  final String walletId;
  final Ordinal ordinal;

  static const _spacing = 12.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "${ordinal.inscriptionId}", // Use any other property you want
          style: STextStyles.w600_16(context),
        ),
        const SizedBox(
          height: _spacing,
        ),
        AspectRatio(
          aspectRatio: 1,
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              color: Colors.red,
              child: Image.network(
                ordinal.content, // Use the preview URL as the image source
                fit: BoxFit.cover,
                filterQuality: FilterQuality.none, // Set the filter mode to nearest
              ),
            ),
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
                icon: SvgPicture.asset(
                  Assets.svg.arrowDown,
                  width: 10,
                  height: 12,
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .buttonTextSecondary,
                ),
                buttonHeight: ButtonHeight.l,
                iconSpacing: 4,
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
                  Assets.svg.send,
                  width: 10,
                  height: 10,
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .buttonTextPrimary,
                ),
                buttonHeight: ButtonHeight.l,
                iconSpacing: 4,
                onPressed: () async {
                  final response = await showDialog<String?>(
                    context: context,
                    builder: (_) => const SendOrdinalUnfreezeDialog(),
                  );
                  if (response == "unfreeze") {
                    // TODO: unfreeze and go to send ord screen
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
