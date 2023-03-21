import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/providers/exchange/trade_note_service_provider.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/utilities/util.dart';
import 'package:stackduo/widgets/background.dart';
import 'package:stackduo/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackduo/widgets/icon_widgets/x_icon.dart';
import 'package:stackduo/widgets/stack_text_field.dart';
import 'package:stackduo/widgets/textfield_icon_button.dart';

class EditTradeNoteView extends ConsumerStatefulWidget {
  const EditTradeNoteView({
    Key? key,
    required this.tradeId,
    required this.note,
  }) : super(key: key);

  static const String routeName = "/editTradeNote";

  final String tradeId;
  final String note;

  @override
  ConsumerState<EditTradeNoteView> createState() => _EditNoteViewState();
}

class _EditNoteViewState extends ConsumerState<EditTradeNoteView> {
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
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
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
            "Edit trade note",
            style: STextStyles.navBarTitle(context),
          ),
        ),
        body: Padding(
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
                              controller: _noteController,
                              style: STextStyles.field(context),
                              focusNode: noteFieldFocusNode,
                              onChanged: (_) => setState(() {}),
                              decoration: standardInputDecoration(
                                "Note",
                                noteFieldFocusNode,
                                context,
                              ).copyWith(
                                suffixIcon: _noteController.text.isNotEmpty
                                    ? Padding(
                                        padding:
                                            const EdgeInsets.only(right: 0),
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
                              await ref.read(tradeNoteServiceProvider).set(
                                    tradeId: widget.tradeId,
                                    note: _noteController.text,
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
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
