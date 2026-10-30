/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../themes/stack_colors.dart';
import '../../../utilities/constants.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../widgets/desktop/desktop_dialog.dart';
import '../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/rounded_container.dart';
import '../../../widgets/stack_dialog.dart';
import '../../../widgets/stack_text_field.dart';
import 'address_tag_data.dart';

class AddressTagEditorDialog extends StatefulWidget {
  const AddressTagEditorDialog({
    super.key,
    required this.tags,
    required this.onSave,
  });

  final List<String> tags;
  final Future<void> Function(List<String>) onSave;

  @override
  State<AddressTagEditorDialog> createState() => _AddressTagEditorDialogState();
}

class _AddressTagEditorDialogState extends State<AddressTagEditorDialog> {
  static const _defaultSuggestions = [
    "personal",
    "business",
    "mining",
    "exchange",
    "donation",
    "savings",
  ];

  late final List<String> _tags;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _tags = List<String>.from(widget.tags);
    _controller = TextEditingController()..addListener(_onInputChanged);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onInputChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onInputChanged() => setState(() {});

  bool get _atLimit => _tags.length >= maxAddressTagCount;

  String get _normalizedInput => normalizeAddressTag(_controller.text);

  // The input formatter caps characters while _addTag caps code units, so the
  // button has to use _addTag's rule or it would enable a no-op.
  bool get _canAdd =>
      !_atLimit &&
      _normalizedInput.isNotEmpty &&
      _normalizedInput.length <= maxAddressTagLength &&
      !_tags.any((tag) => normalizeAddressTag(tag) == _normalizedInput);

  bool get _inputTooLong => _normalizedInput.length > maxAddressTagLength;

  void _addTag(String value) {
    final tag = normalizeAddressTag(value);
    if (_tags.length >= maxAddressTagCount ||
        tag.isEmpty ||
        tag.length > maxAddressTagLength ||
        _tags.any((existing) => normalizeAddressTag(existing) == tag)) {
      return;
    }
    setState(() {
      _tags.add(tag);
      _saveError = null;
    });
    _controller.clear();
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _saveError = null;
    });
  }

  List<String> get _availableSuggestions => _atLimit
      ? const []
      : _defaultSuggestions
            .where(
              (suggestion) =>
                  !_tags.any((tag) => normalizeAddressTag(tag) == suggestion),
            )
            .toList();

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.onSave(List.unmodifiable(_tags));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, s) {
      Logging.instance.e(
        "Failed to save address tags",
        error: e,
        stackTrace: s,
      );
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError = "Couldn't save tags. Try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Util.isDesktop) {
      final height = (MediaQuery.sizeOf(context).height - 48)
          .clamp(320.0, 560.0)
          .toDouble();
      return DesktopDialog(
        maxWidth: 500,
        maxHeight: height,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    "Edit tags",
                    style: STextStyles.desktopH3(context),
                  ),
                ),
                DesktopDialogCloseButton(
                  onPressedOverride: _saving
                      ? () {}
                      : () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _buildContent(context),
              ),
            ),
            _buildActions(context, const EdgeInsets.all(32), 16),
          ],
        ),
      );
    }

    return StackDialogBase(
      keyboardPaddingAmount: MediaQuery.of(context).viewInsets.bottom,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Edit tags", style: STextStyles.pageTitleH2(context)),
          const SizedBox(height: 16),
          _buildContent(context),
          _buildActions(context, const EdgeInsets.only(top: 20), 8),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    EdgeInsets padding,
    double spacing,
  ) {
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cancel = SecondaryButton(
            label: "Cancel",
            buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
          );
          final save = PrimaryButton(
            label: _saving ? "Saving..." : "Save",
            buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
            enabled: !_saving,
            onPressed: _saving ? null : _save,
          );
          if (constraints.maxWidth < 320) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                cancel,
                SizedBox(height: spacing),
                save,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: cancel),
              SizedBox(width: spacing),
              Expanded(child: save),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colors = Theme.of(context).extension<StackColors>()!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return RoundedContainer(
                radiusMultiplier: 0.5,
                padding: const EdgeInsets.only(left: 8),
                color: colors.buttonBackPrimary,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Tooltip(
                          message: tag,
                          child: Text(
                            tag,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: STextStyles.w500_14(
                              context,
                            ).copyWith(color: colors.buttonTextPrimary),
                          ),
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        padding: EdgeInsets.zero,
                        tooltip: "Remove $tag tag",
                        onPressed: _saving ? null : () => _removeTag(tag),
                        icon: Icon(
                          Icons.close,
                          size: 18,
                          color: colors.buttonTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        if (_tags.isNotEmpty) const SizedBox(height: 12),
        _buildTagInput(context, colors),
        const SizedBox(height: 8),
        Text(
          _atLimit
              ? "Maximum of $maxAddressTagCount tags reached"
              : _inputTooLong
              ? "Tag is too long"
              : "${_tags.length} of $maxAddressTagCount tags",
          style: STextStyles.w500_12(
            context,
          ).copyWith(color: colors.textSubtitle2),
        ),
        if (_saveError != null) const SizedBox(height: 8),
        if (_saveError != null)
          Text(
            _saveError!,
            key: const Key("addressTagSaveError"),
            style: STextStyles.w500_12(
              context,
            ).copyWith(color: colors.snackBarTextError),
          ),
        if (_availableSuggestions.isNotEmpty) const SizedBox(height: 12),
        if (_availableSuggestions.isNotEmpty)
          Text(
            "Suggestions",
            style: STextStyles.itemSubtitle(
              context,
            ).copyWith(color: colors.textSubtitle1),
          ),
        if (_availableSuggestions.isNotEmpty) const SizedBox(height: 8),
        if (_availableSuggestions.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSuggestions.map((suggestion) {
              return RoundedContainer(
                radiusMultiplier: 0.5,
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 7),
                color: colors.buttonBackSecondary,
                onPressed: _saving ? null : () => _addTag(suggestion),
                child: Text(
                  suggestion,
                  style: STextStyles.w500_14(
                    context,
                  ).copyWith(color: colors.buttonTextSecondary),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildTagInput(BuildContext context, StackColors colors) {
    final field = ClipRRect(
      borderRadius: BorderRadius.circular(Constants.size.circularBorderRadius),
      child: TextField(
        autocorrect: false,
        enableSuggestions: false,
        enabled: !_saving && !_atLimit,
        controller: _controller,
        focusNode: _focusNode,
        inputFormatters: [
          LengthLimitingTextInputFormatter(maxAddressTagLength),
        ],
        style: Util.isDesktop
            ? STextStyles.desktopTextExtraSmall(
                context,
              ).copyWith(color: colors.textFieldActiveText, height: 1.8)
            : STextStyles.field(context),
        decoration: standardInputDecoration(
          "Add tag",
          _focusNode,
          context,
          desktopMed: Util.isDesktop,
        ),
        onSubmitted: (value) {
          _addTag(value);
          _focusNode.requestFocus();
        },
      ),
    );
    final add = PrimaryButton(
      width: 96,
      label: "Add",
      enabled: _canAdd && !_saving,
      onPressed: _canAdd && !_saving
          ? () {
              _addTag(_controller.text);
              _focusNode.requestFocus();
            }
          : null,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 300) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              field,
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: add),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: field),
            const SizedBox(width: 8),
            add,
          ],
        );
      },
    );
  }
}
