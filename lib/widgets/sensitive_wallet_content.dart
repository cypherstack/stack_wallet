import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Hides [child] from all Android accessibility services, screen readers
/// included. No-op once MainActivity's API 34+ host filtering applies.
class SensitiveWalletContent extends StatelessWidget {
  const SensitiveWalletContent({
    super.key,
    required this.child,
    this.sensitive = true,
  });

  /// Set at startup when the Android host view is accessibility-data-sensitive.
  static bool hostFiltered = false;

  final Widget child;
  final bool sensitive;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        hostFiltered) {
      return child;
    }
    // Same tree shape either way so toggling [sensitive] keeps child state.
    return Semantics(
      container: sensitive,
      label: sensitive ? "Hidden from accessibility services" : null,
      child: ExcludeSemantics(excluding: sensitive, child: child),
    );
  }
}
