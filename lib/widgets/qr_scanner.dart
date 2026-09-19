import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import '../themes/stack_colors.dart';
import '../utilities/if_not_already.dart';
import '../utilities/text_styles.dart';
import 'background.dart';
import 'custom_buttons/app_bar_icon_button.dart';

class QrScanner extends StatefulWidget {
  const QrScanner({super.key});

  @override
  State<QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: "QR Scan Key");

  QRViewController? controller;

  StreamSubscription<Barcode>? sub;

  late final Future<void> Function(String?) _onScanned;

  @override
  void initState() {
    super.initState();

    _onScanned = IfNotAlreadyAsync<String>.withArgs((data) async {
      await sub?.cancel();
      if (mounted) {
        Navigator.of(context).pop(data);
      }
    }).execute;
  }

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          backgroundColor: Theme.of(
            context,
          ).extension<StackColors>()!.backgroundAppBar,
          leading: const AppBarBackButton(),
          title: Text("Scan QR code", style: STextStyles.navBarTitle(context)),
        ),
        body: QRView(
          key: qrKey,
          onQRViewCreated: (QRViewController p1) {
            sub?.cancel();
            controller = p1;
            sub = controller!.scannedDataStream.listen((data) {
              _onScanned(data.code);
            });
          },
        ),
      ),
    );
  }
}
