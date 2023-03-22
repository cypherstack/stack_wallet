import 'dart:async';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/pages/receive_view/addresses/address_tag.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class AddressCard extends StatefulWidget {
  const AddressCard({
    Key? key,
    required this.addressId,
    required this.walletId,
    required this.coin,
    this.onPressed,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  final int addressId;
  final String walletId;
  final Coin coin;
  final ClipboardInterface clipboard;
  final VoidCallback? onPressed;

  @override
  State<AddressCard> createState() => _AddressCardState();
}

class _AddressCardState extends State<AddressCard> {
  late Stream<AddressLabel?> stream;
  late final Address address;

  AddressLabel? label;

  @override
  void initState() {
    address = MainDB.instance.isar.addresses
        .where()
        .idEqualTo(widget.addressId)
        .findFirstSync()!;

    label = MainDB.instance.getAddressLabelSync(widget.walletId, address.value);
    Id? id = label?.id;
    if (id == null) {
      label = AddressLabel(
        walletId: widget.walletId,
        addressString: address.value,
        value: "",
        tags: address.subType == AddressSubType.receiving
            ? ["receiving"]
            : address.subType == AddressSubType.change
                ? ["change"]
                : null,
      );
      id = MainDB.instance.putAddressLabelSync(label!);
    }
    stream = MainDB.instance.watchAddressLabel(id: id);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      onPressed: widget.onPressed,
      child: StreamBuilder<AddressLabel?>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            label = snapshot.data!;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label!.value.isNotEmpty)
                Text(
                  label!.value,
                  style: STextStyles.itemSubtitle(context),
                  textAlign: TextAlign.left,
                ),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //
              //     CustomTextButton(
              //       text: "Edit label",
              //       textSize: 14,
              //       onTap: () {
              //         Navigator.of(context).pushNamed(
              //           EditAddressLabelView.routeName,
              //           arguments: label!.id,
              //         );
              //       },
              //     ),
              //   ],
              // ),
              if (label!.value.isNotEmpty)
                const SizedBox(
                  height: 8,
                ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      address.value,
                      style: STextStyles.itemSubtitle12(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),

              if (label!.tags != null && label!.tags!.isNotEmpty)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: label!.tags!
                      .map(
                        (e) => AddressTag(
                          tag: e,
                        ),
                      )
                      .toList(),
                ),
              // Row(
              //   children: [
              //     Expanded(
              //       child: SecondaryButton(
              //         label: "Copy address",
              //         icon: CopyIcon(
              //           color: Theme.of(context)
              //               .extension<StackColors>()!
              //               .buttonTextSecondary,
              //         ),
              //         onPressed: () async {
              //           await widget.clipboard.setData(
              //             ClipboardData(
              //               text: address.value,
              //             ),
              //           );
              //           if (mounted) {
              //             unawaited(
              //               showFloatingFlushBar(
              //                 type: FlushBarType.info,
              //                 message: "Copied to clipboard",
              //                 context: context,
              //               ),
              //             );
              //           }
              //         },
              //       ),
              //     ),
              //     const SizedBox(
              //       width: 12,
              //     ),
              //     Expanded(
              //       child: SecondaryButton(
              //         label: "Show QR Code",
              //         icon: QrCodeIcon(
              //           color: Theme.of(context)
              //               .extension<StackColors>()!
              //               .buttonTextSecondary,
              //         ),
              //         onPressed: () {
              //           showDialog<void>(
              //             context: context,
              //             builder: (context) => AddressQrPopup(
              //               addressString: address.value,
              //               coin: widget.coin,
              //               clipboard: widget.clipboard,
              //             ),
              //           );
              //         },
              //       ),
              //     ),
              //   ],
              // )
            ],
          );
        },
      ),
    );
  }
}
