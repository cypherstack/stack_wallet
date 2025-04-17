import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../models/namecoin_dns/dns_a_record_address_type.dart';
import '../../../../models/namecoin_dns/dns_record.dart';
import '../../../../models/namecoin_dns/dns_record_type.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/assets.dart';
import '../../../../utilities/constants.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../utilities/util.dart';
import '../name_form_interface.dart';

class AForm extends NameFormStatefulWidget {
  const AForm({super.key, required super.name});

  @override
  NameFormState<AForm> createState() => _AFormState();
}

class _AFormState extends NameFormState<AForm> {
  final _addressDataController = TextEditingController();
  final _addressDataFieldFocus = FocusNode();

  DNSAddressType _addressType = DNSAddressType.IPv4;

  @override
  DNSRecord buildRecord() {
    final parts = _addressDataController.text.split(",").map((e) => e.trim());

    final List<String> addresses = [];

    for (final part in parts) {
      switch (_addressType) {
        case DNSAddressType.IPv4:
          final address =
              InternetAddress(part.trim(), type: InternetAddressType.IPv4);
          addresses.add(address.address);
          break;

        case DNSAddressType.IPv6:
          final address = InternetAddress(part, type: InternetAddressType.IPv6);
          addresses.add(address.address);
          break;

        case DNSAddressType.Tor:
          final regex = RegExp(r'^[a-z2-7]{56}\.onion$');
          if (regex.hasMatch(part)) {
            addresses.add(part);
          } else {
            throw Exception("Invalid tor address: $part");
          }

        case DNSAddressType.Freenet:
          // TODO: verify
          final regex = RegExp(r'(CHK|SSK|USK)@[a-zA-Z0-9~-]{43,}/?');
          final kskRegex = RegExp(r'KSK@[\w\-.~]+');
          if (regex.hasMatch(part) || kskRegex.hasMatch(part)) {
            addresses.add(part);
          } else {
            throw Exception("Invalid freenet address: $part");
          }

        case DNSAddressType.I2P:
          // TODO: verify
          final b32Regex = RegExp(r'^[a-z2-7]{52}\.b32\.i2p$');
          final b64Regex = RegExp(r'^[A-Za-z0-9+/=]{516,}$');
          if (b32Regex.hasMatch(part) || b64Regex.hasMatch(part)) {
            addresses.add(part);
          } else {
            throw Exception("Invalid i2p address: $part");
          }

        case DNSAddressType.ZeroNet:
          // TODO: verify
          final regex = RegExp(r'^[13][a-km-zA-HJ-NP-Z1-9]{32,33}$');
          if (regex.hasMatch(part)) {
            addresses.add(part);
          } else {
            throw Exception("Invalid zeronet address: $part");
          }
      }
    }

    final Map<String, dynamic> map;

    if (_addressType == DNSAddressType.Tor) {
      map = {
        "map": {
          "_tor": {
            "txt": addresses,
          },
        },
      };
    } else {
      map = {
        _addressType!.key: addresses,
      };
    }

    return DNSRecord(
      name: widget.name,
      type: DNSRecordType.A,
      data: map,
    );
  }

  @override
  void dispose() {
    _addressDataController.dispose();
    _addressDataFieldFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DNSFieldText(
          "Address type",
        ),
        SizedBox(
          height: Util.isDesktop ? 10 : 8,
        ),
        DropdownButtonHideUnderline(
          child: DropdownButton2<DNSAddressType>(
            hint: Text(
              "Choose address type",
              style: STextStyles.fieldLabel(context),
            ),
            dropdownStyleData: DropdownStyleData(
              offset: const Offset(0, -10),
              elevation: 0,
              maxHeight: Util.isDesktop ? null : 200,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldDefaultBG,
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
              ),
            ),
            menuItemStyleData: const MenuItemStyleData(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
            ),
            isExpanded: true,
            value: _addressType,
            onChanged: (value) {
              if (value is DNSAddressType && _addressType != value) {
                setState(() {
                  _addressType = value;
                });
              }
            },
            buttonStyleData: ButtonStyleData(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldDefaultBG,
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
              ),
            ),
            iconStyleData: IconStyleData(
              icon: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: SvgPicture.asset(
                  Assets.svg.chevronDown,
                  width: 10,
                  height: 5,
                  color: Theme.of(context).extension<StackColors>()!.textDark3,
                ),
              ),
            ),
            items: [
              ...DNSAddressType.values.map(
                (e) => DropdownMenuItem<DNSAddressType>(
                  value: e,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      e.name,
                      style: STextStyles.desktopTextExtraExtraSmall(context)
                          .copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textDark,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: Util.isDesktop ? 24 : 16,
        ),
        const DNSFieldText(
          "Value",
        ),
        SizedBox(
          height: Util.isDesktop ? 10 : 8,
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
          child: TextField(
            focusNode: _addressDataFieldFocus,
            controller: _addressDataController,
            textAlignVertical: TextAlignVertical.center,
            maxLines: 3,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.all(16),
              hintText: "e.g. 255.255.255.255, "
                  "76f4a520a262c269dcba66bc1f560452e30a44e14ce6b37ce20b8.onion",
              hintStyle: STextStyles.fieldLabel(context),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
