import 'package:flutter/material.dart';
import 'package:flutter_native_splash/cli_commands.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/utilities/util.dart';
import 'package:stackduo/widgets/background.dart';
import 'package:stackduo/widgets/conditional_parent.dart';
import 'package:stackduo/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackduo/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackduo/widgets/desktop/primary_button.dart';
import 'package:stackduo/widgets/icon_widgets/x_icon.dart';
import 'package:stackduo/widgets/stack_text_field.dart';
import 'package:stackduo/widgets/textfield_icon_button.dart';

class SingleFieldEditView extends StatefulWidget {
  const SingleFieldEditView({
    Key? key,
    required this.initialValue,
    required this.label,
  }) : super(key: key);

  static const String routeName = "/singleFieldEdit";

  final String initialValue;
  final String label;

  @override
  State<SingleFieldEditView> createState() => _SingleFieldEditViewState();
}

class _SingleFieldEditViewState extends State<SingleFieldEditView> {
  late final TextEditingController _textController;
  final _textFocusNode = FocusNode();

  late final bool isDesktop;

  @override
  void initState() {
    isDesktop = Util.isDesktop;
    _textController = TextEditingController()..text = widget.initialValue;
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) => Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
            leading: AppBarBackButton(
              onPressed: () async {
                if (FocusScope.of(context).hasFocus) {
                  FocusScope.of(context).unfocus();
                  await Future<void>.delayed(const Duration(milliseconds: 75));
                }
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: Text(
              "Edit ${widget.label}",
              style: STextStyles.navBarTitle(context),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: child,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isDesktop)
            const SizedBox(
              height: 10,
            ),
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
                    "Edit ${widget.label}",
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
                controller: _textController,
                style: isDesktop
                    ? STextStyles.desktopTextExtraSmall(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textFieldActiveText,
                        height: 1.8,
                      )
                    : STextStyles.field(context),
                focusNode: _textFocusNode,
                decoration: standardInputDecoration(
                  widget.label.capitalize(),
                  _textFocusNode,
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
                  suffixIcon: _textController.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(right: 0),
                          child: UnconstrainedBox(
                            child: Row(
                              children: [
                                TextFieldIconButton(
                                  child: const XIcon(),
                                  onTap: () async {
                                    setState(() {
                                      _textController.text = "";
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

          ConditionalParent(
            condition: isDesktop,
            builder: (child) => Padding(
              padding: const EdgeInsets.all(32),
              child: child,
            ),
            child: PrimaryButton(
              label: "Save",
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop(_textController.text);
                }
              },
            ),
          )
        ],
      ),
    );
  }
}
