import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_libepiccash/git_versions.dart' as EPIC_VERSIONS;
import 'package:flutter_libmonero/git_versions.dart' as MONERO_VERSIONS;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:lelantus/git_versions.dart' as FIRO_VERSIONS;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
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
    Logging.instance.log("doesCommitExist $project $commit", // $response",
        level: LogLevel.Info);
    bool isThereCommit;
    try {
      isThereCommit = response['sha'] == commit;
      Logging.instance.log(
        "$commit isThereCommit=$isThereCommit",
        level: LogLevel.Info,
      );
      return isThereCommit;
    } catch (_) {
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
    Logging.instance.log(
      "isHeadCommit $project $commit $branch", //$response",
      level: LogLevel.Info,
    );
    bool isHead;
    try {
      isHead = response['sha'] == commit;
      Logging.instance.log(
        "$commit isHead=$isHead",
        level: LogLevel.Info,
      );
      return isHead;
    } catch (_) {
      return false;
    }
  } catch (e, s) {
    Logging.instance.log("$e $s", level: LogLevel.Error);
    return false;
  }
}

class AboutView extends ConsumerWidget {
  const AboutView({Key? key}) : super(key: key);

  static const String routeName = "/about";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String firoCommit = FIRO_VERSIONS.getPluginVersion();
    String epicCashCommit = EPIC_VERSIONS.getPluginVersion();
    String moneroCommit = MONERO_VERSIONS.getPluginVersion();
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

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () async {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            "About",
            style: STextStyles.navBarTitle(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FutureBuilder(
                          future: PackageInfo.fromPlatform(),
                          builder:
                              (context, AsyncSnapshot<PackageInfo> snapshot) {
                            String version = "";
                            String signature = "";
                            String appName = "";
                            String build = "";

                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.hasData) {
                              version = snapshot.data!.version;
                              build = snapshot.data!.buildNumber;
                              signature = snapshot.data!.buildSignature;
                              appName = snapshot.data!.appName;
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: Text(
                                    appName,
                                    style: STextStyles.pageTitleH2(context),
                                  ),
                                ),
                                const SizedBox(
                                  height: 24,
                                ),
                                RoundedWhiteContainer(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        "Version",
                                        style: STextStyles.titleBold12(context),
                                      ),
                                      const SizedBox(
                                        height: 4,
                                      ),
                                      SelectableText(
                                        version,
                                        style:
                                            STextStyles.itemSubtitle(context),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                RoundedWhiteContainer(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        "Build number",
                                        style: STextStyles.titleBold12(context),
                                      ),
                                      const SizedBox(
                                        height: 4,
                                      ),
                                      SelectableText(
                                        build,
                                        style:
                                            STextStyles.itemSubtitle(context),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                RoundedWhiteContainer(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        "Build signature",
                                        style: STextStyles.titleBold12(context),
                                      ),
                                      const SizedBox(
                                        height: 4,
                                      ),
                                      SelectableText(
                                        signature,
                                        style:
                                            STextStyles.itemSubtitle(context),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        FutureBuilder(
                            future: commitFiroFuture,
                            builder:
                                (context, AsyncSnapshot<dynamic> snapshot) {
                              bool commitExists = false;
                              bool isHead = false;
                              CommitStatus stateOfCommit =
                                  CommitStatus.notLoaded;

                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.hasData) {
                                commitExists = snapshot.data![0] as bool;
                                isHead = snapshot.data![1] as bool;
                                if (commitExists && isHead) {
                                  stateOfCommit = CommitStatus.isHead;
                                } else if (commitExists) {
                                  stateOfCommit = CommitStatus.isOldCommit;
                                } else {
                                  stateOfCommit = CommitStatus.notACommit;
                                }
                              }
                              TextStyle indicationStyle =
                                  STextStyles.itemSubtitle(context);
                              switch (stateOfCommit) {
                                case CommitStatus.isHead:
                                  indicationStyle =
                                      STextStyles.itemSubtitle(context)
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .accentColorGreen);
                                  break;
                                case CommitStatus.isOldCommit:
                                  indicationStyle =
                                      STextStyles.itemSubtitle(context)
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .accentColorYellow);
                                  break;
                                case CommitStatus.notACommit:
                                  indicationStyle =
                                      STextStyles.itemSubtitle(context)
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .accentColorRed);
                                  break;
                                default:
                                  break;
                              }
                              return RoundedWhiteContainer(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      "Firo Build Commit",
                                      style: STextStyles.titleBold12(context),
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    SelectableText(
                                      firoCommit,
                                      style: indicationStyle,
                                    ),
                                  ],
                                ),
                              );
                            }),
                        const SizedBox(
                          height: 12,
                        ),
                        FutureBuilder(
                            future: commitEpicFuture,
                            builder:
                                (context, AsyncSnapshot<dynamic> snapshot) {
                              bool commitExists = false;
                              bool isHead = false;
                              CommitStatus stateOfCommit =
                                  CommitStatus.notLoaded;

                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.hasData) {
                                commitExists = snapshot.data![0] as bool;
                                isHead = snapshot.data![1] as bool;
                                if (commitExists && isHead) {
                                  stateOfCommit = CommitStatus.isHead;
                                } else if (commitExists) {
                                  stateOfCommit = CommitStatus.isOldCommit;
                                } else {
                                  stateOfCommit = CommitStatus.notACommit;
                                }
                              }
                              TextStyle indicationStyle =
                                  STextStyles.itemSubtitle(context);
                              switch (stateOfCommit) {
                                case CommitStatus.isHead:
                                  indicationStyle =
                                      STextStyles.itemSubtitle(context)
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .accentColorGreen);
                                  break;
                                case CommitStatus.isOldCommit:
                                  indicationStyle =
                                      STextStyles.itemSubtitle(context)
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .accentColorYellow);
                                  break;
                                case CommitStatus.notACommit:
                                  indicationStyle =
                                      STextStyles.itemSubtitle(context)
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .accentColorRed);
                                  break;
                                default:
                                  break;
                              }
                              return RoundedWhiteContainer(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      "Epic Cash Build Commit",
                                      style: STextStyles.titleBold12(context),
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    SelectableText(
                                      epicCashCommit,
                                      style: indicationStyle,
                                    ),
                                  ],
                                ),
                              );
                            }),
                        const SizedBox(
                          height: 12,
                        ),
                        FutureBuilder(
                            future: commitMoneroFuture,
                            builder:
                                (context, AsyncSnapshot<dynamic> snapshot) {
                              bool commitExists = false;
                              bool isHead = false;
                              CommitStatus stateOfCommit =
                                  CommitStatus.notLoaded;

                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.hasData) {
                                commitExists = snapshot.data![0] as bool;
                                isHead = snapshot.data![1] as bool;
                                if (commitExists && isHead) {
                                  stateOfCommit = CommitStatus.isHead;
                                } else if (commitExists) {
                                  stateOfCommit = CommitStatus.isOldCommit;
                                } else {
                                  stateOfCommit = CommitStatus.notACommit;
                                }
                              }
                              TextStyle indicationStyle =
                                  STextStyles.itemSubtitle(context);
                              switch (stateOfCommit) {
                                case CommitStatus.isHead:
                                  indicationStyle =
                                      STextStyles.itemSubtitle(context)
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .accentColorGreen);
                                  break;
                                case CommitStatus.isOldCommit:
                                  indicationStyle =
                                      STextStyles.itemSubtitle(context)
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .accentColorYellow);
                                  break;
                                case CommitStatus.notACommit:
                                  indicationStyle =
                                      STextStyles.itemSubtitle(context)
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .accentColorRed);
                                  break;
                                default:
                                  break;
                              }
                              return RoundedWhiteContainer(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      "Monero Build Commit",
                                      style: STextStyles.titleBold12(context),
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    SelectableText(
                                      moneroCommit,
                                      style: indicationStyle,
                                    ),
                                  ],
                                ),
                              );
                            }),
                        const SizedBox(
                          height: 12,
                        ),
                        RoundedWhiteContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Website",
                                style: STextStyles.titleBold12(context),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              CustomTextButton(
                                text: "https://stackwallet.com",
                                onTap: () {
                                  launchUrl(
                                    Uri.parse("https://stackwallet.com"),
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        const Spacer(),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: STextStyles.label(context),
                            children: [
                              const TextSpan(
                                  text:
                                      "By using Stack Wallet, you agree to the "),
                              TextSpan(
                                text: "Terms of service",
                                style: STextStyles.richLink(context),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    launchUrl(
                                      Uri.parse(
                                          "https://stackwallet.com/terms-of-service.html"),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                              ),
                              const TextSpan(text: " and "),
                              TextSpan(
                                text: "Privacy policy",
                                style: STextStyles.richLink(context),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    launchUrl(
                                      Uri.parse(
                                          "https://stackwallet.com/privacy-policy.html"),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ],
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
