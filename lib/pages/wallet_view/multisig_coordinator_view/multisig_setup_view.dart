import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../themes/stack_colors.dart';
import '../../../../utilities/assets.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../utilities/util.dart';
import '../../../../widgets/background.dart';
import '../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../widgets/custom_buttons/blue_text_button.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/dialogs/simple_mobile_dialog.dart';
import '../../../widgets/stack_dialog.dart';
import 'multisig_coordinator_view.dart';

final multisigSetupStateProvider =
    StateNotifierProvider<MultisigSetupState, MultisigSetupData>((ref) {
  return MultisigSetupState();
});

class MultisigSetupData {
  // These default values are overridden by the inputs' onChanged methods.
  const MultisigSetupData({
    this.threshold = 2,
    this.participants = 3,
    this.coinType = 0, // Bitcoin mainnet.
    this.account = 0,
    this.scriptType = MultisigScriptType.nativeSegwit,
    this.cosignerXpubs = const [],
  });

  final int threshold;
  final int participants;
  final int coinType;
  final int account;
  final MultisigScriptType scriptType;
  final List<String> cosignerXpubs;

  MultisigSetupData copyWith({
    int? threshold,
    int? participants,
    int? coinType,
    int? account,
    MultisigScriptType? scriptType,
    List<String>? cosignerXpubs,
  }) {
    return MultisigSetupData(
      threshold: threshold ?? this.threshold,
      participants: participants ?? this.participants,
      coinType: coinType ?? this.coinType,
      account: account ?? this.account,
      scriptType: scriptType ?? this.scriptType,
      cosignerXpubs: cosignerXpubs ?? this.cosignerXpubs,
    );
  }

  Map<String, dynamic> toJson() => {
        'threshold': threshold,
        'participants': participants,
        'coinType': coinType,
        'account': account,
        'scriptType': scriptType.index,
        'cosignerXpubs': cosignerXpubs,
      };

  factory MultisigSetupData.fromJson(Map<String, dynamic> json) {
    return MultisigSetupData(
      threshold: json['threshold'] as int,
      participants: json['participants'] as int,
      coinType: json['coinType'] as int,
      account: json['account'] as int,
      scriptType: MultisigScriptType.values[json['scriptType'] as int],
      cosignerXpubs: (json['cosignerXpubs'] as List).cast<String>(),
    );
  }
}

class MultisigSetupState extends StateNotifier<MultisigSetupData> {
  MultisigSetupState() : super(const MultisigSetupData());

  void updateThreshold(int threshold) {
    state = state.copyWith(threshold: threshold);
  }

  void updateParticipants(int total) {
    state = state.copyWith(participants: total);
  }

  void updateScriptType(MultisigScriptType type) {
    state = state.copyWith(scriptType: type);
  }

  void addCosignerXpub(String xpub) {
    if (state.cosignerXpubs.length < state.participants) {
      state = state.copyWith(
        cosignerXpubs: [...state.cosignerXpubs, xpub],
      );
    }
  }
}

class MultisigSetupView extends ConsumerStatefulWidget {
  const MultisigSetupView({
    super.key,
    required this.walletId,
    this.scriptType,
    this.participants,
    this.threshold,
    this.account,
  });

  final String walletId;
  final MultisigScriptType? scriptType;
  final int? participants;
  final int? threshold;
  final int? account;

  static const String routeName = "/multisigSetup";

  @override
  ConsumerState<MultisigSetupView> createState() => _MultisigSetupViewState();
}

class _MultisigSetupViewState extends ConsumerState<MultisigSetupView> {
  @override
  void initState() {
    super.initState();

    // Initialize participants count if provided.
    if (widget.participants != null) {
      _participantsCount = widget.participants!;
      _participantsController.text = widget.participants!.toString();
      // Initialize the controllers list.
      for (int i = 0; i < widget.participants!; i++) {
        controllers.add(TextEditingController());
      }
    }

    // Initialize threshold if provided.
    if (widget.threshold != null) {
      _thresholdController.text = widget.threshold!.toString();
    }
  }

  /// Displays a short explanation dialog about musig.
  Future<void> _showMultisigInfoDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return const StackOkDialog(
          title: "What is a multisignature account?",
          message:
              "Multisignature accounts, also called shared accounts, require "
              "multiple signatures to authorize a transaction.  This can "
              "increase security by preventing a single point of failure or "
              "allow multiple parties to jointly control funds."
              "For example, in a 2-of-3 multisig account, two of the three "
              "cosigners are required in order to sign a transaction and spend "
              "funds.",
        );
      },
    );
  }

  void _showScriptTypeDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => SimpleMobileDialog(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What is a script type?",
              style: STextStyles.w600_20(context),
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              "The script type you choose determines the type of wallet "
              "addresses and the size and structure of transactions.",
              style: STextStyles.w400_16(context),
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              "Legacy (P2SH):",
              style: STextStyles.w600_18(context),
            ),
            Text(
              "The original multisig format. Compatible with all wallets but has "
              "higher transaction fees.  P2SH addresses begin with 3.",
              style: STextStyles.w400_16(context),
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              "Nested SegWit (P2SH-P2WSH):",
              style: STextStyles.w600_18(context),
            ),
            Text(
              "A newer format that reduces transaction fees while maintaining "
              "broad compatibility.  P2SH-P2WSH addresses begin with 3.",
              style: STextStyles.w400_16(context),
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              "Native SegWit (P2WSH):",
              style: STextStyles.w600_18(context),
            ),
            Text(
              "The lowest transaction fees, but may not be compatible with older "
              "wallets.  P2WSH addresses begin with bc1.",
              style: STextStyles.w400_16(context),
            ),
          ],
        ),
      ),
    );
  }

  final _thresholdController = TextEditingController();
  final _participantsController = TextEditingController();
  final _accountController = TextEditingController();

  final List<TextEditingController> controllers = [];

  int _participantsCount = 0;

  String _validateInputData() {
    final threshold = int.tryParse(_thresholdController.text);
    if (threshold == null) {
      return "Choose a threshold";
    }

    final partsCount = int.tryParse(_participantsController.text);
    if (partsCount == null) {
      return "Choose total number of participants";
    }

    if (threshold > partsCount) {
      return "Threshold cannot be greater than the number of participants";
    }

    if (partsCount < 2) {
      return "At least two participants required";
    }

    if (controllers.length != partsCount) {
      return "Participants count error";
    }

    if (_accountController.text.isEmpty) {
      return "Choose an account (0 is OK)";
    }

    return "valid";
  }

  void _participantsCountChanged(String newValue) {
    final count = int.tryParse(newValue);
    if (count != null) {
      if (count > _participantsCount) {
        for (int i = _participantsCount; i < count; i++) {
          controllers.add(TextEditingController());
        }

        _participantsCount = count;
        setState(() {});
      } else if (count < _participantsCount) {
        for (int i = _participantsCount; i > count; i--) {
          final last = controllers.removeLast();
          last.dispose();
        }

        _participantsCount = count;
        setState(() {});
      }
    }
  }

  void _showWhatIsThresholdDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => SimpleMobileDialog(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What is a threshold?",
              style: STextStyles.w600_20(context),
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              "A threshold is the amount of people required to perform an "
              "action. This does not have to be the same number as the "
              "total number in the group.",
              style: STextStyles.w400_16(context),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              "For example, if you have 3 people in the group, but a threshold "
              "of 2, then you only need 2 out of the 3 people to sign for an "
              "action to take place.",
              style: STextStyles.w400_16(context),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              "Conversely if you have a group of 3 AND a threshold of 3, you "
              "will need all 3 people in the group to sign to approve any "
              "action.",
              style: STextStyles.w400_16(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showWhatIsAccountDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => SimpleMobileDialog(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What is an account?",
              style: STextStyles.w600_20(context),
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              "The account number you choose will determine which extended "
              "public key (xPub) you share with all participants.  If you use "
              "the same xPub across multiple multisignature accounts, a shared "
              "cosigner in any of them will be able to recognize your "
              "participation in them and so your privacy could be degraded.  "
              "For maximum privacy, use a distinct account number for each "
              "multisignature account.",
              style: STextStyles.w400_16(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    _participantsController.dispose();
    _accountController.dispose();
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setupData = ref.watch(multisigSetupStateProvider);
    // final bool isDesktop = Util.isDesktop;

    return Background(
      child: SafeArea(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
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
              "Multisignature account setup",
              style: STextStyles.navBarTitle(context),
            ),
            titleSpacing: 0,
            actions: [
              AspectRatio(
                aspectRatio: 1,
                child: AppBarIconButton(
                  size: 36,
                  icon: SvgPicture.asset(
                    Assets.svg.circleQuestion,
                    width: 20,
                    height: 20,
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .topNavIconPrimary,
                  ),
                  onPressed: _showMultisigInfoDialog,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Configuration",
                  style: STextStyles.itemSubtitle(context),
                ),
                const SizedBox(height: 16),

                // Script type.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Script type",
                          style: STextStyles.w500_14(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark3,
                          ),
                        ),
                        CustomTextButton(
                          text: "What is a script type?",
                          onTap: _showScriptTypeDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<MultisigScriptType>(
                      value: setupData.scriptType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: MultisigScriptType.values.map((type) {
                        String label;
                        switch (type) {
                          // case MultisigScriptType.legacy:
                          //   label = "Legacy (P2SH)";
                          //   break;
                          // BIP48 does not cover legacy P2SH script types.
                          case MultisigScriptType.segwit:
                            label = "Nested SegWit (P2SH-P2WSH)";
                            break;
                          case MultisigScriptType.nativeSegwit:
                            label = "Native SegWit (P2WSH)";
                            break;
                        }
                        return DropdownMenuItem(
                          value: type,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(multisigSetupStateProvider.notifier)
                              .updateScriptType(value);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Threshold, Participants, and Account.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Number of participants",
                      style: STextStyles.w500_14(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textDark3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      controller: _participantsController,
                      onChanged: _participantsCountChanged,
                      decoration: InputDecoration(
                        hintText: "Enter number of participants",
                        hintStyle: STextStyles.fieldLabel(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Threshold",
                          style: STextStyles.w500_14(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark3,
                          ),
                        ),
                        CustomTextButton(
                          text: "What is a threshold?",
                          onTap: _showWhatIsThresholdDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      controller: _thresholdController,
                      decoration: InputDecoration(
                        hintText: "Enter number of signatures",
                        hintStyle: STextStyles.fieldLabel(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Account",
                          style: STextStyles.w500_14(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark3,
                          ),
                        ),
                        CustomTextButton(
                          text: "What is an account?",
                          onTap: _showWhatIsAccountDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      controller: _accountController,
                      decoration: InputDecoration(
                        hintText: "Enter account number",
                        hintStyle: STextStyles.fieldLabel(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // TODO: Push button to bottom of page.
                PrimaryButton(
                  label: "Continue",
                  onPressed: () async {
                    if (FocusScope.of(context).hasFocus) {
                      FocusScope.of(context).unfocus();
                    }

                    final validationMessage = _validateInputData();

                    if (validationMessage != "valid") {
                      return await showDialog<void>(
                        context: context,
                        builder: (_) => StackOkDialog(
                          title: validationMessage,
                          desktopPopRootNavigator: Util.isDesktop,
                        ),
                      );
                    }

                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => MultisigCoordinatorView(
                          walletId: widget.walletId,
                          scriptType: setupData.scriptType,
                          participants: int.parse(_participantsController.text),
                          threshold: int.parse(_thresholdController.text),
                          account: int.parse(_accountController.text),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
