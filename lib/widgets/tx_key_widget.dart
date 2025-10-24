import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/pinpad_views/pinpad_dialog.dart';
import '../pages/wallet_view/transaction_views/tx_v2/transaction_v2_details_view.dart'
    as tvd;
import '../pages_desktop_specific/password/request_desktop_auth_dialog.dart';
import '../providers/global/wallets_provider.dart';
import '../utilities/text_styles.dart';
import '../utilities/util.dart';
import '../wallets/wallet/intermediate/lib_monero_wallet.dart';
import 'custom_buttons/blue_text_button.dart';
import 'custom_buttons/simple_copy_button.dart';
import 'detail_item.dart';

class TxKeyWidget extends ConsumerStatefulWidget {
  /// The [walletId] MUST be the id of a [LibMoneroWallet]!
  const TxKeyWidget({super.key, required this.walletId, required this.txid});

  final String walletId;
  final String txid;

  @override
  ConsumerState<TxKeyWidget> createState() => _TxKeyWidgetState();
}

class _TxKeyWidgetState extends ConsumerState<TxKeyWidget> {
  String? _private;

  bool _lock = false;

  Future<void> _loadTxKey() async {
    if (_lock) {
      return;
    }
    _lock = true;

    try {
      final verified = await showDialog<String?>(
        context: context,
        builder:
            (context) =>
                Util.isDesktop
                    ? const RequestDesktopAuthDialog(
                      title: "Show private view key",
                    )
                    : const PinpadDialog(
                      biometricsAuthenticationTitle: "Show private view key",
                      biometricsLocalizedReason:
                          "Authenticate to show private view key",
                      biometricsCancelButtonString: "CANCEL",
                    ),
        barrierDismissible: !Util.isDesktop,
      );

      if (verified == "verified success" && mounted) {
        final wallet =
            ref.read(pWallets).getWallet(widget.walletId) as LibMoneroWallet;

        _private = wallet.getTxKeyFor(txid: widget.txid);
        if (_private!.isEmpty) {
          _private = "Unavailable";
        }

        if (context.mounted) {
          setState(() {});
        } else {
          _private == null;
        }
      }
    } finally {
      _lock = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DetailItemBase(
      button:
          _private == null
              ? CustomTextButton(
                text: "Show",
                onTap: _loadTxKey,
                enabled: _private == null,
              )
              : Util.isDesktop
              ? tvd.IconCopyButton(data: _private!)
              : SimpleCopyButton(data: _private!),
      title: Text("Private view key", style: STextStyles.itemSubtitle(context)),
      detail: SelectableText(
        // TODO
        _private ?? "*" * 52, // 52 is approx length
        style: STextStyles.w500_14(context),
      ),
    );
  }
}
