import 'package:flutter/material.dart';

import '../../../models/slatepack_models.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/text_styles.dart';
import '../../../widgets/custom_buttons/checkbox_text_button.dart';
import '../../../widgets/rounded_container.dart';

/// Transport warnings for a direct send on the confirm screen. A blocked
/// send shows the reason; the IP disclosure and plain http:// warnings each
/// need a tick before [allows] is true.
class SlatepackTransportWarnings extends StatelessWidget {
  const SlatepackTransportWarnings({
    super.key,
    required this.policy,
    required this.onClearnetAck,
    required this.onPlaintextAck,
  });

  final SlatepackHttpPolicy policy;
  final void Function(bool) onClearnetAck;
  final void Function(bool) onPlaintextAck;

  static bool allows(
    SlatepackHttpPolicy? policy, {
    required bool clearnetAck,
    required bool plaintextAck,
  }) {
    if (policy == null) return true;
    if (policy.isBlocked) return false;
    if (policy.needsClearnetAck && !clearnetAck) return false;
    if (policy.needsPlaintextAck && !plaintextAck) return false;
    return true;
  }

  Widget _box(
    BuildContext context, {
    required bool error,
    required Widget child,
  }) {
    final colors = Theme.of(context).extension<StackColors>()!;
    return RoundedContainer(
      color: error ? colors.textFieldErrorBG : colors.warningBackground,
      child: child,
    );
  }

  Widget _text(BuildContext context, String text, {required bool error}) {
    final colors = Theme.of(context).extension<StackColors>()!;
    return Text(
      text,
      style: STextStyles.smallMed12(context)
          .copyWith(color: error ? colors.textError : colors.warningForeground),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (policy.isBlocked) {
      return _box(
        context,
        error: true,
        child: _text(
          context,
          "${policy.blockedReason} This send cannot go ahead.",
          error: true,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (policy.needsClearnetAck)
          _box(
            context,
            error: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _text(
                  context,
                  "Tor is off. The recipient's wallet, and anyone watching "
                  "the connection, will see your IP address.",
                  error: false,
                ),
                const SizedBox(height: 8),
                CheckboxTextButton(
                  key: const Key("slatepackClearnetAck"),
                  label: "Send without Tor and reveal my IP address",
                  onChanged: onClearnetAck,
                ),
              ],
            ),
          ),
        if (policy.needsClearnetAck && policy.needsPlaintextAck)
          const SizedBox(height: 8),
        if (policy.needsPlaintextAck)
          _box(
            context,
            error: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _text(
                  context,
                  "This address uses unencrypted http://. Anyone on the path, "
                  "including a Tor exit relay, can read and change the "
                  "transaction data.",
                  error: false,
                ),
                const SizedBox(height: 8),
                CheckboxTextButton(
                  key: const Key("slatepackPlaintextAck"),
                  label: "Send over unencrypted http:// anyway",
                  onChanged: onPlaintextAck,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
