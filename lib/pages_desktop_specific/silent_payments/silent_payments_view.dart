// ignore_for_file: unused_import, prefer_const_constructors, avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:coinlib_flutter/coinlib_flutter.dart';

import '../../notifications/show_flush_bar.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_app_bar.dart';
import '../../widgets/desktop/desktop_scaffold.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/icon_widgets/copy_icon.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/qr.dart';

import 'package:silent_payments/silent_payments.dart';

class SilentPaymentsView extends ConsumerStatefulWidget {
  const SilentPaymentsView({super.key, required this.walletId});

  final String walletId;

  static const String routeName = "/silentPayments";

  @override
  ConsumerState<SilentPaymentsView> createState() => _SilentPaymentsViewState();
}

class _SilentPaymentsViewState extends ConsumerState<SilentPaymentsView> {
  bool _enabled = false;
  bool _isLoading = false;
  bool _isGeneratingKeys = false;

  // Mock silent payment owner
  SilentPaymentOwner? _owner;
  String _silentPaymentAddress = "";
  String _scanPrivateKey = "";
  String _spendPrivateKey = "";

  // Mock send fields
  final TextEditingController _recipientAddressController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // Mock scanning fields
  final TextEditingController _blockHeightController = TextEditingController();
  final List<String> _detectedOutputs = [];

  // Mock debug information
  final Map<String, String> _debugInfo = {};

  @override
  void initState() {
    super.initState();
    _blockHeightController.text = "800000"; // Example block height
    _amountController.text = "0.0001"; // Example amount
  }

  @override
  void dispose() {
    _recipientAddressController.dispose();
    _amountController.dispose();
    _blockHeightController.dispose();
    super.dispose();
  }

  // Generate or regenerate silent payment keys
  Future<void> _generateSilentPaymentKeys() async {
    setState(() {
      _isGeneratingKeys = true;
    });

    // In a real implementation, we would derive these from the wallet seed
    // based on BIP32 derivation paths: m/352'/0'/0'/1'/0 and m/352'/0'/0'/0'/0

    try {
      // Mock implementation - in reality would derive from wallet
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Random seed for demonstration
      final seedHex =
          "39c13fb2c797d1702052abede785a0370c7bc13b7834bea06bfb6b78fc4659d8";
      final seed = Uint8List.fromList(hexToBytes(seedHex));

      // Generate keys from seed
      _owner = SilentPaymentOwner.fromSeed(seed);

      _silentPaymentAddress = _owner!.toString();
      _scanPrivateKey = bytesToHex(_owner!.b_scan.data);
      _spendPrivateKey = bytesToHex(_owner!.b_spend.data);

      // Update debug info
      _debugInfo.clear();
      _debugInfo.addAll({
        "B_scan (Public)": bytesToHex(_owner!.address.B_scan.data),
        "B_spend (Public)": bytesToHex(_owner!.address.B_spend.data),
        "b_scan (Private)": _scanPrivateKey,
        "b_spend (Private)": _spendPrivateKey,
      });

      setState(() {
        _isGeneratingKeys = false;
      });

      if (mounted) {
        await showFloatingFlushBar(
          type: FlushBarType.success,
          message: "Silent Payment keys generated successfully",
          context: context,
        );
      }
    } catch (e) {
      setState(() {
        _isGeneratingKeys = false;
      });

      if (mounted) {
        await showFloatingFlushBar(
          type: FlushBarType.warning,
          message: "Failed to generate Silent Payment keys: ${e.toString()}",
          context: context,
        );
      }
    }
  }

  // Mock sending silent payment
  Future<void> _sendSilentPayment() async {
    final recipientAddress = _recipientAddressController.text.trim();
    final amount = _amountController.text.trim();

    if (recipientAddress.isEmpty) {
      await showFloatingFlushBar(
        type: FlushBarType.warning,
        message: "Please enter a recipient address",
        context: context,
      );
      return;
    }

    if (amount.isEmpty ||
        double.tryParse(amount) == null ||
        double.parse(amount) <= 0) {
      await showFloatingFlushBar(
        type: FlushBarType.warning,
        message: "Please enter a valid amount",
        context: context,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // In a real implementation, this would:
      // 1. Create a transaction with inputs
      // 2. Derive the shared secret
      // 3. Generate output addresses
      // 4. Broadcast the transaction

      await Future<void>.delayed(const Duration(seconds: 1));

      // Mock transaction details for demonstration
      final txDetails = {
        "txid":
            "85a12304f5d6e14ad32b6ebe2cf39f238695c9479c55d6291c2a1fe2c4af56a3",
        "outpoints": [
          "c45fc3c36d30c9b93b288e51ef59f4af6e963d8e100c752b212aeB65db2cc604:0",
          "7ef3c7f4a1e247b47b1fcb075e4639955ea4c9c6674b42b8b858cbf1f738d352:1",
        ],
        "outputs": [
          "bc1p5gv9zay9m8w99dqeyl2p5zazg4fcw4nnfxazqpu8xre8ctmrx7aq5mhzz7",
          "bc1pcqtmhrfe95e5nejx98u6kcfuxz8lnm976lmedrjxvllr4qm5t5tsl7xnw3",
        ],
        "amount": double.parse(amount),
        "fee": 0.00001,
      };

      // Update debug info
      _debugInfo.clear();
      _debugInfo.addAll({
        "Destination": recipientAddress,
        "Amount": "$amount BTC",
        "Transaction ID": txDetails["txid"]! as String,
        "Output Addresses": (txDetails["outputs"] as List<String>).join("\n"),
      });

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        await showFloatingFlushBar(
          type: FlushBarType.success,
          message: "Silent Payment sent successfully!",
          context: context,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        await showFloatingFlushBar(
          type: FlushBarType.warning,
          message: "Failed to send Silent Payment: ${e.toString()}",
          context: context,
        );
      }
    }
  }

  // Mock scanning for received silent payments
  Future<void> _scanForSilentPayments() async {
    if (_owner == null) {
      await showFloatingFlushBar(
        type: FlushBarType.warning,
        message: "Please generate Silent Payment keys first",
        context: context,
      );
      return;
    }

    final blockHeight = _blockHeightController.text.trim();

    if (blockHeight.isEmpty || int.tryParse(blockHeight) == null) {
      await showFloatingFlushBar(
        type: FlushBarType.warning,
        message: "Please enter a valid block height",
        context: context,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _detectedOutputs.clear();
    });

    try {
      // In a real implementation, this would:
      // 1. Fetch block data for the given height
      // 2. Extract transactions
      // 3. For each transaction, calculate outpoints and input public keys
      // 4. Derive shared secrets and scan outputs

      await Future<void>.delayed(const Duration(seconds: 2));

      // Mock detected outputs for demonstration
      if (_enabled) {
        _detectedOutputs.clear();
        _detectedOutputs.addAll([
          "bc1p5cyxm5c6rvfqzkjq40rrs7cnjr9qpkpz0qjmv3qr7v9dhm0rcsqsxp8hx8",
          "bc1pws9t458yt9fq3ae43a9d23l0tp70yd64qme3pdhtg4rkgkut075st7qcux",
        ]);

        // Update debug info
        _debugInfo.clear();
        _debugInfo.addAll({
          "Block Height": blockHeight,
          "Txs Scanned": "285",
          "Inputs Analyzed": "843",
          "Outputs Checked": "976",
          "Shared Secrets": "123",
          "Tagged Hashes": "432",
          "Detection Method": "Shared Secret + Output Tweaking",
        });
      } else {
        _debugInfo.clear();
        _debugInfo.addAll({
          "Status":
              "Scanning disabled - Enable scanning to detect Silent Payments",
        });
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (_enabled) {
          await showFloatingFlushBar(
            type: FlushBarType.success,
            message: "Found ${_detectedOutputs.length} Silent Payment outputs",
            context: context,
          );
        } else {
          await showFloatingFlushBar(
            type: FlushBarType.info,
            message:
                "Scanning disabled - Enable scanning to detect Silent Payments",
            context: context,
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        await showFloatingFlushBar(
          type: FlushBarType.warning,
          message: "Failed to scan for Silent Payments: ${e.toString()}",
          context: context,
        );
      }
    }
  }

  // Helper method to convert hex string to bytes
  List<int> hexToBytes(String hex) {
    List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }

  // Helper method to convert bytes to hex string
  String bytesToHex(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    final isDesktop = true; // Always desktop for now
    final colors = Theme.of(context).extension<StackColors>()!;

    return MasterScaffold(
      isDesktop: isDesktop,
      appBar:
          isDesktop
              ? DesktopAppBar(
                isCompactHeight: true,
                background: colors.popupBG,
                leading: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 24, right: 20),
                      child: AppBarIconButton(
                        size: 32,
                        color: colors.textFieldDefaultBG,
                        shadows: const [],
                        icon: SvgPicture.asset(
                          Assets.svg.arrowLeft,
                          width: 18,
                          height: 18,
                          colorFilter: ColorFilter.mode(
                            colors.topNavIconPrimary,
                            BlendMode.srcIn,
                          ),
                        ),
                        onPressed: Navigator.of(context).pop,
                      ),
                    ),
                    Text(
                      "Silent Payments",
                      style: STextStyles.desktopH3(context),
                    ),
                  ],
                ),
              )
              : AppBar(
                leading: AppBarBackButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                titleSpacing: 0,
                title: Text(
                  "Silent Payments",
                  style: STextStyles.navBarTitle(context),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: colors.accentColorDark),
              )
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top section: Enable scanning and generate keys
                      RoundedWhiteContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Switch(
                                        value: _enabled,
                                        onChanged: (value) {
                                          setState(() {
                                            _enabled = value;
                                          });
                                        },
                                        activeColor: colors.accentColorGreen,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Scan for Silent Payments",
                                        style:
                                            isDesktop
                                                ? STextStyles.desktopTextMedium(
                                                  context,
                                                )
                                                : STextStyles.titleBold12(
                                                  context,
                                                ),
                                      ),
                                    ],
                                  ),
                                ),
                                SecondaryButton(
                                  width: 170,
                                  label: "Generate Keys",
                                  onPressed:
                                      _isGeneratingKeys
                                          ? null
                                          : _generateSilentPaymentKeys,
                                ),
                              ],
                            ),
                            if (_silentPaymentAddress.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                "Your Silent Payment Address:",
                                style: STextStyles.desktopTextSmall(
                                  context,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.textFieldDefaultBG,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _silentPaymentAddress,
                                        style:
                                            STextStyles.desktopTextExtraExtraSmall(
                                              context,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SecondaryButton(
                                    label: "Copy",
                                    buttonHeight: ButtonHeight.xl,
                                    iconSpacing: 8,
                                    icon: CopyIcon(
                                      width: 12,
                                      height: 12,
                                      color:
                                          Theme.of(context)
                                              .extension<StackColors>()!
                                              .buttonTextSecondary,
                                    ),
                                    onPressed: () async {
                                      await Clipboard.setData(
                                        ClipboardData(
                                          text: _silentPaymentAddress,
                                        ),
                                      );
                                      if (mounted) {
                                        await showFloatingFlushBar(
                                          type: FlushBarType.info,
                                          message: "Copied to clipboard",
                                          iconAsset: Assets.svg.copy,
                                          context: context,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_silentPaymentAddress.isNotEmpty)
                                Center(
                                  child: QR(
                                    data: _silentPaymentAddress,
                                    size: 150,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Main two-column layout
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column: Send Silent Payment
                          Expanded(
                            child: RoundedWhiteContainer(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Send Silent Payment",
                                    style: STextStyles.desktopTextMedium(
                                      context,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),

                                  // Recipient address
                                  Text(
                                    "Recipient Address:",
                                    style: STextStyles.desktopTextSmall(
                                      context,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _recipientAddressController,
                                    decoration: InputDecoration(
                                      hintText: "sp1...",
                                      filled: true,
                                      fillColor: colors.textFieldDefaultBG,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    style: STextStyles.desktopTextExtraSmall(
                                      context,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Amount
                                  Text(
                                    "Amount (BTC):",
                                    style: STextStyles.desktopTextSmall(
                                      context,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _amountController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: InputDecoration(
                                      hintText: "0.0001",
                                      filled: true,
                                      fillColor: colors.textFieldDefaultBG,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    style: STextStyles.desktopTextExtraSmall(
                                      context,
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Send button
                                  Center(
                                    child: PrimaryButton(
                                      width: 150,
                                      label: "Send",
                                      onPressed: _sendSilentPayment,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Send process explanation
                                  ExpansionTile(
                                    title: Text(
                                      "How Silent Payments Work (Sending)",
                                      style: STextStyles.desktopTextSmall(
                                        context,
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          "1. Sender gets recipient's Silent Payment address (sp1...)\n"
                                          "2. Sender collects all input public keys (A1, A2, ..., An)\n"
                                          "3. Calculate sum of all input keys: A_sum = A1 + A2 + ... + An\n"
                                          "4. Compute T = SHA256(TaggedHash(lowest_outpoint || A_sum))\n"
                                          "5. Calculate sender partial secret: s = a_sum * T\n"
                                          "6. Extract B_scan from recipient address\n"
                                          "7. Calculate shared secret: S = B_scan * s\n"
                                          "8. For each output i, calculate outputTweak = TaggedHash(S || i)\n"
                                          "9. Generate output address: B_spend + outputTweak\n"
                                          "10. Send payment to derived address",
                                          style:
                                              STextStyles.desktopTextExtraSmall(
                                                context,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 24),

                          // Right column: Receive Silent Payment
                          Expanded(
                            child: RoundedWhiteContainer(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Scan for Received Silent Payments",
                                    style: STextStyles.desktopTextMedium(
                                      context,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),

                                  // Block height
                                  Text(
                                    "Block Height to Scan:",
                                    style: STextStyles.desktopTextSmall(
                                      context,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _blockHeightController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: "800000",
                                      filled: true,
                                      fillColor: colors.textFieldDefaultBG,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    style: STextStyles.desktopTextExtraSmall(
                                      context,
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Scan button
                                  Center(
                                    child: PrimaryButton(
                                      width: 150,
                                      label: "Scan",
                                      onPressed: _scanForSilentPayments,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Detected outputs
                                  if (_detectedOutputs.isNotEmpty) ...[
                                    Text(
                                      "Detected Silent Payment Outputs:",
                                      style: STextStyles.desktopTextSmall(
                                        context,
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: colors.textFieldDefaultBG,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children:
                                            _detectedOutputs.map((output) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        output,
                                                        style:
                                                            STextStyles.desktopTextExtraExtraSmall(
                                                              context,
                                                            ),
                                                      ),
                                                    ),
                                                    SecondaryButton(
                                                      label: "Copy",
                                                      buttonHeight:
                                                          ButtonHeight.s,
                                                      iconSpacing: 4,
                                                      icon: CopyIcon(
                                                        width: 10,
                                                        height: 10,
                                                        color:
                                                            Theme.of(context)
                                                                .extension<
                                                                  StackColors
                                                                >()!
                                                                .buttonTextSecondary,
                                                      ),
                                                      onPressed: () async {
                                                        await Clipboard.setData(
                                                          ClipboardData(
                                                            text: output,
                                                          ),
                                                        );
                                                        if (mounted) {
                                                          await showFloatingFlushBar(
                                                            type:
                                                                FlushBarType
                                                                    .info,
                                                            message:
                                                                "Copied to clipboard",
                                                            iconAsset:
                                                                Assets.svg.copy,
                                                            context: context,
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 16),

                                  // Receive process explanation
                                  ExpansionTile(
                                    title: Text(
                                      "How Silent Payments Work (Receiving)",
                                      style: STextStyles.desktopTextSmall(
                                        context,
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          "1. Recipient scans each transaction in new blocks\n"
                                          "2. For each transaction, compute A_sum from input public keys\n"
                                          "3. Calculate T = SHA256(TaggedHash(lowest_outpoint || A_sum))\n"
                                          "4. Calculate receiver partial secret: r = T * b_scan\n"
                                          "5. Calculate shared secret: S = A_sum * r\n"
                                          "6. For each output i, calculate outputTweak = TaggedHash(S || i)\n"
                                          "7. Derive expected output: B_spend + outputTweak\n"
                                          "8. Check if any transaction outputs match expected addresses\n"
                                          "9. If match found, calculate private key: b_spend + outputTweak",
                                          style:
                                              STextStyles.desktopTextExtraSmall(
                                                context,
                                              ),
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

                      const SizedBox(height: 24),

                      // Debug information section
                      if (_debugInfo.isNotEmpty)
                        RoundedWhiteContainer(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Debug Information",
                                style: STextStyles.desktopTextMedium(
                                  context,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colors.textFieldDefaultBG,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                      _debugInfo.entries.map((entry) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                width: 150,
                                                child: Text(
                                                  "${entry.key}:",
                                                  style:
                                                      STextStyles.desktopTextExtraSmall(
                                                        context,
                                                      ).copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  entry.value,
                                                  style:
                                                      STextStyles.desktopTextExtraSmall(
                                                        context,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
    );
  }
}
