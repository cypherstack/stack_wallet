import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/notifications/show_flush_bar.dart';
import 'package:stackduo/providers/providers.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/enums/flush_bar_type.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/utilities/util.dart';
import 'package:stackduo/widgets/background.dart';
import 'package:stackduo/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackduo/widgets/icon_widgets/x_icon.dart';
import 'package:stackduo/widgets/stack_text_field.dart';
import 'package:stackduo/widgets/textfield_icon_button.dart';

class RenameWalletView extends ConsumerStatefulWidget {
  const RenameWalletView({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  static const String routeName = "/renameWallet";

  final String walletId;

  @override
  ConsumerState<RenameWalletView> createState() => _RenameWalletViewState();
}

class _RenameWalletViewState extends ConsumerState<RenameWalletView> {
  late final TextEditingController _controller;
  late final String walletId;
  late final String originalName;

  final _focusNode = FocusNode();

  @override
  void initState() {
    _controller = TextEditingController();
    walletId = widget.walletId;
    originalName =
        ref.read(walletsChangeNotifierProvider).getManager(walletId).walletName;
    _controller.text = originalName;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            "Rename wallet",
            style: STextStyles.navBarTitle(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
                child: TextField(
                  autocorrect: Util.isDesktop ? false : true,
                  enableSuggestions: Util.isDesktop ? false : true,
                  controller: _controller,
                  focusNode: _focusNode,
                  style: STextStyles.field(context),
                  onChanged: (_) => setState(() {}),
                  decoration: standardInputDecoration(
                    "Wallet name",
                    _focusNode,
                    context,
                  ).copyWith(
                    suffixIcon: _controller.text.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(right: 0),
                            child: UnconstrainedBox(
                              child: Row(
                                children: [
                                  TextFieldIconButton(
                                    child: const XIcon(),
                                    onTap: () async {
                                      setState(() {
                                        _controller.text = "";
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                style: Theme.of(context)
                    .extension<StackColors>()!
                    .getPrimaryEnabledButtonStyle(context),
                onPressed: () async {
                  final newName = _controller.text;
                  final success = await ref
                      .read(walletsServiceChangeNotifierProvider)
                      .renameWallet(
                        from: originalName,
                        to: newName,
                        shouldNotifyListeners: true,
                      );

                  if (success) {
                    ref
                        .read(walletsChangeNotifierProvider)
                        .getManager(walletId)
                        .walletName = newName;
                    Navigator.of(context).pop();
                    showFloatingFlushBar(
                      type: FlushBarType.success,
                      message: "Wallet renamed",
                      context: context,
                    );
                  } else {
                    showFloatingFlushBar(
                      type: FlushBarType.warning,
                      message: "Wallet named \"$newName\" already exists",
                      context: context,
                    );
                  }
                },
                child: Text(
                  "Save",
                  style: STextStyles.button(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
