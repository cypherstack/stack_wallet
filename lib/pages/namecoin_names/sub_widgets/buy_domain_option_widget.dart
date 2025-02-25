import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:namecoin/namecoin.dart';

import '../../../providers/providers.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/constants.dart';
import '../../../utilities/extensions/impl/string.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/show_loading.dart';
import '../../../utilities/text_formatters.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/wallet/impl/namecoin_wallet.dart';
import '../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/dialogs/s_dialog.dart';
import '../../../widgets/rounded_white_container.dart';
import '../../../widgets/stack_dialog.dart';
import '../buy_domain_view.dart';

class BuyDomainOptionWidget extends ConsumerStatefulWidget {
  const BuyDomainOptionWidget({super.key, required this.walletId});

  final String walletId;

  @override
  ConsumerState<BuyDomainOptionWidget> createState() => _BuyDomainWidgetState();
}

class _BuyDomainWidgetState extends ConsumerState<BuyDomainOptionWidget> {
  static const kMaxByteLength = nameMaxLength - 2; // subtract length of "d/"

  final _nameController = TextEditingController();
  final _nameFieldFocus = FocusNode();

  String? get formattedNameInField {
    if (_nameController.text.isNotEmpty) {
      if (_nameController.text.startsWith("d/")) {
        return _nameController.text;
      } else {
        return "d/${_nameController.text}";
      }
    }
    return null;
  }

  bool _isAvailable = false;
  String? _lastLookedUpName;

  bool _lookupLock = false;
  Future<void> _lookup() async {
    if (_lookupLock) return;
    _lookupLock = true;
    try {
      _isAvailable = false;

      _lastLookedUpName = formattedNameInField;
      final result = await showLoading(
        whileFuture:
            (ref.read(pWallets).getWallet(widget.walletId) as NamecoinWallet)
                .lookupName(_lastLookedUpName!),
        context: context,
        message: "Searching...",
        onException: (e) => throw e,
        rootNavigator: Util.isDesktop,
        delay: const Duration(seconds: 2),
      );

      _isAvailable = result?.nameState == NameState.available;

      if (mounted) {
        setState(() {});
      }

      Logging.instance.i("LOOKUP RESULT: $result");
    } catch (e, s) {
      Logging.instance.e("_lookup failed", error: e, stackTrace: s);

      String? err;
      if (e.toString().contains("Contains invalid characters")) {
        err = "Contains invalid characters";
      }

      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => StackOkDialog(
            title: "Name lookup failed",
            message: err,
            desktopPopRootNavigator: Util.isDesktop,
            maxWidth: Util.isDesktop ? 600 : null,
          ),
        );
      }
    } finally {
      _lookupLock = false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFieldFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFieldFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double dotBitBoxLength = Util.isDesktop ? 100 : 74;
    return Column(
      crossAxisAlignment:
          Util.isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textFieldDefaultBG,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(
                        Constants.size.circularBorderRadius,
                      ), // Adjust radius as needed
                      bottomLeft:
                          Radius.circular(Constants.size.circularBorderRadius),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          inputFormatters: [
                            Utf8ByteLengthLimitingTextInputFormatter(
                              kMaxByteLength,
                            ),
                          ],
                          textInputAction: TextInputAction.search,
                          focusNode: _nameFieldFocus,
                          controller: _nameController,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(14),
                              child: SvgPicture.asset(
                                Assets.svg.search,
                                width: 20,
                                height: 20,
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textFieldDefaultSearchIconLeft,
                              ),
                            ),
                            fillColor: Colors.transparent,
                            hintText: "Find a domain name",
                            hintStyle: STextStyles.fieldLabel(context),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          onSubmitted: (_) {
                            if (_nameController.text.isNotEmpty) {
                              _lookup();
                            }
                          },
                          onChanged: (value) {
                            // trigger look up button enabled/disabled state change
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 48,
                width: dotBitBoxLength,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .buttonBackPrimary,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(
                      Constants.size.circularBorderRadius,
                    ), // Adjust radius as needed
                    bottomRight:
                        Radius.circular(Constants.size.circularBorderRadius),
                  ),
                ),
                child: Center(
                  child: Text(
                    ".bit",
                    style: STextStyles.w600_14(context).copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .buttonTextPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: EdgeInsets.only(right: dotBitBoxLength),
              child: Builder(
                builder: (context) {
                  final length =
                      _nameController.text.toUint8ListFromUtf8.lengthInBytes;
                  return Text(
                    "$length/$kMaxByteLength",
                    style: STextStyles.w500_10(context).copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textSubtitle2,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(
          height: Util.isDesktop ? 24 : 16,
        ),
        SecondaryButton(
          label: "Lookup",
          enabled: _nameController.text.isNotEmpty,
          // width: Util.isDesktop ? 160 : double.infinity,
          buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
          onPressed: _lookup,
        ),
        const SizedBox(
          height: 32,
        ),
        if (_lastLookedUpName != null)
          _NameCard(
            walletId: widget.walletId,
            isAvailable: _isAvailable,
            formattedName: _lastLookedUpName!,
          ),
      ],
    );
  }
}

class _NameCard extends ConsumerWidget {
  const _NameCard({
    super.key,
    required this.walletId,
    required this.isAvailable,
    required this.formattedName,
  });

  final String walletId;
  final bool isAvailable;
  final String formattedName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = isAvailable ? "Available" : "Unavailable";
    final color = isAvailable
        ? Theme.of(context).extension<StackColors>()!.accentColorGreen
        : Theme.of(context).extension<StackColors>()!.accentColorRed;

    final style = (Util.isDesktop
        ? STextStyles.w500_16(context)
        : STextStyles.w500_12(context));

    return RoundedWhiteContainer(
      padding: EdgeInsets.all(Util.isDesktop ? 24 : 16),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${formattedName.substring(2)}.bit",
                    style: style,
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    availability,
                    style: style.copyWith(
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                PrimaryButton(
                  label: "Buy domain",
                  enabled: isAvailable,
                  buttonHeight:
                      Util.isDesktop ? ButtonHeight.m : ButtonHeight.l,
                  width: Util.isDesktop ? 140 : 120,
                  onPressed: () async {
                    if (context.mounted) {
                      if (Util.isDesktop) {
                        await showDialog<void>(
                          context: context,
                          builder: (context) => SDialog(
                            child: SizedBox(
                              width: 580,
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 32,
                                        ),
                                        child: Text(
                                          "Buy domain",
                                          style: STextStyles.desktopH3(context),
                                        ),
                                      ),
                                      const DesktopDialogCloseButton(),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                    ),
                                    child: BuyDomainView(
                                      walletId: walletId,
                                      domainName: formattedName,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } else {
                        await Navigator.of(context).pushNamed(
                          BuyDomainView.routeName,
                          arguments: (
                            walletId: walletId,
                            domainName: formattedName
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
