import 'package:flutter/material.dart';

import '../../../../models/namecoin_dns/dns_record.dart';
import '../../../../models/namecoin_dns/dns_record_type.dart';
import '../../../../utilities/util.dart';
import '../name_form_interface.dart';

class IMPORTForm extends NameFormStatefulWidget {
  const IMPORTForm({super.key});

  @override
  NameFormState<IMPORTForm> createState() => _IMPORTFormState();
}

class _IMPORTFormState extends NameFormState<IMPORTForm> {
  final _nameController = TextEditingController();
  final _subdomainController = TextEditingController();

  @override
  DNSRecord buildRecord() {
    return DNSRecord(
      type: DNSRecordType.IMPORT,
      data: {
        "import": [
          [
            _nameController.text.trim(),
            if (_subdomainController.text.trim().isNotEmpty)
              _subdomainController.text.trim(),
          ],
        ],
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subdomainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const DNSFieldText(
          "Namecoin name",
        ),
        SizedBox(
          height: Util.isDesktop ? 10 : 8,
        ),
        DNSFormField(
          controller: _nameController,
        ),
        const DNSFieldText(
          "Subdomain (optional)",
        ),
        SizedBox(
          height: Util.isDesktop ? 10 : 8,
        ),
        DNSFormField(
          controller: _subdomainController,
        ),
      ],
    );
  }
}
