import 'package:flutter/material.dart';

import '../../../../models/namecoin_dns/dns_record.dart';
import '../../../../models/namecoin_dns/dns_record_type.dart';
import '../../../../utilities/util.dart';
import '../name_form_interface.dart';

class CNAMEForm extends NameFormStatefulWidget {
  const CNAMEForm({super.key, required super.name});

  @override
  NameFormState<CNAMEForm> createState() => _CNAMEFormState();
}

class _CNAMEFormState extends NameFormState<CNAMEForm> {
  final _aliasController = TextEditingController();

  @override
  DNSRecord buildRecord() {
    final address = _aliasController.text.trim();

    return DNSRecord(
      name: widget.name,
      type: DNSRecordType.CNAME,
      data: {"alias": address},
    );
  }

  @override
  void dispose() {
    _aliasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const DNSFieldText(
          "Alias of",
        ),
        SizedBox(
          height: Util.isDesktop ? 10 : 8,
        ),
        DNSFormField(
          controller: _aliasController,
        ),
      ],
    );
  }
}
