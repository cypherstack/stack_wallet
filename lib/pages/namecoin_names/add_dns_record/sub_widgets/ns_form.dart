import 'package:flutter/material.dart';

import '../../../../models/namecoin_dns/dns_record.dart';
import '../../../../models/namecoin_dns/dns_record_type.dart';
import '../../../../utilities/util.dart';
import '../name_form_interface.dart';

class NSForm extends NameFormStatefulWidget {
  const NSForm({super.key});

  @override
  NameFormState<NSForm> createState() => _NSFormState();
}

class _NSFormState extends NameFormState<NSForm> {
  final _serverController = TextEditingController();

  @override
  DNSRecord buildRecord() {
    final address = _serverController.text.trim();

    return DNSRecord(
      type: DNSRecordType.NS,
      data: {
        "ns": [address],
      },
    );
  }

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const DNSFieldText(
          "Nameserver",
        ),
        SizedBox(
          height: Util.isDesktop ? 10 : 8,
        ),
        DNSFormField(
          controller: _serverController,
        ),
      ],
    );
  }
}
