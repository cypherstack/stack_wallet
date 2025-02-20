import 'package:flutter/material.dart';

import '../../../../models/namecoin_dns/dns_record.dart';
import '../../../../models/namecoin_dns/dns_record_type.dart';
import '../../../../utilities/util.dart';
import '../name_form_interface.dart';

class TLSForm extends NameFormStatefulWidget {
  const TLSForm({super.key, required super.name});

  @override
  NameFormState<TLSForm> createState() => _TLSFormState();
}

class _TLSFormState extends NameFormState<TLSForm> {
  final _pubkeyController = TextEditingController();

  @override
  DNSRecord buildRecord() {
    return DNSRecord(
      name: widget.name,
      type: DNSRecordType.TLS,
      data: {
        "map": {
          "*": {
            "tls": [
              [
                2,
                1,
                0,
                _pubkeyController.text.trim(),
              ],
            ],
          },
        },
      },
    );
  }

  @override
  void dispose() {
    _pubkeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const DNSFieldText(
          "DANE-TA public key (base64)",
        ),
        SizedBox(
          height: Util.isDesktop ? 10 : 8,
        ),
        DNSFormField(
          controller: _pubkeyController,
        ),
      ],
    );
  }
}
