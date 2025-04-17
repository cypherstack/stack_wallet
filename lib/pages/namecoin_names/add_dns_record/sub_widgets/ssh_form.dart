import 'package:flutter/material.dart';

import '../../../../models/namecoin_dns/dns_record.dart';
import '../../../../models/namecoin_dns/dns_record_type.dart';
import '../../../../utilities/util.dart';
import '../name_form_interface.dart';

class SSHForm extends NameFormStatefulWidget {
  const SSHForm({super.key, required super.name});

  @override
  NameFormState<SSHForm> createState() => _SSHFormState();
}

class _SSHFormState extends NameFormState<SSHForm> {
  final _algoController = TextEditingController();
  final _fingerprintTypeController = TextEditingController();
  final _fingerprintController = TextEditingController();

  @override
  DNSRecord buildRecord() {
    return DNSRecord(
      name: widget.name,
      type: DNSRecordType.SSH,
      data: {
        "sshfp": [
          [
            int.parse(_algoController.text.trim()),
            int.parse(_fingerprintTypeController.text.trim()),
            _fingerprintController.text.trim(),
          ],
        ],
      },
    );
  }

  @override
  void dispose() {
    _algoController.dispose();
    _fingerprintTypeController.dispose();
    _fingerprintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const DNSFieldText(
          "Algorithm",
        ),
        SizedBox(
          height: Util.isDesktop ? 10 : 8,
        ),
        DNSFormField(
          controller: _algoController,
          keyboardType: TextInputType.number,
        ),
        SizedBox(
          height: Util.isDesktop ? 24 : 16,
        ),
        const DNSFieldText(
          "Fingerprint type",
        ),
        SizedBox(
          height: Util.isDesktop ? 10 : 8,
        ),
        DNSFormField(
          controller: _fingerprintTypeController,
          keyboardType: TextInputType.number,
        ),
        SizedBox(
          height: Util.isDesktop ? 24 : 16,
        ),
        const DNSFieldText(
          "Fingerprint (base64)",
        ),
        SizedBox(
          height: Util.isDesktop ? 10 : 8,
        ),
        DNSFormField(
          controller: _fingerprintController,
        ),
      ],
    );
  }
}
