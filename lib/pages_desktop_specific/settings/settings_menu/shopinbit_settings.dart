import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../../notifications/show_flush_bar.dart';
import '../../../services/shopinbit/shopinbit_service.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/constants.dart';
import '../../../utilities/text_styles.dart';
import '../../../widgets/desktop/desktop_dialog.dart';
import '../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/rounded_white_container.dart';
import '../../../widgets/stack_text_field.dart';

class ShopInBitDesktopSettings extends ConsumerStatefulWidget {
  const ShopInBitDesktopSettings({super.key});

  static const String routeName = "/settingsMenuShopInBit";

  @override
  ConsumerState<ShopInBitDesktopSettings> createState() =>
      _ShopInBitDesktopSettingsState();
}

class _ShopInBitDesktopSettingsState
    extends ConsumerState<ShopInBitDesktopSettings> {
  final _manualKeyController = TextEditingController();
  final _manualKeyFocusNode = FocusNode();
  final _verifyKeyController = TextEditingController();
  final _verifyKeyFocusNode = FocusNode();

  String? _currentKey;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _currentKey = ShopInBitService.instance.loadCustomerKey();
  }

  @override
  void dispose() {
    _manualKeyController.dispose();
    _manualKeyFocusNode.dispose();
    _verifyKeyController.dispose();
    _verifyKeyFocusNode.dispose();
    super.dispose();
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
      builder: (ctx) => DesktopDialog(
        maxWidth: 550,
        maxHeight: double.infinity,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    "Save your current key",
                    style: STextStyles.desktopH3(ctx),
                  ),
                ),
                const DesktopDialogCloseButton(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32, right: 32, bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your current customer key is:",
                    style: STextStyles.desktopTextExtraExtraSmall(ctx),
                  ),
                  const SizedBox(height: 8),
                  RoundedWhiteContainer(
                    borderColor: Theme.of(
                      ctx,
                    ).extension<StackColors>()!.textSubtitle6,
                    child: SelectableText(
                      _currentKey!,
                      style: STextStyles.desktopTextSmall(ctx),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Changing your key will disconnect you from "
                    "existing ShopInBit conversations. Make sure "
                    "you have saved your current key before "
                    "proceeding.",
                    style: STextStyles.desktopTextExtraExtraSmall(ctx),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: "Cancel",
                          buttonHeight: ButtonHeight.l,
                          onPressed: () =>
                              Navigator.of(ctx, rootNavigator: true).pop(false),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: PrimaryButton(
                          label: "I saved my key",
                          buttonHeight: ButtonHeight.l,
                          onPressed: () =>
                              Navigator.of(ctx, rootNavigator: true).pop(null),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
            return DesktopDialog(
              maxWidth: 550,
              maxHeight: double.infinity,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          "Verify your key",
                          style: STextStyles.desktopH3(ctx),
                        ),
                      ),
                      const DesktopDialogCloseButton(),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 32,
                      right: 32,
                      bottom: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Enter your current customer key to "
                          "confirm you have saved it.",
                          style: STextStyles.desktopTextExtraExtraSmall(ctx),
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
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                label: "Cancel",
                                buttonHeight: ButtonHeight.l,
                                onPressed: () => Navigator.of(
                                  ctx,
                                  rootNavigator: true,
                                ).pop(false),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: PrimaryButton(
                                label: "Confirm",
                                buttonHeight: ButtonHeight.l,
                                enabled: matches,
                                onPressed: () => Navigator.of(
                                  ctx,
                                  rootNavigator: true,
                                ).pop(true),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 30),
          child: RoundedWhiteContainer(
            radiusMultiplier: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset(
                    Assets.svg.key,
                    width: 48,
                    height: 48,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Customer Key",
                        style: STextStyles.desktopTextSmall(context),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Your customer key identifies you to ShopInBit. "
                        "Save it to restore access to your conversations "
                        "on another device. If you change it, you will "
                        "lose access to existing conversations.",
                        style: STextStyles.desktopTextExtraExtraSmall(context),
                      ),
                      const SizedBox(height: 20),
                      if (_currentKey != null) ...[
                        Text(
                          "Current key",
                          style: STextStyles.desktopTextExtraExtraSmall(context)
                              .copyWith(
                                color: Theme.of(
                                  context,
                                ).extension<StackColors>()!.textDark3,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            SelectableText(
                              _currentKey!,
                              style: STextStyles.desktopTextSmall(context),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: _currentKey!),
                                );
                                if (mounted) {
                                  unawaited(
                                    showFloatingFlushBar(
                                      type: FlushBarType.info,
                                      message: "Key copied to clipboard",
                                      context: context,
                                    ),
                                  );
                                }
                              },
                              child: SvgPicture.asset(
                                Assets.svg.copy,
                                width: 20,
                                height: 20,
                                color: Theme.of(
                                  context,
                                ).extension<StackColors>()!.textDark3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(
                            "No key set",
                            style: STextStyles.desktopTextExtraExtraSmall(
                              context,
                            ),
                          ),
                        ),
                      PrimaryButton(
                        width: 210,
                        buttonHeight: ButtonHeight.m,
                        enabled: !_loading,
                        label: _currentKey == null
                            ? "Generate key"
                            : "Generate new key",
                        onPressed: _generate,
                      ),
                      const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Divider(thickness: 0.5),
                      ),
                      Text(
                        "Restore key",
                        style: STextStyles.desktopTextSmall(context),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Enter a previously saved customer key to "
                        "restore access to your ShopInBit "
                        "conversations.",
                        style: STextStyles.desktopTextExtraExtraSmall(context),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 512,
                        child: ClipRRect(
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
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        width: 210,
                        buttonHeight: ButtonHeight.m,
                        enabled:
                            !_loading &&
                            _manualKeyController.text.trim().isNotEmpty,
                        label: "Set key",
                        onPressed: _setManualKey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
