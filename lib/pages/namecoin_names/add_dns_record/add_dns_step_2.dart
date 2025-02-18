import 'package:flutter/material.dart';

import '../../../models/namecoin_dns/dns_record_type.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/stack_dialog.dart';
import 'name_form_interface.dart';
import 'sub_widgets/a_form.dart';
import 'sub_widgets/cname_form.dart';
import 'sub_widgets/ds_form.dart';
import 'sub_widgets/import_form.dart';
import 'sub_widgets/ns_form.dart';
import 'sub_widgets/srv_form.dart';
import 'sub_widgets/ssh_form.dart';
import 'sub_widgets/tls_form.dart';
import 'sub_widgets/txt_form.dart';

class AddDnsStep2 extends StatefulWidget {
  const AddDnsStep2({super.key, required this.recordType});
  final DNSRecordType recordType;

  @override
  State<AddDnsStep2> createState() => _AddDnsStep2State();
}

class _AddDnsStep2State extends State<AddDnsStep2> {
  final GlobalKey<NameFormState> _formStateKey = GlobalKey();

  bool _nextLock = false;
  void _nextPressed() {
    if (_nextLock) return;
    _nextLock = true;
    try {
      final record = _formStateKey.currentState!.buildRecord();
      Navigator.of(context, rootNavigator: true).pop(
        record,
      );
    } catch (e, s) {
      Logging.instance.e(
        runtimeType,
        error: e,
        stackTrace: s,
      );

      final String err;
      switch (e.runtimeType) {
        case const (ArgumentError):
          err = e.toString().replaceFirst(
                "Invalid Arguments(s): ",
                "",
              );

        case const (Exception):
          err = e.toString().replaceFirst(
                "Exception: ",
                "",
              );

        default:
          err = e.toString();
      }

      showDialog<void>(
        context: context,
        useRootNavigator: true,
        builder: (context) {
          return StackOkDialog(
            desktopPopRootNavigator: true, // mobile as well due to sub nav flow
            title: "Error",
            maxWidth: 500,
            message: err,
          );
        },
      );
    } finally {
      _nextLock = false;
    }
  }

  NameFormStatefulWidget? _form;
  NameFormStatefulWidget get form => _form ??= _buildForm();

  NameFormStatefulWidget _buildForm() {
    switch (widget.recordType) {
      case DNSRecordType.A:
        return AForm(key: _formStateKey);
      case DNSRecordType.CNAME:
        return CNAMEForm(key: _formStateKey);
      case DNSRecordType.NS:
        return NSForm(key: _formStateKey);
      case DNSRecordType.DS:
        return DSForm(key: _formStateKey);
      case DNSRecordType.TLS:
        return TLSForm(key: _formStateKey);
      case DNSRecordType.SRV:
        return SRVForm(key: _formStateKey);
      case DNSRecordType.TXT:
        return TXTForm(key: _formStateKey);
      case DNSRecordType.IMPORT:
        return IMPORTForm(key: _formStateKey);
      case DNSRecordType.SSH:
        return SSHForm(key: _formStateKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!Util.isDesktop)
          Text(
            "Add DNS record",
            style: STextStyles.pageTitleH2(context),
          ),
        SizedBox(
          height: Util.isDesktop ? 24 : 16,
        ),
        form,
        SizedBox(
          height: Util.isDesktop ? 24 : 16,
        ),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: "Cancel",
                buttonHeight: ButtonHeight.l,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(
              width: 16,
            ),
            Expanded(
              child: PrimaryButton(
                label: "Next",
                onPressed: _nextPressed,
                buttonHeight: ButtonHeight.l,
              ),
            ),
          ],
        ),
        SizedBox(
          height: Util.isDesktop ? 32 : 16,
        ),
      ],
    );
  }
}
