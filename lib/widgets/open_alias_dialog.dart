import 'package:flutter/material.dart';

import '../services/openalias/open_alias.dart';
import '../themes/stack_colors.dart';
import '../utilities/constants.dart';
import '../utilities/text_styles.dart';
import '../utilities/util.dart';
import 'conditional_parent.dart';
import 'desktop/desktop_dialog.dart';
import 'desktop/desktop_dialog_close_button.dart';
import 'desktop/primary_button.dart';
import 'desktop/secondary_button.dart';
import 'rounded_container.dart';
import 'stack_dialog.dart';
import 'stack_text_field.dart';

class OpenAliasDialog extends StatefulWidget {
  const OpenAliasDialog({
    super.key,
    required this.resolve,
    this.initialInput = "",
  });

  final Future<OpenAliasRecipient> Function(String) resolve;
  final String initialInput;

  @override
  State<OpenAliasDialog> createState() => _OpenAliasDialogState();
}

class _OpenAliasDialogState extends State<OpenAliasDialog> {
  late final TextEditingController _inputController;
  late final FocusNode _inputFocusNode;
  late String _lastInput;

  OpenAliasRecipient? _result;
  String? _error;
  bool _busy = false;
  int _generation = 0;

  void _onInputChanged() {
    // Ignore selection-only notifications.
    if (_inputController.text == _lastInput) {
      return;
    }
    _lastInput = _inputController.text;
    _generation++;
    setState(() {
      _busy = false;
      _result = null;
      _error = null;
    });
  }

  Future<void> _lookup() async {
    if (_busy || _inputController.text.trim().isEmpty) {
      return;
    }
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _result = null;
      _error = null;
    });
    try {
      final result = await widget.resolve(_inputController.text);
      if (mounted && generation == _generation) {
        setState(() => _result = result);
      }
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(
          () => _error = e is OpenAliasException
              ? e.message
              : "Lookup failed. Please try again.",
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  void initState() {
    _inputController = TextEditingController(text: widget.initialInput);
    _inputFocusNode = FocusNode();
    _lastInput = _inputController.text;
    _inputController.addListener(_onInputChanged);

    super.initState();
  }

  @override
  void dispose() {
    _generation++;
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final colors = Theme.of(context).extension<StackColors>()!;
    final result = _result;

    final labelStyle = isDesktop
        ? STextStyles.desktopTextExtraExtraSmall(context)
        : STextStyles.smallMed12(context);
    final valueStyle = isDesktop
        ? STextStyles.desktopTextExtraExtraSmall(
            context,
          ).copyWith(color: colors.textDark)
        : STextStyles.itemSubtitle12(context);

    return ConditionalParent(
      condition: isDesktop,
      builder: (child) => DesktopDialog(
        maxWidth: 580,
        maxHeight: double.infinity,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    "Use OpenAlias",
                    style: STextStyles.desktopH3(context),
                  ),
                ),
                const DesktopDialogCloseButton(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32, right: 32, bottom: 32),
              child: child,
            ),
          ],
        ),
      ),
      child: ConditionalParent(
        condition: !isDesktop,
        builder: (child) => StackDialogBase(
          keyboardPaddingAmount: MediaQuery.of(context).viewInsets.bottom,
          child: child,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isDesktop)
              Text("Use OpenAlias", style: STextStyles.pageTitleH2(context)),
            if (!isDesktop) const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
              child: TextField(
                key: const Key("openAliasInput"),
                controller: _inputController,
                focusNode: _inputFocusNode,
                autofocus: isDesktop,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.emailAddress,
                style: isDesktop
                    ? STextStyles.desktopTextExtraSmall(
                        context,
                      ).copyWith(color: colors.textFieldActiveText, height: 1.8)
                    : STextStyles.field(context),
                decoration: standardInputDecoration(
                  "Domain or email-style alias",
                  _inputFocusNode,
                  context,
                  desktopMed: isDesktop,
                ),
                onSubmitted: (_) => _lookup(),
              ),
            ),
            if (_error != null)
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      textAlign: TextAlign.left,
                      style: STextStyles.label(
                        context,
                      ).copyWith(color: colors.textError),
                    ),
                  ),
                ),
              ),
            if (result != null) ...[
              const SizedBox(height: 16),
              RoundedContainer(
                color: colors.textFieldDefaultBG,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("OpenAlias", style: labelStyle),
                    const SizedBox(height: 4),
                    SelectableText(result.domain, style: valueStyle),
                    const SizedBox(height: 12),
                    Text("Address", style: labelStyle),
                    const SizedBox(height: 4),
                    SelectableText(
                      result.address,
                      key: const Key("openAliasResolvedAddress"),
                      style: valueStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Check the recipient and full address before continuing.",
                style: labelStyle,
              ),
            ],
            SizedBox(height: isDesktop ? 32 : 24),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: "Cancel",
                    buttonHeight: isDesktop ? ButtonHeight.l : null,
                    onPressed: Navigator.of(context).pop,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: result == null
                      ? PrimaryButton(
                          label: _busy ? "Looking up..." : "Look up",
                          buttonHeight: isDesktop ? ButtonHeight.l : null,
                          enabled: !_busy,
                          onPressed: _lookup,
                        )
                      : PrimaryButton(
                          key: const Key("acceptOpenAlias"),
                          label: "Use address",
                          buttonHeight: isDesktop ? ButtonHeight.l : null,
                          onPressed: () => Navigator.of(context).pop(result),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OpenAliasAttribution extends StatelessWidget {
  const OpenAliasAttribution({super.key, required this.recipient});

  final OpenAliasRecipient recipient;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0, top: 4.0),
        child: Text(
          "Resolved from OpenAlias ${recipient.domain}",
          textAlign: TextAlign.left,
          style: STextStyles.label(context).copyWith(
            color: Theme.of(context).extension<StackColors>()!.accentColorGreen,
          ),
        ),
      ),
    );
  }
}
