import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../notifications/show_flush_bar.dart';
import '../../services/shopinbit/shopinbit_service.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/constants.dart';
import '../../utilities/text_styles.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/rounded_container.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_dialog.dart';
import '../../widgets/stack_text_field.dart';

class ShopInBitSettingsView extends ConsumerStatefulWidget {
  const ShopInBitSettingsView({super.key});

  static const String routeName = "/shopInBitSettings";

  @override
  ConsumerState<ShopInBitSettingsView> createState() =>
      _ShopInBitSettingsViewState();
}

class _ShopInBitSettingsViewState extends ConsumerState<ShopInBitSettingsView> {
  final _manualKeyController = TextEditingController();
  final _manualKeyFocusNode = FocusNode();
  final _verifyKeyController = TextEditingController();
  final _verifyKeyFocusNode = FocusNode();
  late final TextEditingController _displayNameController;
  late final FocusNode _displayNameFocusNode;

  String? _currentKey;
  bool _loading = false;
  bool _savingName = false;

  @override
  void initState() {
    super.initState();
    _currentKey = ShopInBitService.instance.loadCustomerKey();
    final savedName = ShopInBitService.instance.loadDisplayName();
    _displayNameController = TextEditingController(text: savedName ?? '');
    _displayNameFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _manualKeyController.dispose();
    _manualKeyFocusNode.dispose();
    _verifyKeyController.dispose();
    _verifyKeyFocusNode.dispose();
    _displayNameController.dispose();
    _displayNameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveDisplayName() async {
    final name = _displayNameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _savingName = true);
    try {
      await ShopInBitService.instance.setDisplayName(name);
      if (mounted) {
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.success,
            message: "Display name updated",
            context: context,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _generate() async {
    if (_currentKey != null) {
      final proceed = await _showChangeWarning();
      if (proceed != true) return;
    }

    setState(() => _loading = true);
    try {
      final String key;
      if (_currentKey != null) {
        final resp = await ShopInBitService.instance.client.generateKey();
        key = resp.valueOrThrow;
        await ShopInBitService.instance.setCustomerKey(key);
      } else {
        key = await ShopInBitService.instance.ensureCustomerKey();
      }
      setState(() => _currentKey = key);
      if (mounted) {
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.success,
            message: "Customer key generated",
            context: context,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.warning,
            message: "Failed to generate key: $e",
            context: context,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _setManualKey() async {
    final newKey = _manualKeyController.text.trim();
    if (newKey.isEmpty) return;

    if (_currentKey != null) {
      final proceed = await _showChangeWarning();
      if (proceed != true) return;
    }

    setState(() => _loading = true);
    try {
      await ShopInBitService.instance.setCustomerKey(newKey);
      setState(() {
        _currentKey = newKey;
        _manualKeyController.clear();
      });
      if (mounted) {
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.success,
            message: "Customer key set",
            context: context,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.warning,
            message: "Failed to set key: $e",
            context: context,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<bool?> _showChangeWarning() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => StackDialogBase(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Save your current key",
              style: STextStyles.pageTitleH2(context),
            ),
            const SizedBox(height: 8),
            SelectableText(
              "Your current customer key is:",
              style: STextStyles.smallMed14(context),
            ),
            const SizedBox(height: 8),
            RoundedContainer(
              color: Theme.of(
                context,
              ).extension<StackColors>()!.warningBackground,
              child: SelectableText(
                _currentKey!,
                style: STextStyles.smallMed14(context).copyWith(
                  color: Theme.of(
                    context,
                  ).extension<StackColors>()!.warningForeground,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              "Changing your key will disconnect you from "
              "existing ShopinBit conversations. Make sure "
              "you have saved your current key before "
              "proceeding.",
              style: STextStyles.smallMed14(context),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: Theme.of(context)
                        .extension<StackColors>()!
                        .getSecondaryEnabledButtonStyle(context),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      "Cancel",
                      style: STextStyles.button(context).copyWith(
                        color: Theme.of(
                          context,
                        ).extension<StackColors>()!.accentColorDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    style: Theme.of(context)
                        .extension<StackColors>()!
                        .getPrimaryEnabledButtonStyle(context),
                    onPressed: () => Navigator.of(context).pop(null),
                    child: Text(
                      "I saved my key",
                      style: STextStyles.button(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (result == false || !mounted) return false;

    return _showVerifyDialog();
  }

  Future<bool?> _showVerifyDialog() async {
    _verifyKeyController.clear();
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final matches = _verifyKeyController.text.trim() == _currentKey;
            return StackDialogBase(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Verify your key", style: STextStyles.pageTitleH2(ctx)),
                  const SizedBox(height: 8),
                  Text(
                    "Enter your current customer key to "
                    "confirm you have saved it.",
                    style: STextStyles.smallMed14(ctx),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                    child: TextField(
                      controller: _verifyKeyController,
                      focusNode: _verifyKeyFocusNode,
                      style: STextStyles.field(ctx),
                      decoration: standardInputDecoration(
                        "Enter current key",
                        _verifyKeyFocusNode,
                        ctx,
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: Theme.of(ctx)
                              .extension<StackColors>()!
                              .getSecondaryEnabledButtonStyle(ctx),
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(
                            "Cancel",
                            style: STextStyles.button(ctx).copyWith(
                              color: Theme.of(
                                ctx,
                              ).extension<StackColors>()!.accentColorDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton(
                          style: matches
                              ? Theme.of(ctx)
                                    .extension<StackColors>()!
                                    .getPrimaryEnabledButtonStyle(ctx)
                              : Theme.of(ctx)
                                    .extension<StackColors>()!
                                    .getPrimaryDisabledButtonStyle(ctx),
                          onPressed: matches
                              ? () => Navigator.of(ctx).pop(true)
                              : null,
                          child: Text(
                            "Confirm",
                            style: STextStyles.button(ctx),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text("ShopinBit", style: STextStyles.navBarTitle(context)),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.only(left: 12, top: 12, right: 12),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 24,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            RoundedWhiteContainer(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Customer Key",
                                    style: STextStyles.titleBold12(context),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Your customer key identifies you "
                                    "to ShopinBit. Save it to restore "
                                    "access to your conversations on "
                                    "another device. If you change it, "
                                    "you will lose access to existing "
                                    "conversations.",
                                    style: STextStyles.itemSubtitle12(context),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_currentKey != null) ...[
                                    RoundedContainer(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .textFieldDefaultBG,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: SelectableText(
                                              _currentKey!,
                                              style: STextStyles.field(context),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () async {
                                              await Clipboard.setData(
                                                ClipboardData(
                                                  text: _currentKey!,
                                                ),
                                              );
                                              if (mounted) {
                                                unawaited(
                                                  showFloatingFlushBar(
                                                    type: FlushBarType.info,
                                                    message:
                                                        "Key copied to clipboard",
                                                    context: context,
                                                  ),
                                                );
                                              }
                                            },
                                            child: SvgPicture.asset(
                                              Assets.svg.copy,
                                              width: 20,
                                              height: 20,
                                              color: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .textDark3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else
                                    Text(
                                      "No key set",
                                      style: STextStyles.itemSubtitle(context),
                                    ),
                                  const SizedBox(height: 16),
                                  PrimaryButton(
                                    label: _currentKey == null
                                        ? "Generate key"
                                        : "Generate new key",
                                    enabled: !_loading,
                                    onPressed: _generate,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            RoundedWhiteContainer(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Restore key",
                                    style: STextStyles.titleBold12(context),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Enter a previously saved customer "
                                    "key to restore access to your "
                                    "ShopinBit conversations.",
                                    style: STextStyles.itemSubtitle12(context),
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      Constants.size.circularBorderRadius,
                                    ),
                                    child: TextField(
                                      controller: _manualKeyController,
                                      focusNode: _manualKeyFocusNode,
                                      style: STextStyles.field(context),
                                      decoration: standardInputDecoration(
                                        "Enter customer key",
                                        _manualKeyFocusNode,
                                        context,
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  PrimaryButton(
                                    label: "Set key",
                                    enabled:
                                        !_loading &&
                                        _manualKeyController.text
                                            .trim()
                                            .isNotEmpty,
                                    onPressed: _setManualKey,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            RoundedWhiteContainer(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Display Name",
                                    style: STextStyles.titleBold12(context),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "The name ShopinBit staff will see "
                                    "when communicating with you.",
                                    style: STextStyles.itemSubtitle12(context),
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      Constants.size.circularBorderRadius,
                                    ),
                                    child: TextField(
                                      controller: _displayNameController,
                                      focusNode: _displayNameFocusNode,
                                      style: STextStyles.field(context),
                                      decoration: standardInputDecoration(
                                        "Display name",
                                        _displayNameFocusNode,
                                        context,
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  PrimaryButton(
                                    label: "Save",
                                    enabled:
                                        !_savingName &&
                                        _displayNameController.text
                                            .trim()
                                            .isNotEmpty,
                                    onPressed: _saveDisplayName,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
