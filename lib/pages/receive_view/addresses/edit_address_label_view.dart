import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/main_db.dart';
import 'package:stackwallet/models/isar/models/address_label.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class EditAddressLabelView extends ConsumerStatefulWidget {
  const EditAddressLabelView({
    Key? key,
    required this.addressLabelId,
  }) : super(key: key);

  static const String routeName = "/editAddressLabel";

  final int addressLabelId;

  @override
  ConsumerState<EditAddressLabelView> createState() =>
      _EditAddressLabelViewState();
}

class _EditAddressLabelViewState extends ConsumerState<EditAddressLabelView> {
  late final TextEditingController _labelFieldController;
  final labelFieldFocusNode = FocusNode();

  late final bool isDesktop;

  late AddressLabel addressLabel;

  @override
  void initState() {
    isDesktop = Util.isDesktop;
    _labelFieldController = TextEditingController();
    addressLabel = MainDB.instance.isar.addressLabels
        .where()
        .idEqualTo(widget.addressLabelId)
        .findFirstSync()!;
    _labelFieldController.text = addressLabel.value;
    super.initState();
  }

  @override
  void dispose() {
    _labelFieldController.dispose();
    labelFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) => Background(
        child: child,
      ),
      child: Scaffold(
        backgroundColor: isDesktop
            ? Colors.transparent
            : Theme.of(context).extension<StackColors>()!.background,
        appBar: isDesktop
            ? null
            : AppBar(
                backgroundColor:
                    Theme.of(context).extension<StackColors>()!.background,
                leading: AppBarBackButton(
                  onPressed: () async {
                    if (FocusScope.of(context).hasFocus) {
                      FocusScope.of(context).unfocus();
                      await Future<void>.delayed(
                          const Duration(milliseconds: 75));
                    }
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                title: Text(
                  "Edit label",
                  style: STextStyles.navBarTitle(context),
                ),
              ),
        body: ConditionalParent(
          condition: !isDesktop,
          builder: (child) => Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: child,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isDesktop)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 32,
                    bottom: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Edit label",
                        style: STextStyles.desktopH3(context),
                      ),
                      const DesktopDialogCloseButton(),
                    ],
                  ),
                ),
              Padding(
                padding: isDesktop
                    ? const EdgeInsets.symmetric(
                        horizontal: 32,
                      )
                    : const EdgeInsets.all(0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                  child: TextField(
                    autocorrect: Util.isDesktop ? false : true,
                    enableSuggestions: Util.isDesktop ? false : true,
                    controller: _labelFieldController,
                    style: isDesktop
                        ? STextStyles.desktopTextExtraSmall(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textFieldActiveText,
                            height: 1.8,
                          )
                        : STextStyles.field(context),
                    focusNode: labelFieldFocusNode,
                    decoration: standardInputDecoration(
                      "Address label",
                      labelFieldFocusNode,
                      context,
                      desktopMed: isDesktop,
                    ).copyWith(
                      contentPadding: isDesktop
                          ? const EdgeInsets.only(
                              left: 16,
                              top: 11,
                              bottom: 12,
                              right: 5,
                            )
                          : null,
                      suffixIcon: _labelFieldController.text.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(right: 0),
                              child: UnconstrainedBox(
                                child: Row(
                                  children: [
                                    TextFieldIconButton(
                                      child: const XIcon(),
                                      onTap: () async {
                                        setState(() {
                                          _labelFieldController.text = "";
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
              ),
              // if (!isDesktop)
              const Spacer(),
              if (isDesktop)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: PrimaryButton(
                    label: "Save",
                    onPressed: () async {
                      await MainDB.instance.updateAddressLabel(
                        addressLabel.copyWith(
                          label: _labelFieldController.text,
                        ),
                      );
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              if (!isDesktop)
                TextButton(
                  onPressed: () async {
                    await MainDB.instance.updateAddressLabel(
                      addressLabel.copyWith(
                        label: _labelFieldController.text,
                      ),
                    );
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  style: Theme.of(context)
                      .extension<StackColors>()!
                      .getPrimaryEnabledButtonStyle(context),
                  child: Text(
                    "Save",
                    style: STextStyles.button(context),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
