import 'dart:async';

import 'package:epicpay/models/epicbox_model.dart';
import 'package:epicpay/providers/providers.dart';
import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/constants.dart';
import 'package:epicpay/utilities/enums/coin_enum.dart';
import 'package:epicpay/utilities/flutter_secure_storage_interface.dart';
import 'package:epicpay/utilities/test_epic_box_connection.dart';
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

enum AddEditEpicBoxViewType { add, edit }

class AddEditEpicBoxView extends ConsumerStatefulWidget {
  const AddEditEpicBoxView({
    Key? key,
    required this.viewType,
    required this.epicBoxId,
    required this.routeOnSuccessOrDelete,
    this.secureStore = const SecureStorageWrapper(
      FlutterSecureStorage(),
    ),
  }) : super(key: key);

  static const String routeName = "/addEditEpicBox";

  final AddEditEpicBoxViewType viewType;
  final String routeOnSuccessOrDelete;
  final String? epicBoxId;
  final FlutterSecureStorageInterface secureStore;

  @override
  ConsumerState<AddEditEpicBoxView> createState() => _AddEditEpicBoxViewState();
}

class _AddEditEpicBoxViewState extends ConsumerState<AddEditEpicBoxView>
    with SingleTickerProviderStateMixin {
  late final AddEditEpicBoxViewType viewType;
  late final String? epicBoxId;

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
                                  : "Could not connect. Please try again or use a different Epic Box server.",
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

  Future<EpicBoxFormData?> _testConnection(
      {bool showNotification = true}) async {
    final formData =
        await testEpicBoxConnection(ref.read(epicBoxFormDataProvider));

    if (showNotification && mounted) {
      unawaited(
        showTestResult(context, formData != null),
      );
    }

    return formData;
  }

  Future<void> attemptSave() async {
    EpicBoxFormData? formData = await _testConnection(showNotification: false);
    final canConnect = formData != null;

    bool? shouldSave;

    if (!canConnect) {
      await showDialog<dynamic>(
        context: context,
        useSafeArea: true,
        barrierDismissible: true,
        builder: (_) => StackDialog(
          title: "Server currently unreachable",
          message: "Would you like to save this Epic Box server anyways?",
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
      formData = ref.read(epicBoxFormDataProvider);
    }

    switch (viewType) {
      case AddEditEpicBoxViewType.add:
        EpicBoxModel epicBox = EpicBoxModel(
          host: formData!.host!,
          port: formData.port!,
          name: formData.name!,
          id: const Uuid().v1(),
          useSSL: formData.useSSL!,
          enabled: true,
          isFailover: formData.isFailover!,
          isDown: false,
        );

        await ref.read(nodeServiceChangeNotifierProvider).addEpicBox(
              epicBox,
              true,
            );
        if (mounted) {
          Navigator.of(context)
              .popUntil(ModalRoute.withName(widget.routeOnSuccessOrDelete));
        }
        break;
      case AddEditEpicBoxViewType.edit:
        EpicBoxModel epicBox = EpicBoxModel(
          host: formData!.host!,
          port: formData.port!,
          name: formData.name!,
          id: epicBoxId!,
          useSSL: formData.useSSL!,
          enabled: true,
          isFailover: formData.isFailover!,
          isDown: false,
        );

        await ref.read(nodeServiceChangeNotifierProvider).addEpicBox(
              epicBox,
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
                                      .deleteEpicBox(
                                        epicBoxId!,
                                        true,
                                      );
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  width: constraints.minWidth,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      "Delete server",
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
    ref.refresh(epicBoxFormDataProvider);
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    animation = CurveTween(
      curve: Curves.bounceInOut,
    ).animate(animationController);
    viewType = widget.viewType;
    epicBoxId = widget.epicBoxId;

    if (epicBoxId == null) {
      saveEnabled = false;
      testConnectionEnabled = false;
    } else {
      final epicBox = ref
          .read(nodeServiceChangeNotifierProvider)
          .getEpicBoxById(id: epicBoxId!)!;
      testConnectionEnabled = epicBox.host.isNotEmpty;
      saveEnabled = testConnectionEnabled && epicBox.name.isNotEmpty;
    }

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EpicBoxModel? epicBox =
        viewType == AddEditEpicBoxViewType.edit && epicBoxId != null
            ? ref.watch(nodeServiceChangeNotifierProvider
                .select((value) => value.getEpicBoxById(id: epicBoxId!)))
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
            viewType == AddEditEpicBoxViewType.edit
                ? "Edit server"
                : "Add custom Epic Box server",
            style: STextStyles.titleH4(context),
          ),
          actions: [
            if (viewType == AddEditEpicBoxViewType.edit)
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
                          EpicBoxForm(
                            epicBox: epicBox,
                            readOnly: false,
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

class EpicBoxFormData {
  String? name, host, login, password;
  int? port;
  bool? useSSL, isFailover;

  @override
  String toString() {
    return "{ name: $name, host: $host, port: $port, useSSL: $useSSL }";
  }
}

final epicBoxFormDataProvider =
    Provider<EpicBoxFormData>((_) => EpicBoxFormData());

class EpicBoxForm extends ConsumerStatefulWidget {
  const EpicBoxForm({
    Key? key,
    this.epicBox,
    required this.readOnly,
    this.onChanged,
  }) : super(key: key);

  final EpicBoxModel? epicBox;
  final bool readOnly;
  final void Function(bool canSave, bool canTestConnection)? onChanged;

  @override
  ConsumerState<EpicBoxForm> createState() => _EpicBoxFormState();
}

class _EpicBoxFormState extends ConsumerState<EpicBoxForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _passwordController;
  late final TextEditingController _usernameController;

  final _nameFocusNode = FocusNode();
  final _portFocusNode = FocusNode();
  final _hostFocusNode = FocusNode();

  bool _useSSL = false;
  bool _isFailover = false;
  int? port;
  late bool enableSSLCheckbox;

  void Function(bool canSave, bool canTestConnection)? onChanged;

  bool _checkShouldEnableAuthFields(Coin coin) {
    // switch (coin) {
    //   case Coin.epicCash:
    //     return true;
    // }
    return false;
  }

  bool get canSave {
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
    ref.read(epicBoxFormDataProvider).name = _nameController.text;
    ref.read(epicBoxFormDataProvider).host = _hostController.text;

    ref.read(epicBoxFormDataProvider).port = port;
    ref.read(epicBoxFormDataProvider).useSSL = _useSSL;
    ref.read(epicBoxFormDataProvider).isFailover = _isFailover;
    setState(() {});
  }

  @override
  void initState() {
    onChanged = widget.onChanged;
    _nameController = TextEditingController();
    _hostController = TextEditingController();
    _portController = TextEditingController();
    _usernameController = TextEditingController();

    if (widget.epicBox != null) {
      final epicBox = widget.epicBox!;
      _nameController.text = epicBox.name;
      _hostController.text = epicBox.host;
      _portController.text = epicBox.port.toString();
      _useSSL = epicBox.useSSL ?? true;
      _isFailover = epicBox.isFailover ?? true;
      enableSSLCheckbox = epicBox.host.startsWith("https");

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // update provider state object so test connection works without having to modify a field in the ui first
        _updateState();
      });
    } else {
      enableSSLCheckbox = true;
    }

    super.initState();
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
    return Column(
      children: [
        TextField(
          textAlignVertical: TextAlignVertical.center,
          autocorrect: false,
          enableSuggestions: false,
          key: const Key("addCustomEpicBoxEpicBoxNameFieldKey"),
          readOnly: widget.readOnly,
          enabled: enableField(_nameController),
          controller: _nameController,
          focusNode: _nameFocusNode,
          style: STextStyles.body(context),
          decoration: InputDecoration(
            hintText: "Server name",
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
          key: const Key("addCustomEpicBoxEpicBoxAddressFieldKey"),
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
          key: const Key("addCustomEpicBoxEpicBoxPortFieldKey"),
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
        // const SizedBox(
        //   height: 16,
        // ),
        // Row(
        //   children: [
        //     GestureDetector(
        //       onTap: !widget.readOnly && enableSSLCheckbox
        //           ? () {
        //               setState(() {
        //                 _useSSL = !_useSSL;
        //               });
        //               _updateState();
        //             }
        //           : null,
        //       child: Container(
        //         color: Colors.transparent,
        //         child: Row(
        //           children: [
        //             SizedBox(
        //               width: 20,
        //               height: 20,
        //               child: Checkbox(
        //                 fillColor: widget.readOnly
        //                     ? MaterialStateProperty.all(Theme.of(context)
        //                         .extension<StackColors>()!
        //                         .checkboxBGDisabled)
        //                     : null,
        //                 materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        //                 value: _useSSL,
        //                 onChanged: !widget.readOnly && enableSSLCheckbox
        //                     ? (newValue) {
        //                         setState(() {
        //                           _useSSL = newValue!;
        //                         });
        //                         _updateState();
        //                       }
        //                     : null,
        //               ),
        //             ),
        //             const SizedBox(
        //               width: 12,
        //             ),
        //             Text(
        //               "Use SSL",
        //               style: STextStyles.itemSubtitle12(context),
        //             )
        //           ],
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }
}
