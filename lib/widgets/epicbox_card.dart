import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../providers/global/node_service_provider.dart';
import '../themes/stack_colors.dart';
import '../utilities/assets.dart';
import '../utilities/default_epicboxes.dart';
import '../utilities/test_epicbox_server_connection.dart';
import '../utilities/text_styles.dart';
import '../utilities/util.dart';
import 'custom_buttons/blue_text_button.dart';
import 'expandable.dart';
import 'rounded_white_container.dart';

class EpicBoxCard extends ConsumerStatefulWidget {
  const EpicBoxCard({
    super.key,
    required this.epicBoxId,
    required this.onConnect,
    required this.onEdit,
    this.testOnInit = false,
  });

  final String epicBoxId;
  final VoidCallback onConnect;
  final VoidCallback onEdit;
  final bool testOnInit;

  @override
  ConsumerState<EpicBoxCard> createState() => _EpicBoxCardState();
}

class _EpicBoxCardState extends ConsumerState<EpicBoxCard> {
  bool _advancedIsExpanded = false;
  bool _testing = false;
  bool? _testResult;

  @override
  void initState() {
    super.initState();
    if (widget.testOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _testConnection());
    }
  }

  @override
  void didUpdateWidget(EpicBoxCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-test when testOnInit changes from false to true
    if (widget.testOnInit && !oldWidget.testOnInit && _testResult == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _testConnection();
      });
    }
  }

  Future<void> _testConnection() async {
    final epicBox =
        ref
            .read(nodeServiceChangeNotifierProvider)
            .getEpicBoxById(id: widget.epicBoxId) ??
        DefaultEpicBoxes.all.firstWhere((e) => e.id == widget.epicBoxId);

    setState(() {
      _testing = true;
      _testResult = null;
    });

    final data = EpicBoxFormData()
      ..host = epicBox.host
      ..port = epicBox.port ?? 443
      ..useSSL = epicBox.useSSL;

    final result = await testEpicBoxServerConnection(data) != null;

    if (mounted) {
      setState(() {
        _testing = false;
        _testResult = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final epicBox =
        ref.watch(
          nodeServiceChangeNotifierProvider.select(
            (value) => value.getEpicBoxById(id: widget.epicBoxId),
          ),
        ) ??
        DefaultEpicBoxes.all.firstWhere((e) => e.id == widget.epicBoxId);

    final primaryEpicBox = ref.watch(
      nodeServiceChangeNotifierProvider.select(
        (value) => value.getPrimaryEpicBox(),
      ),
    );

    final isPrimary = primaryEpicBox?.id == epicBox.id;
    final isDesktop = Util.isDesktop;

    String status;
    Color? statusColor;
    if (_testing) {
      status = "Testing...";
    } else if (_testResult == true) {
      status = isPrimary ? "Connected" : "Reachable";
      statusColor = Theme.of(
        context,
      ).extension<StackColors>()!.accentColorGreen;
    } else if (_testResult == false) {
      status = "Unreachable";
      statusColor = Theme.of(context).extension<StackColors>()!.accentColorRed;
    } else {
      status = isPrimary ? "Selected" : "";
      if (isPrimary) {
        statusColor = Theme.of(
          context,
        ).extension<StackColors>()!.accentColorBlue;
      }
    }

    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(0),
      borderColor: isDesktop
          ? Theme.of(context).extension<StackColors>()!.background
          : null,
      child: Expandable(
        onExpandChanged: (state) {
          setState(() {
            _advancedIsExpanded = state == ExpandableState.expanded;
          });
        },
        header: Padding(
          padding: EdgeInsets.all(isDesktop ? 16 : 12),
          child: Row(
            children: [
              Container(
                width: isDesktop ? 40 : 24,
                height: isDesktop ? 40 : 24,
                decoration: BoxDecoration(
                  color: epicBox.isDefault
                      ? Theme.of(
                          context,
                        ).extension<StackColors>()!.buttonBackSecondary
                      : Theme.of(context)
                            .extension<StackColors>()!
                            .infoItemIcons
                            .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    Assets.svg.node,
                    height: isDesktop ? 18 : 11,
                    width: isDesktop ? 20 : 14,
                    color: epicBox.isDefault
                        ? Theme.of(
                            context,
                          ).extension<StackColors>()!.accentColorDark
                        : Theme.of(
                            context,
                          ).extension<StackColors>()!.infoItemIcons,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(epicBox.name, style: STextStyles.titleBold12(context)),
                    const SizedBox(height: 2),
                    Text(
                      "${epicBox.host}:${epicBox.port ?? 443}",
                      style: STextStyles.label(context),
                    ),
                  ],
                ),
              ),
              Text(
                status,
                style: STextStyles.label(context).copyWith(color: statusColor),
              ),
              const SizedBox(width: 12),
              SvgPicture.asset(
                _advancedIsExpanded
                    ? Assets.svg.chevronUp
                    : Assets.svg.chevronDown,
                width: 12,
                height: 6,
                color: Theme.of(
                  context,
                ).extension<StackColors>()!.textSubtitle1,
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            children: [
              const SizedBox(width: 66),
              CustomTextButton(
                text: "Test",
                enabled: !_testing,
                onTap: _testConnection,
              ),
              const SizedBox(width: 48),
              CustomTextButton(
                text: "Connect",
                enabled: !isPrimary,
                onTap: widget.onConnect,
              ),
              const SizedBox(width: 48),
              if (!epicBox.isDefault)
                CustomTextButton(text: "Edit", onTap: widget.onEdit),
            ],
          ),
        ),
      ),
    );
  }
}
