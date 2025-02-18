import 'package:flutter/material.dart';

import '../../../../models/namecoin_dns/dns_record.dart';
import '../../../../models/namecoin_dns/dns_record_type.dart';
import '../../../../utilities/util.dart';
import '../name_form_interface.dart';

class SRVForm extends NameFormStatefulWidget {
  const SRVForm({super.key});

  @override
  NameFormState<SRVForm> createState() => _SRVFormState();
}

class _SRVFormState extends NameFormState<SRVForm> {
  final _priorityController = TextEditingController();
  final _weightController = TextEditingController();
  final _portController = TextEditingController();
  final _hostController = TextEditingController();

  @override
  DNSRecord buildRecord() {
    return DNSRecord(
      type: DNSRecordType.SRV,
      data: {
        "srv": [
          [
            int.parse(_priorityController.text.trim()),
            int.parse(_weightController.text.trim()),
            int.parse(_portController.text.trim()),
            _hostController.text.trim(),
          ],
        ],
      },
    );
  }

  @override
  void dispose() {
    _priorityController.dispose();
    _weightController.dispose();
    _portController.dispose();
    _hostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const DNSFieldText(
          "Priority",
        ),
        SizedBox(
          height: Util.isDesktop ? 10 : 8,
        ),
        DNSFormField(
          controller: _priorityController,
          keyboardType: TextInputType.number,
        ),
        SizedBox(
          height: Util.isDesktop ? 24 : 16,
        ),
        const DNSFieldText(
          "Weight",
        ),
        SizedBox(
          height: Util.isDesktop ? 10 : 8,
        ),
        DNSFormField(
          controller: _weightController,
          keyboardType: TextInputType.number,
        ),
        SizedBox(
          height: Util.isDesktop ? 24 : 16,
        ),
        const DNSFieldText(
          "Port",
        ),
        SizedBox(
          height: Util.isDesktop ? 10 : 8,
        ),
        DNSFormField(
          controller: _portController,
          keyboardType: TextInputType.number,
        ),
        SizedBox(
          height: Util.isDesktop ? 24 : 16,
        ),
        const DNSFieldText(
          "Host",
        ),
        SizedBox(
          height: Util.isDesktop ? 10 : 8,
        ),
        DNSFormField(
          controller: _hostController,
        ),
      ],
    );
  }
}
