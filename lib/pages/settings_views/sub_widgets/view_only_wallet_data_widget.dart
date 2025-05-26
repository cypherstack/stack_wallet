import 'package:flutter/material.dart';

import '../../../models/keys/view_only_wallet_data.dart';
import '../../../utilities/util.dart';
import '../../../widgets/custom_buttons/simple_copy_button.dart';
import '../../../widgets/detail_item.dart';
import '../../wallet_view/transaction_views/transaction_details_view.dart';

class ViewOnlyWalletDataWidget extends StatelessWidget {
  const ViewOnlyWalletDataWidget({
    super.key,
    required this.data,
  });

  final ViewOnlyWalletData data;

  @override
  Widget build(BuildContext context) {
    return switch (data) {
      final CryptonoteViewOnlyWalletData e => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DetailItem(
              title: "Address",
              detail: e.address,
              button: Util.isDesktop
                  ? IconCopyButton(
                      data: e.address,
                    )
                  : SimpleCopyButton(
                      data: e.address,
                    ),
            ),
            const SizedBox(
              height: 16,
            ),
            DetailItem(
              title: "Private view key",
              detail: e.privateViewKey,
              button: Util.isDesktop
                  ? IconCopyButton(
                      data: e.privateViewKey,
                    )
                  : SimpleCopyButton(
                      data: e.privateViewKey,
                    ),
            ),
          ],
        ),
      final AddressViewOnlyWalletData e => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DetailItem(
              title: "Address",
              detail: e.address,
              button: Util.isDesktop
                  ? IconCopyButton(
                      data: e.address,
                    )
                  : SimpleCopyButton(
                      data: e.address,
                    ),
            ),
          ],
        ),
      final ExtendedKeysViewOnlyWalletData e => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...e.xPubs.map(
              (xPub) => DetailItem(
                title: xPub.path,
                detail: xPub.encoded,
                button: Util.isDesktop
                    ? IconCopyButton(
                        data: xPub.encoded,
                      )
                    : SimpleCopyButton(
                        data: xPub.encoded,
                      ),
              ),
            ),
          ],
        ),
      final SparkViewOnlyWalletData e => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DetailItem(
              title: "View Key",
              detail: e.viewKey,
              button: Util.isDesktop
                  ? IconCopyButton(
                      data: e.viewKey,
                    )
                  : SimpleCopyButton(
                      data: e.viewKey,
                    ),
            ),
          ],
        ),
    };
  }
}
