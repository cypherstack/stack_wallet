import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

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

  @override
  void initState() {
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
    return Scaffold(
        backgroundColor: StackTheme.instance.color.background,
        appBar: AppBar(
          backgroundColor: StackTheme.instance.color.background,
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
            "Edit note",
            style: STextStyles.navBarTitle,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            Constants.size.circularBorderRadius,
                          ),
                          child: TextField(
                            controller: _noteController,
                            style: STextStyles.field,
                            focusNode: noteFieldFocusNode,
                            decoration: standardInputDecoration(
                              "Note",
                              noteFieldFocusNode,
                            ).copyWith(
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
                        const Spacer(),
                        TextButton(
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
                          style:
                              Theme.of(context).textButtonTheme.style?.copyWith(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      CFColors.stackAccent,
                                    ),
                                  ),
                          child: Text(
                            "Save",
                            style: STextStyles.button,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ));
  }
}
