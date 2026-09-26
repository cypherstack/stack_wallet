import 'dart:async';

import 'package:flutter/material.dart';

import 'sensitive_wallet_content.dart';

void main() {
  SensitiveWalletContent.hostFiltered = const bool.fromEnvironment(
    'HOST_FILTERED',
  );
  runApp(const MaterialApp(home: Probe()));
}

class Probe extends StatefulWidget {
  const Probe({super.key});
  @override
  State<Probe> createState() => _ProbeState();
}

class _ProbeState extends State<Probe> {
  final controller = TextEditingController(text: 'private-probe-0');
  Timer? timer;
  int count = 0;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      controller.text = 'private-probe-${++count}';
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        const Text('public-probe'),
        const SensitiveWalletContent(child: Text('seed-probe')),
        SensitiveWalletContent(
          child: TextField(controller: controller, autofocus: true),
        ),
      ],
    ),
  );
}
