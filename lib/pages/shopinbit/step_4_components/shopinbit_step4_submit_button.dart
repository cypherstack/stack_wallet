import "package:flutter/material.dart";

import "../../../widgets/desktop/primary_button.dart";

class ShopInBitStep4SubmitButton extends StatelessWidget {
  const ShopInBitStep4SubmitButton({
    super.key,
    required this.submitting,
    required this.enabled,
    required this.onPressed,
  });

  final bool submitting;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: submitting ? "Submitting..." : "Submit request",
      enabled: enabled,
      onPressed: enabled ? onPressed : null,
    );
  }
}
