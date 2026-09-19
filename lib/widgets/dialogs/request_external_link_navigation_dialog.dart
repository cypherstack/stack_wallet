import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../conditional_parent.dart';
import '../desktop/desktop_dialog_close_button.dart';
import '../desktop/primary_button.dart';
import '../desktop/secondary_button.dart';
import 's_dialog.dart';

Future<void> showRequestExternalLinkAndMaybeLaunch(
  BuildContext context, {
  required Uri uri,
}) async {
  final shouldContinue = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => RequestExternalLinkNavigationDialog(uri: uri),
  );

  if (shouldContinue == true) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class RequestExternalLinkNavigationDialog extends StatefulWidget {
  const RequestExternalLinkNavigationDialog({super.key, required this.uri});

  final Uri uri;

  @override
  State<RequestExternalLinkNavigationDialog> createState() =>
      _RequestExternalLinkNavigationDialogState();
}

class _RequestExternalLinkNavigationDialogState
    extends State<RequestExternalLinkNavigationDialog> {
  @override
  Widget build(BuildContext context) {
    return SDialog(
      child: ConditionalParent(
        condition: Util.isDesktop,
        builder: (child) => SizedBox(width: 500, child: child),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Padding(
              padding: .only(
                left: Util.isDesktop ? 32 : 16,
                top: Util.isDesktop ? 0 : 16,
                bottom: Util.isDesktop ? 16 : 8,
              ),
              child: Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  SelectableText(
                    "Attention",
                    style: Util.isDesktop
                        ? STextStyles.desktopH3(context)
                        : STextStyles.pageTitleH2(context),
                  ),
                  if (Util.isDesktop) const DesktopDialogCloseButton(),
                ],
              ),
            ),
            Padding(
              padding: .symmetric(horizontal: Util.isDesktop ? 32 : 16),
              child: Text(
                "You are about to open "
                "${widget.uri.scheme}://${widget.uri.host} "
                "in your browser.",
                style: Util.isDesktop
                    ? STextStyles.desktopTextSmall(context)
                    : STextStyles.smallMed14(context),
              ),
            ),
            Padding(
              padding: .only(
                top: Util.isDesktop ? 32 : 24,
                left: Util.isDesktop ? 32 : 16,
                right: Util.isDesktop ? 32 : 16,
                bottom: Util.isDesktop ? 32 : 16,
              ),
              child: Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: "Cancel",
                      buttonHeight: Util.isDesktop ? .l : null,
                      onPressed: Navigator.of(context).pop,
                    ),
                  ),
                  Util.isDesktop
                      ? const SizedBox(width: 32)
                      : const SizedBox(width: 16),
                  Expanded(
                    child: PrimaryButton(
                      label: "Continue",
                      buttonHeight: Util.isDesktop ? .l : null,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
