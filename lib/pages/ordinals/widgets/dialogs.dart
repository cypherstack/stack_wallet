import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../themes/stack_colors.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../widgets/desktop/desktop_dialog.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/stack_dialog.dart';

class SendOrdinalUnfreezeDialog extends StatelessWidget {
  const SendOrdinalUnfreezeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    if (Util.isDesktop) {
      return DesktopDialog(
        maxWidth: 450,
        maxHeight: 220,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "This ordinal is frozen",
                    style: STextStyles.desktopH3(context),
                  ),
                  SvgPicture.asset(
                    Assets.svg.coinControl.blocked,
                    width: 24,
                    height: 24,
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "To send this ordinal, you must unfreeze it first.",
                style: STextStyles.desktopTextMedium(context),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: "Cancel",
                      onPressed: Navigator.of(context).pop,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: PrimaryButton(
                      label: "Unfreeze",
                      onPressed: () {
                        Navigator.of(context).pop("unfreeze");
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return StackDialog(
      title: "This ordinal is frozen",
      icon: SvgPicture.asset(
        Assets.svg.coinControl.blocked,
        width: 24,
        height: 24,
        color: Theme.of(context).extension<StackColors>()!.textDark,
      ),
      message: "To send this ordinal, you must unfreeze it first.",
      leftButton: SecondaryButton(
        label: "Cancel",
        onPressed: Navigator.of(context).pop,
      ),
      rightButton: PrimaryButton(
        label: "Unfreeze",
        onPressed: () {
          Navigator.of(context).pop("unfreeze");
        },
      ),
    );
  }
}

class UnfreezeOrdinalDialog extends StatelessWidget {
  const UnfreezeOrdinalDialog({super.key});

  @override
  Widget build(BuildContext context) {
    if (Util.isDesktop) {
      return DesktopDialog(
        maxWidth: 450,
        maxHeight: 200,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Unfreeze ordinal?",
                    style: STextStyles.desktopH3(context),
                  ),
                  SvgPicture.asset(
                    Assets.svg.coinControl.blocked,
                    width: 24,
                    height: 24,
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: "Cancel",
                      onPressed: Navigator.of(context).pop,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: PrimaryButton(
                      label: "Unfreeze",
                      onPressed: () {
                        Navigator.of(context).pop("unfreeze");
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return StackDialog(
      title: "Are you sure you want to unfreeze this ordinal?",
      icon: SvgPicture.asset(
        Assets.svg.coinControl.blocked,
        width: 24,
        height: 24,
        color: Theme.of(context).extension<StackColors>()!.textDark,
      ),
      leftButton: SecondaryButton(
        label: "Cancel",
        onPressed: Navigator.of(context).pop,
      ),
      rightButton: PrimaryButton(
        label: "Unfreeze",
        onPressed: () {
          Navigator.of(context).pop("unfreeze");
        },
      ),
    );
  }
}

class OrdinalRecipientAddressDialog extends StatefulWidget {
  const OrdinalRecipientAddressDialog({
    super.key,
    required this.inscriptionNumber,
  });

  final int inscriptionNumber;

  @override
  State<OrdinalRecipientAddressDialog> createState() =>
      _OrdinalRecipientAddressDialogState();
}

class _OrdinalRecipientAddressDialogState
    extends State<OrdinalRecipientAddressDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    _controller = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildTextField(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: "Paste address",
        hintStyle: STextStyles.fieldLabel(context),
        suffixIcon: IconButton(
          icon: SvgPicture.asset(
            Assets.svg.clipboard,
            width: 20,
            height: 20,
            color: Theme.of(
              context,
            ).extension<StackColors>()!.textFieldDefaultSearchIconLeft,
          ),
          onPressed: () async {
            final data = await Clipboard.getData("text/plain");
            if (data?.text != null) {
              _controller.text = data!.text!;
              setState(() {});
            }
          },
        ),
      ),
      style: STextStyles.field(context),
      autofocus: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Util.isDesktop) {
      return DesktopDialog(
        maxWidth: 500,
        maxHeight: 300,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Send ordinal #${widget.inscriptionNumber}",
                style: STextStyles.desktopH3(context),
              ),
              const SizedBox(height: 12),
              Text(
                "Enter the recipient address",
                style: STextStyles.desktopTextMedium(context),
              ),
              const SizedBox(height: 8),
              _buildTextField(context),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: "Cancel",
                      onPressed: Navigator.of(context).pop,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: PrimaryButton(
                      label: "Continue",
                      onPressed: () {
                        final address = _controller.text.trim();
                        if (address.isNotEmpty) {
                          Navigator.of(context).pop(address);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return StackDialogBase(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Send ordinal #${widget.inscriptionNumber}",
            style: STextStyles.pageTitleH2(context),
          ),
          const SizedBox(height: 12),
          Text(
            "Enter the recipient address",
            style: STextStyles.smallMed12(context),
          ),
          const SizedBox(height: 8),
          _buildTextField(context),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: "Cancel",
                  onPressed: Navigator.of(context).pop,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PrimaryButton(
                  label: "Continue",
                  onPressed: () {
                    final address = _controller.text.trim();
                    if (address.isNotEmpty) {
                      Navigator.of(context).pop(address);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
