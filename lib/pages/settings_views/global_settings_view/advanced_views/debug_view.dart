import 'dart:async';
import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stackwallet/models/isar/models/log.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/providers/global/debug_service_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/custom_loading_overlay.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class DebugView extends ConsumerStatefulWidget {
  const DebugView({Key? key}) : super(key: key);

  static const String routeName = "/debug";

  @override
  ConsumerState<DebugView> createState() => _DebugViewState();
}

class _DebugViewState extends ConsumerState<DebugView> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  final scrollController = ScrollController();

  String _searchTerm = "";

  List<Log> filtered(List<Log> unfiltered, String filter) {
    if (filter == "") {
      return unfiltered;
    }
    return unfiltered
        .where(
            (e) => (e.toString().toLowerCase().contains(filter.toLowerCase())))
        .toList();
  }

  BorderRadius? _borderRadius(int index, int listLength) {
    if (index == 0 && listLength == 1) {
      return BorderRadius.circular(
        Constants.size.circularBorderRadius,
      );
    } else if (index == 0) {
      return BorderRadius.vertical(
        bottom: Radius.circular(
          Constants.size.circularBorderRadius,
        ),
      );
    } else if (index == listLength - 1) {
      return BorderRadius.vertical(
        top: Radius.circular(
          Constants.size.circularBorderRadius,
        ),
      );
    }
    return null;
  }

  @override
  void initState() {
    ref.read(debugServiceProvider).updateRecentLogs();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).extension<StackColors>()!.background,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "Debug",
          style: STextStyles.navBarTitle(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              top: 10,
              bottom: 10,
              right: 10,
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: AppBarIconButton(
                key: const Key("deleteLogsAppBarButtonKey"),
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
                  await showDialog<void>(
                    context: context,
                    builder: (_) => StackDialog(
                      title: "Delete logs?",
                      message:
                          "You are about to delete all logs permanently. Are you sure?",
                      leftButton: TextButton(
                        style: Theme.of(context)
                            .extension<StackColors>()!
                            .getSecondaryEnabledButtonColor(context),
                        child: Text(
                          "Cancel",
                          style: STextStyles.itemSubtitle12(context),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      rightButton: TextButton(
                        style: Theme.of(context)
                            .extension<StackColors>()!
                            .getPrimaryEnabledButtonColor(context),
                        child: Text(
                          "Delete logs",
                          style: STextStyles.button(context),
                        ),
                        onPressed: () async {
                          Navigator.of(context).pop();

                          bool shouldPop = false;
                          unawaited(showDialog<dynamic>(
                            barrierDismissible: false,
                            context: context,
                            builder: (_) => WillPopScope(
                              onWillPop: () async {
                                return shouldPop;
                              },
                              child: const CustomLoadingOverlay(
                                message: "Deleting logs...",
                                eventBus: null,
                              ),
                            ),
                          ));

                          await ref
                              .read(debugServiceProvider)
                              .deleteAllMessages();
                          await ref
                              .read(debugServiceProvider)
                              .updateRecentLogs();

                          shouldPop = true;

                          if (mounted) {
                            Navigator.pop(context);
                            unawaited(showFloatingFlushBar(
                                type: FlushBarType.info,
                                context: context,
                                message: 'Logs cleared!'));
                          }
                        },
                      ),
                    ),
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
          left: 16,
          right: 16,
        ),
        child: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverOverlapAbsorber(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            Constants.size.circularBorderRadius,
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: (newString) {
                              setState(() => _searchTerm = newString);
                            },
                            style: STextStyles.field(context),
                            decoration: standardInputDecoration(
                              "Search",
                              _searchFocusNode,
                              context,
                            ).copyWith(
                              prefixIcon: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 16,
                                ),
                                child: SvgPicture.asset(
                                  Assets.svg.search,
                                  width: 16,
                                  height: 16,
                                ),
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.only(right: 0),
                                      child: UnconstrainedBox(
                                        child: Row(
                                          children: [
                                            TextFieldIconButton(
                                              child: const XIcon(),
                                              onTap: () async {
                                                setState(() {
                                                  _searchController.text = "";
                                                  _searchTerm = "";
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
                        const SizedBox(
                          height: 12,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // BlueTextButton(
                            //   text: ref.watch(debugServiceProvider
                            //           .select((value) => value.isPaused))
                            //       ? "Unpause"
                            //       : "Pause",
                            //   onTap: () {
                            //     ref
                            //         .read(debugServiceProvider)
                            //         .togglePauseUiUpdates();
                            //   },
                            // ),
                            const Spacer(),
                            BlueTextButton(
                              text: "Save logs to file",
                              onTap: () async {
                                Directory rootPath =
                                    (await getApplicationDocumentsDirectory());

                                if (Platform.isAndroid) {
                                  rootPath = Directory("/storage/emulated/0/");
                                }

                                Directory dir =
                                    Directory('${rootPath.path}/Documents');
                                if (Platform.isIOS) {
                                  dir = Directory(rootPath.path);
                                }
                                try {
                                  if (!dir.existsSync()) {
                                    dir.createSync();
                                  }
                                } catch (e, s) {
                                  Logging.instance
                                      .log("$e\n$s", level: LogLevel.Error);
                                }

                                final String? path =
                                    await FilePicker.platform.getDirectoryPath(
                                  dialogTitle: "Choose Backup location",
                                  initialDirectory: dir.path,
                                  lockParentWindow: true,
                                );

                                if (path != null) {
                                  final eventBus = EventBus();
                                  bool shouldPop = false;
                                  unawaited(showDialog<dynamic>(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (_) => WillPopScope(
                                      onWillPop: () async {
                                        return shouldPop;
                                      },
                                      child: CustomLoadingOverlay(
                                        message: "Generating Stack logs file",
                                        eventBus: eventBus,
                                      ),
                                    ),
                                  ));

                                  await ref
                                      .read(debugServiceProvider)
                                      .exportToFile(path, eventBus);

                                  shouldPop = true;

                                  if (mounted) {
                                    Navigator.pop(context);
                                    unawaited(showFloatingFlushBar(
                                        type: FlushBarType.info,
                                        context: context,
                                        message: 'Logs file saved'));
                                  }
                                }
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: Builder(
            builder: (context) {
              final logs = filtered(
                      ref.watch(debugServiceProvider
                          .select((value) => value.recentLogs)),
                      _searchTerm)
                  .reversed
                  .toList(growable: false);

              return CustomScrollView(
                reverse: true,
                // shrinkWrap: true,
                controller: scrollController,
                slivers: [
                  SliverOverlapInjector(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                      context,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final log = logs[index];

                        return Container(
                          key: Key("log_${log.id}_${log.timestampInMillisUTC}"),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .popupBG,
                            borderRadius: _borderRadius(index, logs.length),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: RoundedContainer(
                              padding: const EdgeInsets.all(0),
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .popupBG,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        " [${log.logLevel.name}]",
                                        style: STextStyles.baseXS(context)
                                            .copyWith(
                                          fontSize: 8,
                                          color: (log.logLevel == LogLevel.Info
                                              ? Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .topNavIconGreen
                                              : (log.logLevel ==
                                                      LogLevel.Warning
                                                  ? Theme.of(context)
                                                      .extension<StackColors>()!
                                                      .topNavIconYellow
                                                  : (log.logLevel ==
                                                          LogLevel.Error
                                                      ? Colors.orange
                                                      : Theme.of(context)
                                                          .extension<
                                                              StackColors>()!
                                                          .topNavIconRed))),
                                        ),
                                      ),
                                      Text(
                                        "[${DateTime.fromMillisecondsSinceEpoch(log.timestampInMillisUTC, isUtc: true)}]: ",
                                        style: STextStyles.baseXS(context)
                                            .copyWith(
                                          fontSize: 8,
                                          color: Theme.of(context)
                                              .extension<StackColors>()!
                                              .textDark3,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                        width: 20,
                                      ),
                                      Flexible(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SelectableText(
                                              log.message,
                                              style: STextStyles.baseXS(context)
                                                  .copyWith(fontSize: 8),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: logs.length,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
