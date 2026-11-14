import 'package:flutter/material.dart';

import '../../../themes/stack_colors.dart';
import '../../../utilities/clipboard_interface.dart';
import '../../../utilities/slatepack_terms.dart';
import '../../../utilities/text_styles.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/stack_dialog.dart';
import '../../slatepack/slatepack_input_field.dart';

/// Asks for a slatepack on mobile and pops with the text.
class SlatepackEntryDialog extends StatefulWidget {
  const SlatepackEntryDialog({
    super.key,
    required this.terms,
    this.clipboard = const ClipboardWrapper(),
  });

  final SlatepackTerms terms;
  final ClipboardInterface clipboard;

  @override
  State<SlatepackEntryDialog> createState() => _SlatepackEntryDialogState();
}

class _SlatepackEntryDialogState extends State<SlatepackEntryDialog> {
  final _controller = TextEditingController();

  bool get _hasText => _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StackDialogBase(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Import ${widget.terms.title}",
            style: STextStyles.desktopTextExtraSmall(context).copyWith(
              color: Theme.of(context)
                  .extension<StackColors>()!
                  .textFieldActiveSearchIconRight,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 12),
          SlatepackInputField(
            controller: _controller,
            hint: "Enter ${widget.terms.payload}",
            clipboard: widget.clipboard,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: "Import",
            enabled: _hasText,
            onPressed: _hasText
                ? () => Navigator.of(context).pop(_controller.text.trim())
                : null,
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            label: "Cancel",
            onPressed: Navigator.of(context).pop,
          ),
        ],
      ),
    );
  }
}
