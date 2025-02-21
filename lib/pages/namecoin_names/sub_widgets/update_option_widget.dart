import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/isar/models/blockchain_data/utxo.dart';
import '../../../utilities/barcode_scanner_interface.dart';
import '../../../utilities/clipboard_interface.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/util.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/stack_dialog.dart';

class UpdateOptionWidget extends ConsumerStatefulWidget {
  const UpdateOptionWidget({
    super.key,
    required this.walletId,
    required this.utxo,
    this.clipboard = const ClipboardWrapper(),
    this.barcodeScanner = const BarcodeScannerWrapper(),
  });

  final String walletId;
  final UTXO utxo;

  final ClipboardInterface clipboard;
  final BarcodeScannerInterface barcodeScanner;

  @override
  ConsumerState<UpdateOptionWidget> createState() => _BuyDomainWidgetState();
}

class _BuyDomainWidgetState extends ConsumerState<UpdateOptionWidget> {
  final _nameController = TextEditingController();
  final _nameFieldFocus = FocusNode();

  bool _lookupLock = false;
  Future<void> _lookup() async {
    if (_lookupLock) return;
    _lookupLock = true;
    try {} catch (e, s) {
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          Util.isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: Util.isDesktop ? 24 : 16,
        ),
        SecondaryButton(
          label: "Update",
          enabled: _nameController.text.isNotEmpty,
          // width: Util.isDesktop ? 160 : double.infinity,
          buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
          onPressed: _lookup,
        ),
        SizedBox(
          height: Util.isDesktop ? 24 : 16,
        ),
      ],
    );
  }
}
