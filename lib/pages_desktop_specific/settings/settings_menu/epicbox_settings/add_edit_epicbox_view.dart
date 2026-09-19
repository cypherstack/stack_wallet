import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../models/epicbox_server_model.dart';
import '../../../../notifications/show_flush_bar.dart';
import '../../../../providers/global/node_service_provider.dart';
import '../../../../utilities/constants.dart';
import '../../../../utilities/test_epicbox_server_connection.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../../widgets/desktop/delete_button.dart';
import '../../../../widgets/desktop/desktop_dialog.dart';
import '../../../../widgets/desktop/primary_button.dart';
import '../../../../widgets/desktop/secondary_button.dart';
import '../../../../widgets/icon_widgets/x_icon.dart';
import '../../../../widgets/stack_text_field.dart';
import '../../../../widgets/textfield_icon_button.dart';

enum AddEditEpicBoxViewType { add, edit }

class AddEditEpicBoxView extends ConsumerStatefulWidget {
  const AddEditEpicBoxView({
    super.key,
    required this.viewType,
    this.epicBoxId,
    required this.onSave,
  }) : assert(
         (viewType == .edit && epicBoxId != null) ||
             viewType == .add && epicBoxId == null,
       );

  final AddEditEpicBoxViewType viewType;
  final String? epicBoxId;
  final VoidCallback onSave;

  @override
  ConsumerState<AddEditEpicBoxView> createState() => _AddEditEpicBoxViewState();
}

class _AddEditEpicBoxViewState extends ConsumerState<AddEditEpicBoxView> {
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
      await showDialog<dynamic>(
        context: context,
        useSafeArea: true,
        barrierDismissible: true,
        builder: (_) => DesktopDialog(
          maxWidth: 440,
          maxHeight: 300,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Row(
                  children: [
                    const SizedBox(width: 32),
                    Text(
                      "Server currently unreachable",
                      style: STextStyles.desktopH3(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 32,
                    right: 32,
                    top: 16,
                    bottom: 32,
                  ),
                  child: Column(
                    children: [
                      const Spacer(),
                      Text(
                        "Would you like to save this server anyways?",
                        style: STextStyles.desktopTextMedium(context),
                      ),
                      const Spacer(flex: 2),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              label: "Cancel",
                              buttonHeight: ButtonHeight.l,
                              onPressed: () => Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pop(false),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: PrimaryButton(
                              label: "Save",
                              buttonHeight: ButtonHeight.l,
                              onPressed: () => Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pop(true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ).then((value) {
        if (value is bool && value) {
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
    widget.onSave();

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
    return DesktopDialog(
      maxWidth: 580,
      maxHeight: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SizedBox(width: 8),
                  const AppBarBackButton(iconSize: 24, size: 40),
                  Text(
                    widget.viewType == AddEditEpicBoxViewType.add
                        ? "Add Epic Box server"
                        : "Edit Epic Box server",
                    style: STextStyles.desktopH3(context),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 32,
              right: 32,
              top: 16,
              bottom: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                  padding: const EdgeInsets.only(right: 0),
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
                const SizedBox(height: 8),
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
                                  padding: const EdgeInsets.only(right: 0),
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
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                  child: TextField(
                    autocorrect: false,
                    enableSuggestions: false,
                    controller: _portController,
                    focusNode: _portFocusNode,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                                  padding: const EdgeInsets.only(right: 0),
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
                const SizedBox(height: 8),
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
                              style: STextStyles.itemSubtitle12(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                if (canDelete)
                  SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        Expanded(
                          child: DeleteButton(
                            label: "Delete node",
                            desktopMed: true,
                            onPressed: () {
                              Navigator.of(context).pop();
                              ref
                                  .read(nodeServiceChangeNotifierProvider)
                                  .deleteEpicBox(widget.epicBoxId!, true);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Spacer(),
                      ],
                    ),
                  ),
                if (canDelete) const SizedBox(height: 45),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: "Test connection",
                        enabled: canTestConnection,
                        buttonHeight: ButtonHeight.l,
                        onPressed: canTestConnection ? _testConnection : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PrimaryButton(
                        label: "Save",
                        enabled: canSave,
                        buttonHeight: ButtonHeight.l,
                        onPressed: canSave ? _attemptSave : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
