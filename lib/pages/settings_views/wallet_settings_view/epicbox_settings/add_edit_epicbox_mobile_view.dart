import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:uuid/uuid.dart';

import '../../../../models/epicbox_server_model.dart';
import '../../../../notifications/show_flush_bar.dart';
import '../../../../providers/global/node_service_provider.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/assets.dart';
import '../../../../utilities/constants.dart';
import '../../../../utilities/test_epicbox_server_connection.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../widgets/background.dart';
import '../../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../../widgets/desktop/primary_button.dart';
import '../../../../widgets/desktop/secondary_button.dart';
import '../../../../widgets/icon_widgets/x_icon.dart';
import '../../../../widgets/stack_text_field.dart';
import '../../../../widgets/textfield_icon_button.dart';

enum AddEditEpicboxMobileViewType { add, edit }

class AddEditEpicboxMobileView extends ConsumerStatefulWidget {
  const AddEditEpicboxMobileView({
    super.key,
    required this.viewType,
    this.epicBoxId,
    required this.routeOnSuccessOrDelete,
  }) : assert(
         (viewType == .edit && epicBoxId != null) ||
             viewType == .add && epicBoxId == null,
       );

  static const routeName = "/addEditEpicboxMobile";

  final AddEditEpicboxMobileViewType viewType;
  final String? epicBoxId;
  final String routeOnSuccessOrDelete;

  @override
  ConsumerState<AddEditEpicboxMobileView> createState() =>
      _AddEditEpicboxMobileViewState();
}

class _AddEditEpicboxMobileViewState
    extends ConsumerState<AddEditEpicboxMobileView> {
  late final TextEditingController _nameController;
  late final TextEditingController _hostController;
  late final TextEditingController _portController;

  final _nameFocusNode = FocusNode();
  final _hostFocusNode = FocusNode();
  final _portFocusNode = FocusNode();

  bool _useSSL = true;
  int? port;

  bool get canSave {
    return _nameController.text.isNotEmpty && canTestConnection;
  }

  bool get canTestConnection {
    return _hostController.text.isNotEmpty &&
        port != null &&
        port! >= 0 &&
        port! <= 65535;
  }

  Future<void> _testConnection() async {
    final data = EpicBoxFormData()
      ..name = _nameController.text
      ..host = _hostController.text
      ..port = port ?? 443
      ..useSSL = _useSSL;

    final result = await testEpicBoxServerConnection(data);
    if (!mounted) return;

    if (result != null) {
      unawaited(
        showFloatingFlushBar(
          type: FlushBarType.success,
          message: "Connection successful",
          context: context,
        ),
      );
    } else {
      unawaited(
        showFloatingFlushBar(
          type: FlushBarType.warning,
          message: "Could not connect to server",
          context: context,
        ),
      );
    }
  }

  Future<void> _attemptSave() async {
    final data = EpicBoxFormData()
      ..name = _nameController.text
      ..host = _hostController.text
      ..port = port ?? 443
      ..useSSL = _useSSL;

    final canConnect = await testEpicBoxServerConnection(data) != null;

    bool shouldSave = canConnect;

    if (!canConnect && mounted) {
      await showDialog<bool>(
        context: context,
        useSafeArea: true,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          title: const Text("Server currently unreachable"),
          content: const Text("Would you like to save this server anyways?"),
          actions: [
            // todo both pop until routeOnSuccessOrDelete ?
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                "Cancel",
                style: STextStyles.button(context).copyWith(
                  color: Theme.of(
                    context,
                  ).extension<StackColors>()!.accentColorDark,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                "Save",
                style: STextStyles.button(context).copyWith(
                  color: Theme.of(
                    context,
                  ).extension<StackColors>()!.accentColorDark,
                ),
              ),
            ),
          ],
        ),
      ).then((value) {
        if (value == true) {
          shouldSave = true;
        }
      });
    }

    if (!shouldSave) return;

    final epicBox = EpicBoxServerModel(
      id: widget.epicBoxId ?? const Uuid().v1(),
      host: _hostController.text,
      port: port ?? 443,
      name: _nameController.text,
      useSSL: _useSSL,
      enabled: true,
      isFailover: true,
      isDown: false,
    );

    await ref.read(nodeServiceChangeNotifierProvider).addEpicBox(epicBox, true);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  late final bool canDelete;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _hostController = TextEditingController();
    _portController = TextEditingController();

    switch (widget.viewType) {
      case .add:
        _portController.text = "443";
        port = 443;
        canDelete = false;
        break;

      case .edit:
        final epicBox = ref
            .read(nodeServiceChangeNotifierProvider)
            .getEpicBoxById(id: widget.epicBoxId!)!;

        _nameController.text = epicBox.name;
        _hostController.text = epicBox.host;
        _portController.text = (epicBox.port ?? 443).toString();
        _useSSL = epicBox.useSSL ?? true;
        port = epicBox.port ?? 443;
        canDelete = !epicBox.isDefault;
        break;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _nameFocusNode.dispose();
    _hostFocusNode.dispose();
    _portFocusNode.dispose();
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
            widget.viewType == AddEditEpicboxMobileViewType.add
                ? "Add Epicbox Server"
                : "Edit Epicbox Server",
            style: STextStyles.navBarTitle(context),
          ),
          actions: [
            if (canDelete)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10, right: 10),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AppBarIconButton(
                    key: const Key("deleteNodeAppBarButtonKey"),
                    size: 36,
                    shadows: const [],
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.background,
                    icon: SvgPicture.asset(
                      Assets.svg.trash,
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.accentColorDark,
                      width: 20,
                      height: 20,
                    ),
                    onPressed: () async {
                      Navigator.popUntil(
                        context,
                        ModalRoute.withName(widget.routeOnSuccessOrDelete),
                      );
                      await ref
                          .read(nodeServiceChangeNotifierProvider)
                          .deleteEpicBox(widget.epicBoxId!, true);
                    },
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (builderContext, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              Constants.size.circularBorderRadius,
                            ),
                            child: TextField(
                              autocorrect: false,
                              enableSuggestions: false,
                              controller: _nameController,
                              focusNode: _nameFocusNode,
                              style: STextStyles.field(context),
                              decoration:
                                  standardInputDecoration(
                                    "Server name",
                                    _nameFocusNode,
                                    context,
                                  ).copyWith(
                                    suffixIcon: _nameController.text.isNotEmpty
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                              right: 0,
                                            ),
                                            child: UnconstrainedBox(
                                              child: TextFieldIconButton(
                                                child: const XIcon(),
                                                onTap: () {
                                                  _nameController.clear();
                                                  setState(() {});
                                                },
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              Constants.size.circularBorderRadius,
                            ),
                            child: TextField(
                              autocorrect: false,
                              enableSuggestions: false,
                              controller: _hostController,
                              focusNode: _hostFocusNode,
                              style: STextStyles.field(context),
                              decoration:
                                  standardInputDecoration(
                                    "Host",
                                    _hostFocusNode,
                                    context,
                                  ).copyWith(
                                    suffixIcon: _hostController.text.isNotEmpty
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                              right: 0,
                                            ),
                                            child: UnconstrainedBox(
                                              child: TextFieldIconButton(
                                                child: const XIcon(),
                                                onTap: () {
                                                  _hostController.clear();
                                                  setState(() {});
                                                },
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              Constants.size.circularBorderRadius,
                            ),
                            child: TextField(
                              autocorrect: false,
                              enableSuggestions: false,
                              controller: _portController,
                              focusNode: _portFocusNode,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              keyboardType: TextInputType.number,
                              style: STextStyles.field(context),
                              decoration:
                                  standardInputDecoration(
                                    "Port",
                                    _portFocusNode,
                                    context,
                                  ).copyWith(
                                    suffixIcon: _portController.text.isNotEmpty
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                              right: 0,
                                            ),
                                            child: UnconstrainedBox(
                                              child: TextFieldIconButton(
                                                child: const XIcon(),
                                                onTap: () {
                                                  _portController.clear();
                                                  setState(() {});
                                                },
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                              onChanged: (value) {
                                port = int.tryParse(value);
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _useSSL = !_useSSL;
                                  });
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          value: _useSSL,
                                          onChanged: (newValue) {
                                            setState(() {
                                              _useSSL = newValue!;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Use SSL",
                                        style: STextStyles.itemSubtitle12(
                                          context,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),
                          const SizedBox(height: 16),
                          SecondaryButton(
                            label: "Test connection",
                            enabled: canTestConnection,
                            onPressed: canTestConnection
                                ? _testConnection
                                : null,
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: "Save",
                            onPressed: canSave ? _attemptSave : null,
                          ),
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
