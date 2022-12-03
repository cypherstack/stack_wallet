import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/utilities/util.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/conditional_parent.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:epicmobile/widgets/desktop/primary_button.dart';
import 'package:epicmobile/widgets/icon_widgets/x_icon.dart';
import 'package:epicmobile/widgets/stack_text_field.dart';
import 'package:epicmobile/widgets/textfield_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditNoteView extends ConsumerStatefulWidget {
  const EditNoteView({
    Key? key,
    required this.txid,
    required this.walletId,
    required this.note,
  }) : super(key: key);

  static const String routeName = "/editNote";

  final String txid;
  final String walletId;
  final String note;

  @override
  ConsumerState<EditNoteView> createState() => _EditNoteViewState();
}

class _EditNoteViewState extends ConsumerState<EditNoteView> {
  late final TextEditingController _noteController;
  final noteFieldFocusNode = FocusNode();

  late final bool isDesktop;

  @override
  void initState() {
    isDesktop = Util.isDesktop;
    _noteController = TextEditingController();
    _noteController.text = widget.note;
    super.initState();
  }

  @override
  void dispose() {
    _noteController.dispose();
    noteFieldFocusNode.dispose();
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
                  "Edit note",
                  style: STextStyles.titleH4(context),
                ),
              ),
        body: MobileEditNoteScaffold(
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
                        "Edit note",
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
                    controller: _noteController,
                    style: isDesktop
                        ? STextStyles.desktopTextExtraSmall(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textFieldActiveText,
                            height: 1.8,
                          )
                        : STextStyles.field(context),
                    focusNode: noteFieldFocusNode,
                    decoration: standardInputDecoration(
                      "Note",
                      noteFieldFocusNode,
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
                      suffixIcon: _noteController.text.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(right: 0),
                              child: UnconstrainedBox(
                                child: Row(
                                  children: [
                                    TextFieldIconButton(
                                      child: const XIcon(),
                                      onTap: () async {
                                        setState(() {
                                          _noteController.text = "";
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
                      await ref
                          .read(notesServiceChangeNotifierProvider(
                              widget.walletId))
                          .editOrAddNote(
                            txid: widget.txid,
                            note: _noteController.text,
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
                    await ref
                        .read(
                            notesServiceChangeNotifierProvider(widget.walletId))
                        .editOrAddNote(
                          txid: widget.txid,
                          note: _noteController.text,
                        );
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  style: Theme.of(context)
                      .extension<StackColors>()!
                      .getPrimaryEnabledButtonColor(context),
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

class MobileEditNoteScaffold extends StatelessWidget {
  const MobileEditNoteScaffold({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Util.isDesktop) {
      return child;
    } else {
      return Padding(
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
      );
    }
  }
}
