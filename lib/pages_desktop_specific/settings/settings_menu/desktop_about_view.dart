import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_libepiccash/git_versions.dart' as EPIC_VERSIONS;
// import 'package:flutter_libmonero/git_versions.dart' as MONERO_VERSIONS;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
// import 'package:lelantus/git_versions.dart' as FIRO_VERSIONS;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:url_launcher/url_launcher.dart';

const kGithubAPI = "https://api.github.com";
const kGithubSearch = "/search/commits";
const kGithubHead = "/repos";

enum CommitStatus { isHead, isOldCommit, notACommit, notLoaded }

Future<bool> doesCommitExist(
  String organization,
  String project,
  String commit,
) async {
  Logging.instance.log("doesCommitExist", level: LogLevel.Info);
  final Client client = Client();
  try {
    final uri = Uri.parse(
        "$kGithubAPI$kGithubHead/$organization/$project/commits/$commit");

    final commitQuery = await client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    final response = jsonDecode(commitQuery.body.toString());
    Logging.instance.log("doesCommitExist $project $commit $response",
        level: LogLevel.Info);
    bool isThereCommit;
    try {
      isThereCommit = response['sha'] == commit;
      Logging.instance
          .log("isThereCommit $isThereCommit", level: LogLevel.Info);
      return isThereCommit;
    } catch (e, s) {
      return false;
    }
  } catch (e, s) {
    Logging.instance.log("$e $s", level: LogLevel.Error);
    return false;
  }
}

Future<bool> isHeadCommit(
  String organization,
  String project,
  String branch,
  String commit,
) async {
  Logging.instance.log("doesCommitExist", level: LogLevel.Info);
  final Client client = Client();
  try {
    final uri = Uri.parse(
        "$kGithubAPI$kGithubHead/$organization/$project/commits/$branch");

    final commitQuery = await client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    final response = jsonDecode(commitQuery.body.toString());
    Logging.instance.log("isHeadCommit $project $commit $branch $response",
        level: LogLevel.Info);
    bool isHead;
    try {
      isHead = response['sha'] == commit;
      Logging.instance.log("isHead $isHead", level: LogLevel.Info);
      return isHead;
    } catch (e, s) {
      return false;
    }
  } catch (e, s) {
    Logging.instance.log("$e $s", level: LogLevel.Error);
    return false;
  }
}

class DesktopAboutView extends ConsumerWidget {
  const DesktopAboutView({Key? key}) : super(key: key);

  static const String routeName = "/desktopAboutView";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String firoCommit ="lololololo"; // FIRO_VERSIONS.getPluginVersion();
    String epicCashCommit ="lololololo"; // EPIC_VERSIONS.getPluginVersion();
    String moneroCommit = "lololololo"; //MONERO_VERSIONS.getPluginVersion();
    List<Future> futureFiroList = [
      doesCommitExist("cypherstack", "flutter_liblelantus", firoCommit),
      isHeadCommit("cypherstack", "flutter_liblelantus", "main", firoCommit),
    ];
    Future commitFiroFuture = Future.wait(futureFiroList);
    List<Future> futureEpicList = [
      doesCommitExist("cypherstack", "flutter_libepiccash", epicCashCommit),
      isHeadCommit(
          "cypherstack", "flutter_libepiccash", "main", epicCashCommit),
    ];
    Future commitEpicFuture = Future.wait(futureEpicList);
    List<Future> futureMoneroList = [
      doesCommitExist("cypherstack", "flutter_libmonero", moneroCommit),
      isHeadCommit("cypherstack", "flutter_libmonero", "main", moneroCommit),
    ];
    Future commitMoneroFuture = Future.wait(futureMoneroList);

    debugPrint("BUILD: $runtimeType");
    return DesktopScaffold(
      background: Theme.of(context).extension<StackColors>()!.background,
      appBar: DesktopAppBar(
        isCompactHeight: true,
        leading: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
            ),
            Text(
              "About",
              style: STextStyles.desktopH3(context),
            )
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 35),
            child: Row(
              children: [
                Expanded(
                  child: RoundedWhiteContainer(
                    width: 929,
                    height: 411,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, top: 10),
                      child: Column(
                        // mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "Stack Wallet",
                                style: STextStyles.desktopH3(context),
                                textAlign: TextAlign.start,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              RichText(
                                textAlign: TextAlign.start,
                                text: TextSpan(
                                  style: STextStyles.label(context),
                                  children: [
                                    TextSpan(
                                      text:
                                          "By using Stack Wallet, you agree to the ",
                                      style: STextStyles
                                              .desktopTextExtraExtraSmall(
                                                  context)
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .textDark3),
                                    ),
                                    TextSpan(
                                      text: "Terms of service",
                                      style: STextStyles.richLink(context)
                                          .copyWith(fontSize: 14),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          launchUrl(
                                            Uri.parse(
                                                "https://stackwallet.com/terms-of-service.html"),
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        },
                                    ),
                                    TextSpan(
                                      text: " and ",
                                      style: STextStyles
                                              .desktopTextExtraExtraSmall(
                                                  context)
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .textDark3),
                                    ),
                                    TextSpan(
                                      text: "Privacy policy",
                                      style: STextStyles.richLink(context)
                                          .copyWith(fontSize: 14),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          launchUrl(
                                            Uri.parse(
                                                "https://stackwallet.com/privacy-policy.html"),
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Padding(
                            padding:
                                const EdgeInsets.only(right: 10, bottom: 10),
                            child: Column(
                              children: [
                                FutureBuilder(
                                  future: PackageInfo.fromPlatform(),
                                  builder: (context,
                                      AsyncSnapshot<PackageInfo> snapshot) {
                                    String version = "";
                                    String signature = "";
                                    String build = "";

                                    if (snapshot.connectionState ==
                                            ConnectionState.done &&
                                        snapshot.hasData) {
                                      version = snapshot.data!.version;
                                      build = snapshot.data!.buildNumber;
                                      signature = snapshot.data!.buildSignature;
                                    }

                                    return Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Version",
                                                  style: STextStyles
                                                          .desktopTextExtraExtraSmall(
                                                              context)
                                                      .copyWith(
                                                          color: Theme.of(
                                                                  context)
                                                              .extension<
                                                                  StackColors>()!
                                                              .textDark),
                                                ),
                                                const SizedBox(
                                                  height: 2,
                                                ),
                                                SelectableText(
                                                  version,
                                                  style:
                                                      STextStyles.itemSubtitle(
                                                          context),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              width: 400,
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Build number",
                                                  style: STextStyles
                                                          .desktopTextExtraExtraSmall(
                                                              context)
                                                      .copyWith(
                                                          color: Theme.of(
                                                                  context)
                                                              .extension<
                                                                  StackColors>()!
                                                              .textDark),
                                                ),
                                                const SizedBox(
                                                  height: 2,
                                                ),
                                                SelectableText(
                                                  build,
                                                  style:
                                                      STextStyles.itemSubtitle(
                                                          context),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 32),
                                        Row(
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Build signature",
                                                  style: STextStyles
                                                          .desktopTextExtraExtraSmall(
                                                              context)
                                                      .copyWith(
                                                          color: Theme.of(
                                                                  context)
                                                              .extension<
                                                                  StackColors>()!
                                                              .textDark),
                                                ),
                                                const SizedBox(
                                                  height: 2,
                                                ),
                                                SelectableText(
                                                  signature,
                                                  style:
                                                      STextStyles.itemSubtitle(
                                                          context),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              width: 350,
                                            ),
                                            FutureBuilder(
                                                future: commitFiroFuture,
                                                builder: (context,
                                                    AsyncSnapshot<dynamic>
                                                        snapshot) {
                                                  bool commitExists = false;
                                                  bool isHead = false;
                                                  CommitStatus stateOfCommit =
                                                      CommitStatus.notLoaded;

                                                  if (snapshot.connectionState ==
                                                          ConnectionState
                                                              .done &&
                                                      snapshot.hasData) {
                                                    commitExists = snapshot
                                                        .data![0] as bool;
                                                    isHead = snapshot.data![1]
                                                        as bool;
                                                    if (commitExists &&
                                                        isHead) {
                                                      stateOfCommit =
                                                          CommitStatus.isHead;
                                                    } else if (commitExists) {
                                                      stateOfCommit =
                                                          CommitStatus
                                                              .isOldCommit;
                                                    } else {
                                                      stateOfCommit =
                                                          CommitStatus
                                                              .notACommit;
                                                    }
                                                  }
                                                  TextStyle indicationStyle =
                                                      STextStyles.itemSubtitle(
                                                          context);
                                                  switch (stateOfCommit) {
                                                    case CommitStatus.isHead:
                                                      indicationStyle = STextStyles
                                                              .itemSubtitle(
                                                                  context)
                                                          .copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .extension<
                                                                      StackColors>()!
                                                                  .accentColorGreen);
                                                      break;
                                                    case CommitStatus
                                                        .isOldCommit:
                                                      indicationStyle = STextStyles
                                                              .itemSubtitle(
                                                                  context)
                                                          .copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .extension<
                                                                      StackColors>()!
                                                                  .accentColorYellow);
                                                      break;
                                                    case CommitStatus
                                                        .notACommit:
                                                      indicationStyle = STextStyles
                                                              .itemSubtitle(
                                                                  context)
                                                          .copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .extension<
                                                                      StackColors>()!
                                                                  .accentColorRed);
                                                      break;
                                                    default:
                                                      break;
                                                  }
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Firo Build Commit",
                                                        style: STextStyles
                                                                .desktopTextExtraExtraSmall(
                                                                    context)
                                                            .copyWith(
                                                                color: Theme.of(
                                                                        context)
                                                                    .extension<
                                                                        StackColors>()!
                                                                    .textDark),
                                                      ),
                                                      const SizedBox(
                                                        height: 2,
                                                      ),
                                                      SelectableText(
                                                        firoCommit,
                                                        style: indicationStyle,
                                                      ),
                                                    ],
                                                  );
                                                }),
                                          ],
                                        ),
                                        const SizedBox(height: 35),
                                        Row(
                                          children: [
                                            FutureBuilder(
                                                future: commitEpicFuture,
                                                builder: (context,
                                                    AsyncSnapshot<dynamic>
                                                        snapshot) {
                                                  bool commitExists = false;
                                                  bool isHead = false;
                                                  CommitStatus stateOfCommit =
                                                      CommitStatus.notLoaded;

                                                  if (snapshot.connectionState ==
                                                          ConnectionState
                                                              .done &&
                                                      snapshot.hasData) {
                                                    commitExists = snapshot
                                                        .data![0] as bool;
                                                    isHead = snapshot.data![1]
                                                        as bool;
                                                    if (commitExists &&
                                                        isHead) {
                                                      stateOfCommit =
                                                          CommitStatus.isHead;
                                                    } else if (commitExists) {
                                                      stateOfCommit =
                                                          CommitStatus
                                                              .isOldCommit;
                                                    } else {
                                                      stateOfCommit =
                                                          CommitStatus
                                                              .notACommit;
                                                    }
                                                  }
                                                  TextStyle indicationStyle =
                                                      STextStyles.itemSubtitle(
                                                          context);
                                                  switch (stateOfCommit) {
                                                    case CommitStatus.isHead:
                                                      indicationStyle = STextStyles
                                                              .itemSubtitle(
                                                                  context)
                                                          .copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .extension<
                                                                      StackColors>()!
                                                                  .accentColorGreen);
                                                      break;
                                                    case CommitStatus
                                                        .isOldCommit:
                                                      indicationStyle = STextStyles
                                                              .itemSubtitle(
                                                                  context)
                                                          .copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .extension<
                                                                      StackColors>()!
                                                                  .accentColorYellow);
                                                      break;
                                                    case CommitStatus
                                                        .notACommit:
                                                      indicationStyle = STextStyles
                                                              .itemSubtitle(
                                                                  context)
                                                          .copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .extension<
                                                                      StackColors>()!
                                                                  .accentColorRed);
                                                      break;
                                                    default:
                                                      break;
                                                  }
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Epic Cash Build Commit",
                                                        style: STextStyles
                                                                .desktopTextExtraExtraSmall(
                                                                    context)
                                                            .copyWith(
                                                                color: Theme.of(
                                                                        context)
                                                                    .extension<
                                                                        StackColors>()!
                                                                    .textDark),
                                                      ),
                                                      const SizedBox(
                                                        height: 2,
                                                      ),
                                                      SelectableText(
                                                        epicCashCommit,
                                                        style: indicationStyle,
                                                      ),
                                                    ],
                                                  );
                                                }),
                                            const SizedBox(
                                              width: 105,
                                            ),
                                            FutureBuilder(
                                                future: commitMoneroFuture,
                                                builder: (context,
                                                    AsyncSnapshot<dynamic>
                                                        snapshot) {
                                                  bool commitExists = false;
                                                  bool isHead = false;
                                                  CommitStatus stateOfCommit =
                                                      CommitStatus.notLoaded;

                                                  if (snapshot.connectionState ==
                                                          ConnectionState
                                                              .done &&
                                                      snapshot.hasData) {
                                                    commitExists = snapshot
                                                        .data![0] as bool;
                                                    isHead = snapshot.data![1]
                                                        as bool;
                                                    if (commitExists &&
                                                        isHead) {
                                                      stateOfCommit =
                                                          CommitStatus.isHead;
                                                    } else if (commitExists) {
                                                      stateOfCommit =
                                                          CommitStatus
                                                              .isOldCommit;
                                                    } else {
                                                      stateOfCommit =
                                                          CommitStatus
                                                              .notACommit;
                                                    }
                                                  }
                                                  TextStyle indicationStyle =
                                                      STextStyles.itemSubtitle(
                                                          context);
                                                  switch (stateOfCommit) {
                                                    case CommitStatus.isHead:
                                                      indicationStyle = STextStyles
                                                              .itemSubtitle(
                                                                  context)
                                                          .copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .extension<
                                                                      StackColors>()!
                                                                  .accentColorGreen);
                                                      break;
                                                    case CommitStatus
                                                        .isOldCommit:
                                                      indicationStyle = STextStyles
                                                              .itemSubtitle(
                                                                  context)
                                                          .copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .extension<
                                                                      StackColors>()!
                                                                  .accentColorYellow);
                                                      break;
                                                    case CommitStatus
                                                        .notACommit:
                                                      indicationStyle = STextStyles
                                                              .itemSubtitle(
                                                                  context)
                                                          .copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .extension<
                                                                      StackColors>()!
                                                                  .accentColorRed);
                                                      break;
                                                    default:
                                                      break;
                                                  }
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Monero Build Commit",
                                                        style: STextStyles
                                                                .desktopTextExtraExtraSmall(
                                                                    context)
                                                            .copyWith(
                                                                color: Theme.of(
                                                                        context)
                                                                    .extension<
                                                                        StackColors>()!
                                                                    .textDark),
                                                      ),
                                                      const SizedBox(
                                                        height: 2,
                                                      ),
                                                      SelectableText(
                                                        moneroCommit,
                                                        style: indicationStyle,
                                                      ),
                                                    ],
                                                  );
                                                }),
                                          ],
                                        ),
                                        const SizedBox(height: 35),
                                        Row(
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Website",
                                                  style: STextStyles
                                                          .desktopTextExtraExtraSmall(
                                                              context)
                                                      .copyWith(
                                                          color: Theme.of(
                                                                  context)
                                                              .extension<
                                                                  StackColors>()!
                                                              .textDark),
                                                ),
                                                const SizedBox(
                                                  height: 2,
                                                ),
                                                CustomTextButton(
                                                  text:
                                                      "https://stackwallet.com",
                                                  onTap: () {
                                                    launchUrl(
                                                      Uri.parse(
                                                          "https://stackwallet.com"),
                                                      mode: LaunchMode
                                                          .externalApplication,
                                                    );
                                                  },
                                                ),
                                              ],
                                            )
                                          ],
                                        )
                                      ],
                                    );
                                  },
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
