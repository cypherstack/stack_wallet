import 'package:flutter/material.dart';
import 'package:grin_native/grin_native.dart' show GrinAddressKind;

import '../../themes/stack_colors.dart';
import '../../utilities/constants.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../../widgets/stack_text_field.dart';

/// Optional address a slatepack send is encrypted to.
class SlatepackRecipientField extends StatefulWidget {
  const SlatepackRecipientField({
    super.key,
    required this.controller,
    required this.coin,
    this.label = "Recipient address (optional)",
    this.help =
        "The Slatepack is encrypted to this address and a payment proof is "
        "requested. Leave empty to hand out a plain Slatepack.",
  });

  final TextEditingController controller;
  final CryptoCurrency coin;
  final String label;
  final String help;

  /// Empty, or an address the coin accepts.
  static bool isAcceptable(CryptoCurrency coin, String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ||
        (coin is Grin
            ? coin.addressKind(trimmed) == GrinAddressKind.slatepack
            : coin.validateAddress(trimmed));
  }

  @override
  State<SlatepackRecipientField> createState() =>
      _SlatepackRecipientFieldState();
}

class _SlatepackRecipientFieldState extends State<SlatepackRecipientField> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final colors = Theme.of(context).extension<StackColors>()!;
    final valid = SlatepackRecipientField.isAcceptable(
      widget.coin,
      widget.controller.text,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
          child: TextField(
            key: const Key("slatepackRecipientFieldKey"),
            controller: widget.controller,
            focusNode: _focusNode,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) => setState(() {}),
            style: isDesktop
                ? STextStyles.desktopTextExtraSmall(context)
                      .copyWith(color: colors.textFieldActiveText, height: 1.8)
                : STextStyles.field(context),
            decoration: standardInputDecoration(
              widget.label,
              _focusNode,
              context,
              desktopMed: true,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          valid ? widget.help : "Not a ${widget.coin.prettyName} address.",
          style: STextStyles.label(context)
              .copyWith(color: valid ? colors.textSubtitle1 : colors.textError),
        ),
      ],
    );
  }
}
