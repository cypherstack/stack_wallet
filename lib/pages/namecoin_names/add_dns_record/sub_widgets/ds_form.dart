import 'package:flutter/material.dart';

import '../../../../models/namecoin_dns/dns_record.dart';
import '../../../../models/namecoin_dns/dns_record_type.dart';
import '../../../../utilities/util.dart';
import '../name_form_interface.dart';

class DSForm extends NameFormStatefulWidget {
  const DSForm({super.key, required super.name});

  @override
  NameFormState<DSForm> createState() => _DSFormState();
}

class _DSFormState extends NameFormState<DSForm> {
  final _keytagController = TextEditingController();
  final _algoController = TextEditingController();
  final _typeController = TextEditingController();
  final _hashController = TextEditingController();

  @override
  DNSRecord buildRecord() {
    return DNSRecord(
      name: widget.name,
      type: DNSRecordType.DS,
      data: {
        "ds": [
          [
            int.parse(_keytagController.text.trim()),
            int.parse(_algoController.text.trim()),
            int.parse(_typeController.text.trim()),
            _hashController.text.trim(),
          ],
        ],
      },
    );
  }

  @override
  void dispose() {
    _keytagController.dispose();
    _algoController.dispose();
    _typeController.dispose();
    _hashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const DNSFieldText(
          "Keytag",
        ),
        SizedBox(
          height: Util.isDesktop ? 10 : 8,
        ),
        DNSFormField(
          controller: _keytagController,
          keyboardType: TextInputType.number,
        ),
        SizedBox(
          height: Util.isDesktop ? 24 : 16,
        ),
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
          "Hash type",
        ),
        SizedBox(
          height: Util.isDesktop ? 10 : 8,
        ),
        DNSFormField(
          controller: _typeController,
          keyboardType: TextInputType.number,
        ),
        SizedBox(
          height: Util.isDesktop ? 24 : 16,
        ),
        const DNSFieldText(
          "Hash (base64)",
        ),
        SizedBox(
          height: Util.isDesktop ? 10 : 8,
        ),
        DNSFormField(
          controller: _hashController,
        ),
      ],
    );
  }
}
