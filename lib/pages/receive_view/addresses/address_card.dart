import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/receive_view/addresses/address_qr_popup.dart';
import 'package:stackwallet/pages/receive_view/addresses/edit_address_label_view.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/copy_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/qrcode_icon.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class AddressCard extends StatefulWidget {
  const AddressCard({
    Key? key,
    required this.address,
    required this.walletId,
    required this.coin,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  final Address address;
  final String walletId;
  final Coin coin;
  final ClipboardInterface clipboard;

  @override
  State<AddressCard> createState() => _AddressCardState();
}

class _AddressCardState extends State<AddressCard> {
  late Stream<AddressLabel?> stream;

  AddressLabel? label;

  @override
  void initState() {
    label = MainDB.instance
        .getAddressLabelSync(widget.walletId, widget.address.value);
    Id? id = label?.id;
    if (id == null) {
      label = AddressLabel(
        walletId: widget.walletId,
        addressString: widget.address.value,
        value: "",
      );
      id = MainDB.instance.putAddressLabelSync(label!);
    }
    stream = MainDB.instance.watchAddressLabel(id: id);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      child: StreamBuilder<AddressLabel?>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              label = snapshot.data!;
            }

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label!.value,
                      style: STextStyles.itemSubtitle(context),
                    ),
                    CustomTextButton(
                      text: "Edit label",
                      textSize: 14,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          EditAddressLabelView.routeName,
                          arguments: label!,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        widget.address.value,
                        style: STextStyles.itemSubtitle12(context),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: "Copy address",
                        icon: CopyIcon(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .buttonTextSecondary,
                        ),
                        onPressed: () async {
                          await widget.clipboard.setData(
                            ClipboardData(
                              text: widget.address.value,
                            ),
                          );
                          unawaited(
                            showFloatingFlushBar(
                              type: FlushBarType.info,
                              message: "Copied to clipboard",
                              context: context,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child: SecondaryButton(
                        label: "Show QR Code",
                        icon: QrCodeIcon(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .buttonTextSecondary,
                        ),
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            builder: (context) => AddressQrPopup(
                              addressString: widget.address.value,
                              coin: widget.coin,
                              clipboard: widget.clipboard,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
              ],
            );
          }),
    );
  }
}
