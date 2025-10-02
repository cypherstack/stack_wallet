import 'package:flutter/material.dart';

import '../../db/hive/db.dart';
import '../../utilities/assets.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../conditional_parent.dart';
import '../desktop/desktop_dialog.dart';
import '../desktop/desktop_dialog_close_button.dart';
import '../desktop/primary_button.dart';
import '../stack_dialog.dart';

const _kOneTimeTorHasBeenAddedDialogWasShown =
    "oneTimeTorHasBeenAddedDialogWasShown";

Future<void> showOneTimeTorHasBeenAddedDialogIfRequired(
  BuildContext context,
) async {
  final box =
      await DB.instance.hive.openBox<bool>(DB.boxNameOneTimeDialogsShown);

  if (!box.get(
        _kOneTimeTorHasBeenAddedDialogWasShown,
        defaultValue: false,
      )! &&
      context.mounted) {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _TorHasBeenAddedDialog(),
    );
  }
}

class _TorHasBeenAddedDialog extends StatefulWidget {
  const _TorHasBeenAddedDialog({super.key});

  @override
  State<_TorHasBeenAddedDialog> createState() => _TorHasBeenAddedDialogState();
}

class _TorHasBeenAddedDialogState extends State<_TorHasBeenAddedDialog> {
  bool _lock = false;

  void setDoNotShowAgain() async {
    if (_lock) {
      return;
    }
    _lock = true;
    try {
      final box = await DB.instance.hive.openBox<bool>(
        DB.boxNameOneTimeDialogsShown,
      );
      await box.put(_kOneTimeTorHasBeenAddedDialogWasShown, true);
    } catch (_) {
      //
    } finally {
      _lock = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: Util.isDesktop,
      builder: (child) => DesktopDialog(
        maxHeight: double.infinity,
        maxWidth: 450,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    "",
                    style: STextStyles.desktopH3(context),
                  ),
                ),
                DesktopDialogCloseButton(
                  onPressedOverride: () {
                    setDoNotShowAgain();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: child,
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PrimaryButton(
                    buttonHeight: ButtonHeight.l,
                    width: 180,
                    label: "Ok",
                    onPressed: () {
                      setDoNotShowAgain();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      child: ConditionalParent(
        condition: !Util.isDesktop,
        builder: (child) => StackDialogBase(
          child: Column(
            children: [
              child,
              const SizedBox(
                height: 28,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2,
                    child: PrimaryButton(
                      label: "Ok",
                      onPressed: () {
                        setDoNotShowAgain();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        child: Column(
          children: [
            const StacyOnion(),
            SizedBox(
              height: Util.isDesktop ? 24 : 16,
            ),
            Text(
              "Tor has been added to help keep your connections private and secure!",
              style: Util.isDesktop
                  ? STextStyles.desktopTextMedium(context)
                  : STextStyles.smallMed14(context),
            ),
            SizedBox(
              height: Util.isDesktop ? 24 : 16,
            ),
            Text(
              "Note: Tor does NOT yet work for Monero, Mimblewimblecoin or Epic Cash wallets. "
              "Opening one of these will leak your IP address.",
              style: Util.isDesktop
                  ? STextStyles.desktopTextMedium(context)
                  : STextStyles.smallMed14(context),
            ),
          ],
        ),
      ),
    );
  }
}

class StacyOnion extends StatelessWidget {
  const StacyOnion({super.key});

  @override
  Widget build(BuildContext context) {
    return Image(
      height: 200,
      image: AssetImage(
        Assets.gif.stacyOnion,
      ),
    );
  }
}
