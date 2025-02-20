import 'package:flutter/material.dart';

import '../../../../models/namecoin_dns/dns_record.dart';
import '../../../../models/namecoin_dns/dns_record_type.dart';
import '../../../../utilities/util.dart';
import '../name_form_interface.dart';

class TXTForm extends NameFormStatefulWidget {
  const TXTForm({super.key, required super.name});

  @override
  NameFormState<TXTForm> createState() => _TXTFormState();
}

class _TXTFormState extends NameFormState<TXTForm> {
  final _valueController = TextEditingController();

  @override
  DNSRecord buildRecord() {
    return DNSRecord(
      name: widget.name,
      type: DNSRecordType.TXT,
      data: {
        "txt": [_valueController.text.trim()],
      },
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const DNSFieldText(
          "Value",
        ),
        SizedBox(
          height: Util.isDesktop ? 10 : 8,
        ),
        DNSFormField(
          controller: _valueController,
        ),
      ],
    );
  }
}
