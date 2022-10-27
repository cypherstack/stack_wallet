import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/electrumx_rpc/electrumx.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/providers/global/node_service_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/test_epic_box_connection.dart';
import 'package:stackwallet/utilities/test_monero_node_connection.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';
import 'package:uuid/uuid.dart';

import 'package:stackwallet/utilities/util.dart';

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

class _AddEditNodeViewState extends ConsumerState<AddEditNodeView> {
  late final AddEditNodeViewType viewType;
  late final Coin coin;
  late final String? nodeId;

  late bool saveEnabled;
  late bool testConnectionEnabled;

  Future<bool> _testConnection({bool showFlushBar = true}) async {
    final formData = ref.read(nodeFormDataProvider);

    bool testPassed = false;

    switch (coin) {
      case Coin.epicCash:
        try {
          final uri = Uri.parse(formData.host!);
          if (uri.scheme.startsWith("http")) {
            final String path = uri.path.isEmpty ? "/v1/version" : uri.path;

            String uriString =
                "${uri.scheme}://${uri.host}:${formData.port ?? 0}$path";

            if (uri.host == "https") {
              ref.read(nodeFormDataProvider).useSSL = true;
            } else {
              ref.read(nodeFormDataProvider).useSSL = false;
            }

            testPassed = await testEpicBoxNodeConnection(Uri.parse(uriString));
          }
        } catch (e, s) {
          Logging.instance.log("$e\n$s", level: LogLevel.Warning);
        }
        break;

      case Coin.monero:
      case Coin.wownero:
        try {
          final uri = Uri.parse(formData.host!);
          if (uri.scheme.startsWith("http")) {
            final String path = uri.path.isEmpty ? "/json_rpc" : uri.path;

            String uriString =
                "${uri.scheme}://${uri.host}:${formData.port ?? 0}$path";

            if (uri.host == "https") {
              ref.read(nodeFormDataProvider).useSSL = true;
            } else {
              ref.read(nodeFormDataProvider).useSSL = false;
            }

            testPassed = await testMoneroNodeConnection(Uri.parse(uriString));
          }
        } catch (e, s) {
          Logging.instance.log("$e\n$s", level: LogLevel.Warning);
        }

        break;

      case Coin.bitcoin:
      case Coin.bitcoincash:
      case Coin.dogecoin:
      case Coin.firo:
      case Coin.namecoin:
      case Coin.bitcoinTestNet:
      case Coin.bitcoincashTestnet:
      case Coin.firoTestNet:
      case Coin.dogecoinTestNet:
        final client = ElectrumX(
          host: formData.host!,
          port: formData.port!,
          useSSL: formData.useSSL!,
          failovers: [],
          prefs: ref.read(prefsChangeNotifierProvider),
        );

        try {
          testPassed = await client.ping();
        } catch (_) {
          testPassed = false;
        }

        break;
    }

    if (showFlushBar) {
      if (testPassed) {
        unawaited(showFloatingFlushBar(
          type: FlushBarType.success,
          message: "Server ping success",
          context: context,
        ));
      } else {
        unawaited(showFloatingFlushBar(
          type: FlushBarType.warning,
          message: "Server unreachable",
          context: context,
        ));
      }
    }

    return testPassed;
  }

  @override
  void initState() {
    ref.refresh(nodeFormDataProvider);

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

    return Scaffold(
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
        title: Text(
          viewType == AddEditNodeViewType.edit ? "Edit node" : "Add node",
          style: STextStyles.navBarTitle(context),
        ),
        actions: [
          if (viewType == AddEditNodeViewType.edit)
            Padding(
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 10,
                right: 10,
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: AppBarIconButton(
                  key: const Key("deleteNodeAppBarButtonKey"),
                  size: 36,
                  shadows: const [],
                  color: Theme.of(context).extension<StackColors>()!.background,
                  icon: SvgPicture.asset(
                    Assets.svg.trash,
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .accentColorDark,
                    width: 20,
                    height: 20,
                  ),
                  onPressed: () async {
                    Navigator.popUntil(context,
                        ModalRoute.withName(widget.routeOnSuccessOrDelete));

                    await ref.read(nodeServiceChangeNotifierProvider).delete(
                          nodeId!,
                          true,
                        );
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
                        TextButton(
                          onPressed: testConnectionEnabled
                              ? () async {
                                  await _testConnection();
                                }
                              : null,
                          style: Theme.of(context)
                              .extension<StackColors>()!
                              .getSecondaryEnabledButtonColor(context),
                          child: Text(
                            "Test connection",
                            style: STextStyles.button(context).copyWith(
                              color: testConnectionEnabled
                                  ? Theme.of(context)
                                      .extension<StackColors>()!
                                      .textDark
                                  : Theme.of(context)
                                      .extension<StackColors>()!
                                      .textWhite,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          style: saveEnabled
                              ? Theme.of(context)
                                  .extension<StackColors>()!
                                  .getPrimaryEnabledButtonColor(context)
                              : Theme.of(context)
                                  .extension<StackColors>()!
                                  .getPrimaryDisabledButtonColor(context),
                          onPressed: saveEnabled
                              ? () async {
                                  final canConnect = await _testConnection(
                                      showFlushBar: false);

                                  bool? shouldSave;

                                  if (!canConnect) {
                                    await showDialog<dynamic>(
                                      context: context,
                                      useSafeArea: true,
                                      barrierDismissible: true,
                                      builder: (_) => StackDialog(
                                        title: "Server currently unreachable",
                                        message:
                                            "Would you like to save this node anyways?",
                                        leftButton: TextButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop(false);
                                          },
                                          child: Text(
                                            "Cancel",
                                            style: STextStyles.button(context)
                                                .copyWith(
                                                    color: Theme.of(context)
                                                        .extension<
                                                            StackColors>()!
                                                        .accentColorDark),
                                          ),
                                        ),
                                        rightButton: TextButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop(true);
                                          },
                                          style: Theme.of(context)
                                              .extension<StackColors>()!
                                              .getPrimaryEnabledButtonColor(
                                                  context),
                                          child: Text(
                                            "Save",
                                            style: STextStyles.button(context),
                                          ),
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

                                  final formData =
                                      ref.read(nodeFormDataProvider);

                                  // strip unused path
                                  String address = formData.host!;
                                  if (coin == Coin.monero ||
                                      coin == Coin.wownero ||
                                      coin == Coin.epicCash) {
                                    if (address.startsWith("http")) {
                                      final uri = Uri.parse(address);
                                      address = "${uri.scheme}://${uri.host}";
                                    }
                                  }

                                  switch (viewType) {
                                    case AddEditNodeViewType.add:
                                      NodeModel node = NodeModel(
                                        host: address,
                                        port: formData.port!,
                                        name: formData.name!,
                                        id: const Uuid().v1(),
                                        useSSL: formData.useSSL!,
                                        loginName: formData.login,
                                        enabled: true,
                                        coinName: coin.name,
                                        isFailover: formData.isFailover!,
                                        isDown: false,
                                      );

                                      await ref
                                          .read(
                                              nodeServiceChangeNotifierProvider)
                                          .add(
                                            node,
                                            formData.password,
                                            true,
                                          );
                                      if (mounted) {
                                        Navigator.of(context).popUntil(
                                            ModalRoute.withName(
                                                widget.routeOnSuccessOrDelete));
                                      }
                                      break;
                                    case AddEditNodeViewType.edit:
                                      NodeModel node = NodeModel(
                                        host: address,
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

                                      await ref
                                          .read(
                                              nodeServiceChangeNotifierProvider)
                                          .add(
                                            node,
                                            formData.password,
                                            true,
                                          );
                                      if (mounted) {
                                        Navigator.of(context).popUntil(
                                            ModalRoute.withName(
                                                widget.routeOnSuccessOrDelete));
                                      }
                                      break;
                                  }
                                }
                              : null,
                          child: Text(
                            "Save",
                            style: STextStyles.button(context),
                          ),
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

  late final bool enableAuthFields;

  void Function(bool canSave, bool canTestConnection)? onChanged;

  bool _checkShouldEnableAuthFields(Coin coin) {
    // TODO: which coin servers can have username and password?
    switch (coin) {
      case Coin.bitcoin:
      case Coin.dogecoin:
      case Coin.firo:
      case Coin.namecoin:
      case Coin.bitcoincash:
      case Coin.bitcoinTestNet:
      case Coin.bitcoincashTestnet:
      case Coin.firoTestNet:
      case Coin.dogecoinTestNet:
        return false;

      case Coin.epicCash:
      case Coin.monero:
      case Coin.wownero:
        return true;
    }
  }

  bool get canSave {
    // 65535 is max tcp port
    return _nameController.text.isNotEmpty && canTestConnection;
  }

  bool get canTestConnection {
    // 65535 is max tcp port
    return _hostController.text.isNotEmpty &&
        port != null &&
        port! >= 0 &&
        port! <= 65535;
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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // update provider state object so test connection works without having to modify a field in the ui first
        _updateState();
      });
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
        ClipRRect(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
          child: TextField(
            autocorrect: Util.isDesktop ? false : true,
            enableSuggestions: Util.isDesktop ? false : true,
            key: const Key("addCustomNodeNodeNameFieldKey"),
            readOnly: widget.readOnly,
            enabled: enableField(_nameController),
            controller: _nameController,
            focusNode: _nameFocusNode,
            style: STextStyles.field(context),
            decoration: standardInputDecoration(
              "Node name",
              _nameFocusNode,
              context,
            ).copyWith(
              suffixIcon: !widget.readOnly && _nameController.text.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(right: 0),
                      child: UnconstrainedBox(
                        child: Row(
                          children: [
                            TextFieldIconButton(
                              child: const XIcon(),
                              onTap: () async {
                                _nameController.text = "";
                                _updateState();
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
            ),
            onChanged: (newValue) {
              _updateState();
              setState(() {});
            },
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
                child: TextField(
                  autocorrect: Util.isDesktop ? false : true,
                  enableSuggestions: Util.isDesktop ? false : true,
                  key: const Key("addCustomNodeNodeAddressFieldKey"),
                  readOnly: widget.readOnly,
                  enabled: enableField(_hostController),
                  controller: _hostController,
                  focusNode: _hostFocusNode,
                  style: STextStyles.field(context),
                  decoration: standardInputDecoration(
                    (widget.coin != Coin.monero &&
                            widget.coin != Coin.wownero &&
                            widget.coin != Coin.epicCash)
                        ? "IP address"
                        : "Url",
                    _hostFocusNode,
                    context,
                  ).copyWith(
                    suffixIcon:
                        !widget.readOnly && _hostController.text.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(right: 0),
                                child: UnconstrainedBox(
                                  child: Row(
                                    children: [
                                      TextFieldIconButton(
                                        child: const XIcon(),
                                        onTap: () async {
                                          _hostController.text = "";
                                          _updateState();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : null,
                  ),
                  onChanged: (newValue) {
                    _updateState();
                    setState(() {});
                  },
                ),
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
                child: TextField(
                  autocorrect: Util.isDesktop ? false : true,
                  enableSuggestions: Util.isDesktop ? false : true,
                  key: const Key("addCustomNodeNodePortFieldKey"),
                  readOnly: widget.readOnly,
                  enabled: enableField(_portController),
                  controller: _portController,
                  focusNode: _portFocusNode,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  keyboardType: TextInputType.number,
                  style: STextStyles.field(context),
                  decoration: standardInputDecoration(
                    "Port",
                    _portFocusNode,
                    context,
                  ).copyWith(
                    suffixIcon:
                        !widget.readOnly && _portController.text.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(right: 0),
                                child: UnconstrainedBox(
                                  child: Row(
                                    children: [
                                      TextFieldIconButton(
                                        child: const XIcon(),
                                        onTap: () async {
                                          _portController.text = "";
                                          _updateState();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : null,
                  ),
                  onChanged: (newValue) {
                    _updateState();
                    setState(() {});
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 8,
        ),
        if (enableAuthFields)
          ClipRRect(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
            child: TextField(
              autocorrect: Util.isDesktop ? false : true,
              enableSuggestions: Util.isDesktop ? false : true,
              controller: _usernameController,
              readOnly: widget.readOnly,
              enabled: enableField(_usernameController),
              keyboardType: TextInputType.number,
              focusNode: _usernameFocusNode,
              style: STextStyles.field(context),
              decoration: standardInputDecoration(
                "Login (optional)",
                _usernameFocusNode,
                context,
              ).copyWith(
                suffixIcon:
                    !widget.readOnly && _usernameController.text.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(right: 0),
                            child: UnconstrainedBox(
                              child: Row(
                                children: [
                                  TextFieldIconButton(
                                    child: const XIcon(),
                                    onTap: () async {
                                      _usernameController.text = "";
                                      _updateState();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )
                        : null,
              ),
              onChanged: (newValue) {
                _updateState();
                setState(() {});
              },
            ),
          ),
        if (enableAuthFields)
          const SizedBox(
            height: 8,
          ),
        if (enableAuthFields)
          ClipRRect(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
            child: TextField(
              autocorrect: Util.isDesktop ? false : true,
              enableSuggestions: Util.isDesktop ? false : true,
              controller: _passwordController,
              readOnly: widget.readOnly,
              enabled: enableField(_passwordController),
              keyboardType: TextInputType.number,
              focusNode: _passwordFocusNode,
              style: STextStyles.field(context),
              decoration: standardInputDecoration(
                "Password (optional)",
                _passwordFocusNode,
                context,
              ).copyWith(
                suffixIcon:
                    !widget.readOnly && _passwordController.text.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(right: 0),
                            child: UnconstrainedBox(
                              child: Row(
                                children: [
                                  TextFieldIconButton(
                                    child: const XIcon(),
                                    onTap: () async {
                                      _passwordController.text = "";
                                      _updateState();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )
                        : null,
              ),
              onChanged: (newValue) {
                _updateState();
                setState(() {});
              },
            ),
          ),
        if (enableAuthFields)
          const SizedBox(
            height: 8,
          ),
        if (widget.coin != Coin.monero &&
            widget.coin != Coin.wownero &&
            widget.coin != Coin.epicCash)
          Row(
            children: [
              GestureDetector(
                onTap: widget.readOnly
                    ? null
                    : () {
                        setState(() {
                          _useSSL = !_useSSL;
                        });
                        _updateState();
                      },
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
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          value: _useSSL,
                          onChanged: widget.readOnly
                              ? null
                              : (newValue) {
                                  setState(() {
                                    _useSSL = newValue!;
                                  });
                                  _updateState();
                                },
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
        if (widget.coin != Coin.monero &&
            widget.coin != Coin.wownero &&
            widget.coin != Coin.epicCash)
          const SizedBox(
            height: 8,
          ),
        if (widget.coin != Coin.monero &&
            widget.coin != Coin.wownero &&
            widget.coin != Coin.epicCash)
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isFailover = !_isFailover;
                  });
                  if (widget.readOnly) {
                    ref.read(nodeServiceChangeNotifierProvider).edit(
                          widget.node!.copyWith(isFailover: _isFailover),
                          null,
                          true,
                        );
                  } else {
                    _updateState();
                  }
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
                          value: _isFailover,
                          onChanged: (newValue) {
                            setState(() {
                              _isFailover = newValue!;
                            });
                            if (widget.readOnly) {
                              ref.read(nodeServiceChangeNotifierProvider).edit(
                                    widget.node!
                                        .copyWith(isFailover: _isFailover),
                                    null,
                                    true,
                                  );
                            } else {
                              _updateState();
                            }
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Text(
                        "Use as failover",
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
