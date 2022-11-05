import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class RestoreBackupDialog extends StatelessWidget {
  const RestoreBackupDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
        maxHeight: 750,
        maxWidth: 600,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              "Restoring Stack Wallet",
                              style: STextStyles.desktopH3(context),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const DesktopDialogCloseButton(),
                        ],
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                          children: [
                            Text(
                              "Settings",
                              style: STextStyles.desktopTextExtraSmall(context)
                                  .copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textDark3,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                        child: RoundedWhiteContainer(
                          borderColor: Theme.of(context)
                              .extension<StackColors>()!
                              .background,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    Assets.svg.framedAddressBook,
                                    width: 40,
                                    height: 40,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Address Book",
                                    style:
                                        STextStyles.desktopTextSmall(context),
                                  ),
                                ],
                              ),

                              ///TODO: CHECKMARK ANIMATION
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                        child: RoundedWhiteContainer(
                          borderColor: Theme.of(context)
                              .extension<StackColors>()!
                              .background,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    Assets.svg.framedGear,
                                    width: 40,
                                    height: 40,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Preferences",
                                    style:
                                        STextStyles.desktopTextSmall(context),
                                  ),
                                ],
                              ),

                              ///TODO: CHECKMARK ANIMATION
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                          children: [
                            Text(
                              "Wallets",
                              style: STextStyles.desktopTextExtraSmall(context)
                                  .copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textDark3,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SecondaryButton(
                              desktopMed: true,
                              width: 200,
                              label: "Cancel restore process",
                              onPressed: () {
                                Navigator.of(context).pop();
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
          },
        ));
  }
}
