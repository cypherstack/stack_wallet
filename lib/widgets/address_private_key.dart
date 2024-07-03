import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/isar/models/isar_models.dart';
import '../providers/global/wallets_provider.dart';
import '../utilities/show_loading.dart';
import '../utilities/text_styles.dart';
import '../utilities/util.dart';
import '../wallets/wallet/intermediate/bip39_hd_wallet.dart';
import 'custom_buttons/blue_text_button.dart';
import 'detail_item.dart';

class AddressPrivateKey extends ConsumerStatefulWidget {
  /// The [walletId] MUST be the id of a [Bip39HDWallet]!
  const AddressPrivateKey({
    super.key,
    required this.walletId,
    required this.address,
  });

  final String walletId;
  final Address address;

  @override
  ConsumerState<AddressPrivateKey> createState() => _AddressPrivateKeyState();
}

class _AddressPrivateKeyState extends ConsumerState<AddressPrivateKey> {
  String? _private;

  bool _lock = false;

  Future<void> _loadPrivKey() async {
    // sanity check that should never actually fail in practice.
    // Big problems if it actually does though so we check and crash if it fails.
    assert(widget.walletId == widget.address.walletId);

    if (_lock) {
      return;
    }
    _lock = true;

    try {
      final wallet =
          ref.read(pWallets).getWallet(widget.walletId) as Bip39HDWallet;

      _private = await showLoading(
        whileFuture: wallet.getPrivateKeyWIF(widget.address),
        context: context,
        message: "Loading...",
        delay: const Duration(milliseconds: 800),
        rootNavigator: Util.isDesktop,
      );

      if (context.mounted) {
        setState(() {});
      } else {
        _private == null;
      }
    } finally {
      _lock = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DetailItemBase(
      button: CustomTextButton(
        text: "Show",
        onTap: _loadPrivKey,
        enabled: _private == null,
      ),
      title: Text(
        "Private key",
        style: STextStyles.itemSubtitle(context),
      ),
      detail: SelectableText(
        _private ?? "*" * 52, // 52 is approx length
        style: STextStyles.w500_14(context),
      ),
    );
  }
}
