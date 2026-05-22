import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

import "../../../utilities/text_styles.dart";
import "../../../utilities/util.dart";
import "../../../widgets/desktop/desktop_dialog.dart";
import "../../../widgets/desktop/primary_button.dart";
import "../../../widgets/desktop/secondary_button.dart";
import "../../../widgets/dialogs/request_external_link_navigation_dialog.dart";

const String _shopInBitPrivacyUrl =
    "https://api.shopinbit.com/static/policy/privacy.html";

class ShopInBitPrivacyCheckbox extends StatelessWidget {
  const ShopInBitPrivacyCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: isDesktop
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: isDesktop ? 3 : 0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: IgnorePointer(
                  child: Checkbox(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: value,
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: isDesktop
                      ? STextStyles.desktopTextSmall(context)
                      : STextStyles.w500_14(context),
                  children: [
                    const TextSpan(
                      text: "I have read and agree to the ShopinBit ",
                    ),
                    TextSpan(
                      text: "Privacy Policy",
                      style: STextStyles.richLink(
                        context,
                      ).copyWith(fontSize: isDesktop ? 18 : 14),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => showRequestExternalLinkAndMaybeLaunch(
                          context,
                          uri: Uri.parse(_shopInBitPrivacyUrl),
                        ),
                    ),
                    const TextSpan(text: "."),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopBrowserWarning extends StatelessWidget {
  const _DesktopBrowserWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      maxWidth: 550,
      maxHeight: 250,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        child: Column(
          children: [
            Text("Attention", style: STextStyles.desktopH2(context)),
            const SizedBox(height: 16),
            Text(message, style: STextStyles.desktopTextSmall(context)),
            const SizedBox(height: 35),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SecondaryButton(
                  width: 200,
                  buttonHeight: ButtonHeight.l,
                  label: "Cancel",
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                const SizedBox(width: 20),
                PrimaryButton(
                  width: 200,
                  buttonHeight: ButtonHeight.l,
                  label: "Continue",
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
