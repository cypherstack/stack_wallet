import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../notifications/show_flush_bar.dart';
import '../../providers/global/shopin_bit_service_provider.dart';
import '../../providers/providers.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/rounded_container.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_dialog.dart';
import '../../widgets/textfields/adaptive_text_field.dart';

class ShopInBitSettingsView extends ConsumerStatefulWidget {
  const ShopInBitSettingsView({super.key});

  static const String routeName = "/shopInBitSettings";

  @override
  ConsumerState<ShopInBitSettingsView> createState() =>
      _ShopInBitSettingsViewState();
}

class _ShopInBitSettingsViewState extends ConsumerState<ShopInBitSettingsView> {
  final _manualKeyController = TextEditingController();
  final _verifyKeyController = TextEditingController();
  final _displayNameController = TextEditingController();

  String? _currentKey;
  bool _loading = false;
  bool _savingName = false;

  @override
  void initState() {
    super.initState();

    // not the greatest solution but its the least invasive with the current
    // ui code impl
    () async {
      final settings = await ref
          .read(pSharedDrift)
          .shopinBitSettingsDao
          .getSettings();
      final key = await ref.read(pShopinBitService).loadCustomerKey();
      if (mounted) {
        setState(() {
          _currentKey = key;
          _displayNameController.text = settings.displayName ?? "";
        });
      }
    }();
  }

  @override
  void dispose() {
    _manualKeyController.dispose();
    _verifyKeyController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _saveDisplayName() async {
    final name = _displayNameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _savingName = true);
    try {
      await ref.read(pSharedDrift).shopinBitSettingsDao.setDisplayName(name);
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
        final resp = await ref.read(pShopinBitService).client.generateKey();
        key = resp.valueOrThrow;
        await ref.read(pShopinBitService).setCustomerKey(key);
      } else {
        key = await ref.read(pShopinBitService).ensureCustomerKey();
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
      await ref.read(pShopinBitService).setCustomerKey(newKey);
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
      builder: (context) {
        // TODO: this conditional can probably be merged when we have time
        if (Util.isDesktop) {
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
                        "Save your current key",
                        style: STextStyles.desktopH3(context),
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
                        "Your current customer key is:",
                        style: STextStyles.desktopTextExtraExtraSmall(context),
                      ),
                      const SizedBox(height: 8),
                      RoundedWhiteContainer(
                        borderColor: Theme.of(
                          context,
                        ).extension<StackColors>()!.textSubtitle6,
                        child: SelectableText(
                          _currentKey!,
                          style: STextStyles.desktopTextSmall(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Changing your key will disconnect you from "
                        "existing ShopinBit requests. Make sure "
                        "you have saved your current key before "
                        "proceeding.",
                        style: STextStyles.desktopTextExtraExtraSmall(context),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              label: "Cancel",
                              buttonHeight: ButtonHeight.l,
                              onPressed: () => Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pop(false),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: PrimaryButton(
                              label: "I saved my key",
                              buttonHeight: ButtonHeight.l,
                              onPressed: () => Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pop(null),
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
        } else {
          return StackDialogBase(
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
          );
        }
      },
    );

    if (result == false || !mounted) return false;

    return _showVerifyDialog();
  }

  Future<bool?> _showVerifyDialog() async {
    _verifyKeyController.clear();
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final matches = _verifyKeyController.text.trim() == _currentKey;

            // TODO: this conditional can probably be merged when we have time
            if (Util.isDesktop) {
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
                          AdaptiveTextField(
                            labelText: "Enter current key",
                            controller: _verifyKeyController,
                            onChangedComprehensive: (_) =>
                                setDialogState(() {}),
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
            } else {
              return StackDialogBase(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Verify your key",
                      style: STextStyles.pageTitleH2(ctx),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Enter your current customer key to "
                      "confirm you have saved it.",
                      style: STextStyles.smallMed14(ctx),
                    ),
                    const SizedBox(height: 16),
                    AdaptiveTextField(
                      labelText: "Enter current key",
                      controller: _verifyKeyController,
                      onChangedComprehensive: (_) => setDialogState(() {}),
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
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: this conditional can probably be merged when we have time
    if (Util.isDesktop) {
      return SingleChildScrollView(
        child: Column(
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
                            "Your customer key identifies you to ShopinBit. "
                            "Save it to restore access to your conversations "
                            "on another device. If you change it, you will "
                            "lose access to existing conversations.",
                            style: STextStyles.desktopTextExtraExtraSmall(
                              context,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_currentKey != null) ...[
                            Text(
                              "Current key",
                              style:
                                  STextStyles.desktopTextExtraExtraSmall(
                                    context,
                                  ).copyWith(
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
                                    if (context.mounted) {
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
                          const SizedBox(height: 20),
                          Text(
                            "Restore key",
                            style: STextStyles.desktopTextSmall(context),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Enter a previously saved customer key to "
                            "restore access to your ShopinBit "
                            "conversations.",
                            style: STextStyles.desktopTextExtraExtraSmall(
                              context,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 512,
                            child: AdaptiveTextField(
                              labelText: "Enter customer key",
                              controller: _manualKeyController,
                              onChangedComprehensive: (_) => setState(() {}),
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
                          const SizedBox(height: 20),
                          Text(
                            "Display Name",
                            style: STextStyles.desktopTextSmall(context),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "The name ShopinBit staff will see "
                            "when communicating with you.",
                            style: STextStyles.desktopTextExtraExtraSmall(
                              context,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 512,
                            child: AdaptiveTextField(
                              labelText: "Display name",
                              controller: _displayNameController,
                              onChangedComprehensive: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            width: 210,
                            buttonHeight: ButtonHeight.m,
                            enabled:
                                !_savingName &&
                                _displayNameController.text.trim().isNotEmpty,
                            label: "Save",
                            onPressed: _saveDisplayName,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Background(
        child: Scaffold(
          backgroundColor: Theme.of(
            context,
          ).extension<StackColors>()!.background,
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
                                      style: STextStyles.itemSubtitle12(
                                        context,
                                      ),
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
                                                style: STextStyles.field(
                                                  context,
                                                ),
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
                                        style: STextStyles.itemSubtitle(
                                          context,
                                        ),
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
                                      style: STextStyles.itemSubtitle12(
                                        context,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    AdaptiveTextField(
                                      labelText: "Enter customer key",
                                      controller: _manualKeyController,
                                      onChangedComprehensive: (_) =>
                                          setState(() {}),
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
                                      style: STextStyles.itemSubtitle12(
                                        context,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    AdaptiveTextField(
                                      labelText: "Display name",
                                      controller: _displayNameController,
                                      onChangedComprehensive: (_) =>
                                          setState(() {}),
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
}
