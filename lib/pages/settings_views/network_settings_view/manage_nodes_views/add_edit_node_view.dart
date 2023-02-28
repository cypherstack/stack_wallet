import 'dart:async';

import 'package:epicpay/models/node_model.dart';
import 'package:epicpay/providers/providers.dart';
import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/constants.dart';
import 'package:epicpay/utilities/enums/coin_enum.dart';
import 'package:epicpay/utilities/flutter_secure_storage_interface.dart';
import 'package:epicpay/utilities/test_epic_node_connection.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/widgets/background.dart';
import 'package:epicpay/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicpay/widgets/desktop/primary_button.dart';
import 'package:epicpay/widgets/desktop/secondary_button.dart';
import 'package:epicpay/widgets/icon_widgets/x_icon.dart';
import 'package:epicpay/widgets/rounded_container.dart';
import 'package:epicpay/widgets/stack_dialog.dart';
import 'package:epicpay/widgets/textfield_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:uuid/uuid.dart';

enum AddEditNodeViewType { add, edit }

class AddEditNodeView extends ConsumerStatefulWidget {
  const AddEditNodeView({
    Key? key,
    required this.viewType,
    required this.coin,
    required this.nodeId,
    required this.routeOnSuccessOrDelete,
    this.secureStore = const SecureStorageWrapper(
      FlutterSecureStorage(),
    ),
  }) : super(key: key);

  static const String routeName = "/addEditNode";

  final AddEditNodeViewType viewType;
  final Coin coin;
  final String routeOnSuccessOrDelete;
  final String? nodeId;
  final FlutterSecureStorageInterface secureStore;

  @override
  ConsumerState<AddEditNodeView> createState() => _AddEditNodeViewState();
}

class _AddEditNodeViewState extends ConsumerState<AddEditNodeView>
    with SingleTickerProviderStateMixin {
  late final AddEditNodeViewType viewType;
  late final Coin coin;
  late final String? nodeId;

  late final AnimationController animationController;
  late final Animation<double> animation;

  late bool saveEnabled;
  late bool testConnectionEnabled;

  Future<void> showTestResult(
    BuildContext context,
    bool testPassed,
  ) async {
    OverlayState? overlayState = Overlay.of(context);

    OverlayEntry entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 100,
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(Constants.size.circularBorderRadius),
            child: Material(
              color: Colors.transparent,
              child: FadeTransition(
                opacity: animation,
                child: RoundedContainer(
                  width: MediaQuery.of(context).size.width - 48,
                  color: Theme.of(context).extension<StackColors>()!.popupBG,
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        testPassed
                            ? Assets.svg.circleCheck
                            : Assets.svg.circleRedX,
                        color: testPassed
                            ? Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorGreen
                            : Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorRed,
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              testPassed
                                  ? "Connection successful"
                                  : "Could not connect. Please try again or use a different node.",
                              style: STextStyles.bodySmall(context).copyWith(
                                color: testPassed
                                    ? Theme.of(context)
                                        .extension<StackColors>()!
                                        .accentColorGreen
                                    : Theme.of(context)
                                        .extension<StackColors>()!
                                        .accentColorRed,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    animationController.addListener(() {
      overlayState?.setState(() {});
    });
    overlayState?.insert(entry);
    await animationController
        .forward()
        .whenComplete(() => Future<void>.delayed(
              const Duration(seconds: 2),
            ))
        .whenComplete(() => animationController.reverse())
        .whenComplete(() => entry.remove());
  }

  Future<NodeFormData?> _testConnection({bool showNotification = true}) async {
    final formData =
        await testEpicNodeConnection(ref.read(nodeFormDataProvider));

    if (showNotification && mounted) {
      unawaited(
        showTestResult(context, formData != null),
      );
    }

    return formData;
  }

  Future<void> attemptSave() async {
    NodeFormData? formData = await _testConnection(showNotification: false);
    final canConnect = formData != null;

    bool? shouldSave;

    if (!canConnect) {
      await showDialog<dynamic>(
        context: context,
        useSafeArea: true,
        barrierDismissible: true,
        builder: (_) => StackDialog(
          title: "Server currently unreachable",
          message: "Would you like to save this node anyways?",
          leftButton: SecondaryButton(
            label: "CANCEL",
            onPressed: () async {
              Navigator.of(context).pop(false);
            },
          ),
          rightButton: PrimaryButton(
            label: "SAVE",
            onPressed: () async {
              Navigator.of(context).pop(true);
            },
          ),
        ),
      ).then((value) {
        if (value is bool && value) {
          shouldSave = true;
        } else {
          shouldSave = false;
        }
      });
    }

    if (!canConnect && !shouldSave!) {
      // return without saving
      return;
    }

    if (!canConnect) {
      // use failing data to save anyways
      formData = ref.read(nodeFormDataProvider);
    }

    switch (viewType) {
      case AddEditNodeViewType.add:
        NodeModel node = NodeModel(
          host: formData!.host!,
          port: formData.port ?? 3413,
          name: formData.name!,
          id: const Uuid().v1(),
          useSSL: formData.useSSL!,
          loginName: formData.login,
          enabled: true,
          coinName: coin.name,
          isFailover: formData.isFailover!,
          isDown: false,
        );

        await ref.read(nodeServiceChangeNotifierProvider).add(
              node,
              formData.password,
              true,
            );
        if (mounted) {
          Navigator.of(context)
              .popUntil(ModalRoute.withName(widget.routeOnSuccessOrDelete));
        }
        break;
      case AddEditNodeViewType.edit:
        NodeModel node = NodeModel(
          host: formData!.host!,
          port: formData.port!,
          name: formData.name!,
          id: nodeId!,
          useSSL: formData.useSSL!,
          loginName: formData.login,
          enabled: true,
          coinName: coin.name,
          isFailover: formData.isFailover!,
          isDown: false,
        );

        await ref.read(nodeServiceChangeNotifierProvider).add(
              node,
              formData.password,
              true,
            );
        if (mounted) {
          Navigator.of(context)
              .popUntil(ModalRoute.withName(widget.routeOnSuccessOrDelete));
        }
        break;
    }
  }

  void showContextMenu() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Material(
                  color: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 160,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return RoundedContainer(
                          padding: const EdgeInsets.all(8),
                          color:
                              Theme.of(context).extension<StackColors>()!.coal,
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  Navigator.popUntil(
                                      context,
                                      ModalRoute.withName(
                                          widget.routeOnSuccessOrDelete));

                                  await ref
                                      .read(nodeServiceChangeNotifierProvider)
                                      .delete(
                                        nodeId!,
                                        true,
                                      );
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  width: constraints.minWidth,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      "Delete node",
                                      style: STextStyles.body(context),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    ref.refresh(nodeFormDataProvider);
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    animation = CurveTween(
      curve: Curves.bounceInOut,
    ).animate(animationController);
    viewType = widget.viewType;
    coin = widget.coin;
    nodeId = widget.nodeId;

    if (nodeId == null) {
      saveEnabled = false;
      testConnectionEnabled = false;
    } else {
      final node =
          ref.read(nodeServiceChangeNotifierProvider).getNodeById(id: nodeId!)!;
      testConnectionEnabled = node.host.isNotEmpty;
      saveEnabled = testConnectionEnabled && node.name.isNotEmpty;
    }

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final NodeModel? node =
        viewType == AddEditNodeViewType.edit && nodeId != null
            ? ref.watch(nodeServiceChangeNotifierProvider
                .select((value) => value.getNodeById(id: nodeId!)))
            : null;

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
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
          centerTitle: true,
          title: Text(
            viewType == AddEditNodeViewType.edit
                ? "Edit node"
                : "Add custom node",
            style: STextStyles.titleH4(context),
          ),
          actions: [
            if (viewType == AddEditNodeViewType.edit)
              Padding(
                padding: const EdgeInsets.only(
                  top: 10,
                  bottom: 10,
                  right: 16,
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AppBarIconButton(
                    key: const Key("addressBookAddNewContactViewButton"),
                    size: 36,
                    shadows: const [],
                    color:
                        Theme.of(context).extension<StackColors>()!.background,
                    icon: SvgPicture.asset(
                      Assets.svg.ellipsis,
                    ),
                    onPressed: () {
                      showContextMenu();
                    },
                  ),
                ),
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.only(
            top: 12,
            left: 12,
            right: 12,
            bottom: 12,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight - 8),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          NodeForm(
                            node: node,
                            secureStore: widget.secureStore,
                            readOnly: false,
                            coin: widget.coin,
                            onChanged: (canSave, canTest) {
                              if (canSave != saveEnabled &&
                                  canTest != testConnectionEnabled) {
                                setState(() {
                                  saveEnabled = canSave;
                                  testConnectionEnabled = canTest;
                                });
                              } else if (canSave != saveEnabled) {
                                setState(() {
                                  saveEnabled = canSave;
                                });
                              } else if (canTest != testConnectionEnabled) {
                                setState(() {
                                  testConnectionEnabled = canTest;
                                });
                              }
                            },
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: SecondaryButton(
                                  label: "TEST",
                                  enabled: testConnectionEnabled,
                                  desktopMed: true,
                                  onPressed: testConnectionEnabled
                                      ? () async {
                                          await _testConnection();
                                        }
                                      : null,
                                ),
                              ),
                              const SizedBox(
                                width: 16,
                              ),
                              Expanded(
                                child: PrimaryButton(
                                  label: "SAVE",
                                  enabled: testConnectionEnabled,
                                  onPressed: saveEnabled ? attemptSave : null,
                                ),
                              ),
                            ],
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

class NodeFormData {
  String? name, host, login, password;
  int? port;
  bool? useSSL, isFailover;

  @override
  String toString() {
    return "{ name: $name, host: $host, port: $port, useSSL: $useSSL }";
  }
}

final nodeFormDataProvider = Provider<NodeFormData>((_) => NodeFormData());

class NodeForm extends ConsumerStatefulWidget {
  const NodeForm({
    Key? key,
    this.node,
    required this.secureStore,
    required this.readOnly,
    required this.coin,
    this.onChanged,
  }) : super(key: key);

  final NodeModel? node;
  final FlutterSecureStorageInterface secureStore;
  final bool readOnly;
  final Coin coin;
  final void Function(bool canSave, bool canTestConnection)? onChanged;

  @override
  ConsumerState<NodeForm> createState() => _NodeFormState();
}

class _NodeFormState extends ConsumerState<NodeForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _passwordController;
  late final TextEditingController _usernameController;

  final _nameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _portFocusNode = FocusNode();
  final _hostFocusNode = FocusNode();
  final _usernameFocusNode = FocusNode();

  bool _useSSL = false;
  bool _isFailover = false;
  int? port;
  late bool enableSSLCheckbox;

  late final bool enableAuthFields;

  void Function(bool canSave, bool canTestConnection)? onChanged;

  bool _checkShouldEnableAuthFields(Coin coin) {
    // switch (coin) {
    //   case Coin.epicCash:
    //     return true;
    // }
    return false;
  }

  bool get canSave {
    // 65535 is max tcp port
    return _nameController.text.isNotEmpty && canTestConnection;
  }

  bool get canTestConnection {
    // 65535 is max tcp port
    final bool _portNullOrInRange =
        (port != null && port! >= 0 && port! <= 65535) ||
            port == null; // need to allow null and default to 443
    return _hostController.text.isNotEmpty && _portNullOrInRange;
  }

  bool enableField(TextEditingController controller) {
    bool enable = true;
    if (widget.readOnly) {
      enable = controller.text.isNotEmpty;
    }
    return enable;
  }

  void _updateState() {
    port = int.tryParse(_portController.text);
    onChanged?.call(canSave, canTestConnection);
    ref.read(nodeFormDataProvider).name = _nameController.text;
    ref.read(nodeFormDataProvider).host = _hostController.text;

    ref.read(nodeFormDataProvider).login =
        _usernameController.text.isEmpty ? null : _usernameController.text;

    ref.read(nodeFormDataProvider).password =
        _passwordController.text.isEmpty ? null : _passwordController.text;

    ref.read(nodeFormDataProvider).port = port;
    ref.read(nodeFormDataProvider).useSSL = _useSSL;
    ref.read(nodeFormDataProvider).isFailover = _isFailover;
    setState(() {});
  }

  @override
  void initState() {
    onChanged = widget.onChanged;
    _nameController = TextEditingController();
    _hostController = TextEditingController();
    _portController = TextEditingController();
    _passwordController = TextEditingController();
    _usernameController = TextEditingController();

    enableAuthFields = _checkShouldEnableAuthFields(widget.coin);

    if (widget.node != null) {
      final node = widget.node!;
      if (enableAuthFields) {
        node.getPassword(widget.secureStore).then((value) {
          if (value is String) {
            _passwordController.text = value;
          }
        });

        _usernameController.text = node.loginName ?? "";
      }

      _nameController.text = node.name;
      _hostController.text = node.host;
      _portController.text = node.port.toString();
      _usernameController.text = node.loginName ?? "";
      _useSSL = node.useSSL;
      _isFailover = node.isFailover;
      enableSSLCheckbox = !node.host.startsWith("http");

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // update provider state object so test connection works without having to modify a field in the ui first
        _updateState();
      });
    } else {
      enableSSLCheckbox = true;
      // default to port 3413
      // _portController.text = "3413";
    }

    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();

    _nameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _usernameFocusNode.dispose();
    _hostFocusNode.dispose();
    _portFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          textAlignVertical: TextAlignVertical.center,
          autocorrect: false,
          enableSuggestions: false,
          key: const Key("addCustomNodeNodeNameFieldKey"),
          readOnly: widget.readOnly,
          enabled: enableField(_nameController),
          controller: _nameController,
          focusNode: _nameFocusNode,
          style: STextStyles.body(context),
          decoration: InputDecoration(
            hintText: "Node name",
            fillColor: _nameFocusNode.hasFocus
                ? Theme.of(context).extension<StackColors>()!.textFieldActiveBG
                : Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldDefaultBG,
            isCollapsed: true,
            hintStyle: STextStyles.body(context).copyWith(
              color: Theme.of(context).extension<StackColors>()!.textMedium,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 0),
              child: UnconstrainedBox(
                child: Row(
                  children: [
                    if (!widget.readOnly && _nameController.text.isNotEmpty)
                      TextFieldIconButton(
                        child: const XIcon(),
                        onTap: () async {
                          _nameController.text = "";
                          _updateState();
                        },
                      ),
                    const SizedBox(
                      height: 40,
                    ),
                  ],
                ),
              ),
            ),
          ),
          onChanged: (newValue) {
            _updateState();
            setState(() {});
          },
        ),
        const SizedBox(
          height: 16,
        ),
        TextField(
          textAlignVertical: TextAlignVertical.center,
          autocorrect: false,
          enableSuggestions: false,
          key: const Key("addCustomNodeNodeAddressFieldKey"),
          readOnly: widget.readOnly,
          enabled: enableField(_hostController),
          controller: _hostController,
          focusNode: _hostFocusNode,
          style: STextStyles.body(context),
          decoration: InputDecoration(
            hintText: "Host or IP address",
            fillColor: _hostFocusNode.hasFocus
                ? Theme.of(context).extension<StackColors>()!.textFieldActiveBG
                : Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldDefaultBG,
            isCollapsed: true,
            hintStyle: STextStyles.body(context).copyWith(
              color: Theme.of(context).extension<StackColors>()!.textMedium,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 0),
              child: UnconstrainedBox(
                child: Row(
                  children: [
                    if (!widget.readOnly && _hostController.text.isNotEmpty)
                      TextFieldIconButton(
                        child: const XIcon(),
                        onTap: () async {
                          _hostController.text = "";
                          _updateState();
                        },
                      ),
                    const SizedBox(
                      height: 40,
                    ),
                  ],
                ),
              ),
            ),
          ),
          onChanged: (newValue) {
            if (newValue.startsWith("https://")) {
              _useSSL = true;
              enableSSLCheckbox = false;
            } else if (newValue.startsWith("http://")) {
              _useSSL = false;
              enableSSLCheckbox = false;
            } else {
              enableSSLCheckbox = true;
            }

            _updateState();
            setState(() {});
          },
        ),
        const SizedBox(
          height: 16,
        ),
        TextField(
          textAlignVertical: TextAlignVertical.center,
          autocorrect: false,
          enableSuggestions: false,
          key: const Key("addCustomNodeNodePortFieldKey"),
          readOnly: widget.readOnly,
          enabled: enableField(_portController),
          controller: _portController,
          focusNode: _portFocusNode,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          keyboardType: TextInputType.number,
          style: STextStyles.body(context),
          decoration: InputDecoration(
            hintText: "Port",
            fillColor: _portFocusNode.hasFocus
                ? Theme.of(context).extension<StackColors>()!.textFieldActiveBG
                : Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldDefaultBG,
            isCollapsed: true,
            hintStyle: STextStyles.body(context).copyWith(
              color: Theme.of(context).extension<StackColors>()!.textMedium,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 0),
              child: UnconstrainedBox(
                child: Row(
                  children: [
                    if (!widget.readOnly && _portController.text.isNotEmpty)
                      TextFieldIconButton(
                        child: const XIcon(),
                        onTap: () async {
                          _portController.text = "";
                          _updateState();
                        },
                      ),
                    const SizedBox(
                      height: 40,
                    ),
                  ],
                ),
              ),
            ),
          ),
          onChanged: (newValue) {
            _updateState();
            setState(() {});
          },
        ),
        const SizedBox(
          height: 16,
        ),
        if (enableAuthFields)
          TextField(
            textAlignVertical: TextAlignVertical.center,
            autocorrect: false,
            enableSuggestions: false,
            controller: _usernameController,
            readOnly: widget.readOnly,
            enabled: enableField(_usernameController),
            keyboardType: TextInputType.number,
            focusNode: _usernameFocusNode,
            style: STextStyles.body(context),
            decoration: InputDecoration(
              hintText: "Login (optional)",
              fillColor: _usernameFocusNode.hasFocus
                  ? Theme.of(context)
                      .extension<StackColors>()!
                      .textFieldActiveBG
                  : Theme.of(context)
                      .extension<StackColors>()!
                      .textFieldDefaultBG,
              isCollapsed: true,
              hintStyle: STextStyles.body(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textMedium,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 0),
                child: UnconstrainedBox(
                  child: Row(
                    children: [
                      if (!widget.readOnly &&
                          _usernameController.text.isNotEmpty)
                        TextFieldIconButton(
                          child: const XIcon(),
                          onTap: () async {
                            _usernameController.text = "";
                            _updateState();
                          },
                        ),
                      const SizedBox(
                        height: 40,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            onChanged: (newValue) {
              _updateState();
              setState(() {});
            },
          ),
        if (enableAuthFields)
          const SizedBox(
            height: 16,
          ),
        if (enableAuthFields)
          TextField(
            textAlignVertical: TextAlignVertical.center,
            autocorrect: false,
            enableSuggestions: false,
            controller: _passwordController,
            readOnly: widget.readOnly,
            enabled: enableField(_passwordController),
            keyboardType: TextInputType.number,
            focusNode: _passwordFocusNode,
            style: STextStyles.body(context),
            obscureText: true,
            obscuringCharacter: "•",
            decoration: InputDecoration(
              hintText: "Password (optional)",
              fillColor: _passwordFocusNode.hasFocus
                  ? Theme.of(context)
                      .extension<StackColors>()!
                      .textFieldActiveBG
                  : Theme.of(context)
                      .extension<StackColors>()!
                      .textFieldDefaultBG,
              isCollapsed: true,
              hintStyle: STextStyles.body(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textMedium,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 0),
                child: UnconstrainedBox(
                  child: Row(
                    children: [
                      if (!widget.readOnly &&
                          _passwordController.text.isNotEmpty)
                        TextFieldIconButton(
                          child: const XIcon(),
                          onTap: () async {
                            _passwordController.text = "";
                            _updateState();
                          },
                        ),
                      const SizedBox(
                        height: 40,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            onChanged: (newValue) {
              _updateState();
              setState(() {});
            },
          ),
        if (enableAuthFields)
          const SizedBox(
            height: 16,
          ),
        Row(
          children: [
            GestureDetector(
              onTap: !widget.readOnly && enableSSLCheckbox
                  ? () {
                      setState(() {
                        _useSSL = !_useSSL;
                      });
                      _updateState();
                    }
                  : null,
              child: Container(
                color: Colors.transparent,
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        fillColor: widget.readOnly
                            ? MaterialStateProperty.all(Theme.of(context)
                                .extension<StackColors>()!
                                .checkboxBGDisabled)
                            : null,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        value: _useSSL,
                        onChanged: !widget.readOnly && enableSSLCheckbox
                            ? (newValue) {
                                setState(() {
                                  _useSSL = newValue!;
                                });
                                _updateState();
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(
                      "Use SSL",
                      style: STextStyles.itemSubtitle12(context),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
