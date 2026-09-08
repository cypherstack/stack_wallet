import 'package:flutter/material.dart';

import '../finalize_view/finalize_view.dart';

/// Keeps the old Epic Cash route resolving; the screen is [FinalizeView].
class EpicFinalizeView extends StatelessWidget {
  const EpicFinalizeView({super.key, required this.walletId});

  static const String routeName = "/epicFinalizeView";

  final String walletId;

  @override
  Widget build(BuildContext context) {
    return FinalizeView(walletId: walletId);
  }
}
