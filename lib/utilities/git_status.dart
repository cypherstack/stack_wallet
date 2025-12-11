import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';

import '../../../themes/stack_colors.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/text_styles.dart';
import '../app_config.dart';
import '../wl_gen/generated/libepiccash_interface_impl.dart';
import '../wl_gen/interfaces/libmwc_interface.dart';

const kGithubAPI = "https://api.github.com";
const kGithubSearch = "/search/commits";
const kGithubHead = "/repos";

enum CommitStatus { isHead, isOldCommit, notACommit, notLoaded }

abstract class GitStatus {
  static String get epicCashCommit => libEpic.getPluginVersion();
  // static String get moneroCommit => monero_versions.getPluginVersion();
  static String get mimblewimblecoinCommit => libMwc.getPluginVersion();

  static String get appCommitHash => AppConfig.commitHash;

  static CommitStatus? _cachedEpicStatus;
  static Future<CommitStatus> getEpicCommitStatus() async {
    if (_cachedEpicStatus != null) {
      return _cachedEpicStatus!;
    }

    final List<bool> results = await Future.wait([
      _doesCommitExist("cypherstack", "flutter_libepiccash", epicCashCommit),
      _isHeadCommit(
        "cypherstack",
        "flutter_libepiccash",
        "main",
        epicCashCommit,
      ),
    ]);

    final commitExists = results[0];
    final commitIsHead = results[1];

    if (commitExists && commitIsHead) {
      _cachedEpicStatus = CommitStatus.isHead;
    } else if (commitExists) {
      _cachedEpicStatus = CommitStatus.isOldCommit;
    } else {
      _cachedEpicStatus = CommitStatus.notACommit;
    }

    return _cachedEpicStatus!;
  }

  static CommitStatus? _cachedMimblewimblecoinStatus;
  static Future<CommitStatus> getMimblewimblecoinCommitStatus() async {
    if (_cachedMimblewimblecoinStatus != null) {
      return _cachedMimblewimblecoinStatus!;
    }
    final List<bool> results = await Future.wait([
      _doesCommitExist("cypherstack", "flutter_libmwc", mimblewimblecoinCommit),
      _isHeadCommit(
        "cypherstack",
        "flutter_libmwc",
        "main",
        mimblewimblecoinCommit,
      ),
    ]);

    final commitExists = results[0];
    final commitIsHead = results[1];

    if (commitExists && commitIsHead) {
      _cachedMimblewimblecoinStatus = CommitStatus.isHead;
    } else if (commitExists) {
      _cachedMimblewimblecoinStatus = CommitStatus.isOldCommit;
    } else {
      _cachedMimblewimblecoinStatus = CommitStatus.notACommit;
    }

    return _cachedMimblewimblecoinStatus!;
  }

  //static CommitStatus? _cachedMoneroStatus;
  //static Future<CommitStatus> getMoneroCommitStatus() async {
  //  if (_cachedMoneroStatus != null) {
  //    return _cachedMoneroStatus!;
  //  }
  //
  //  final List<bool> results = await Future.wait([
  //    _doesCommitExist("cypherstack", "flutter_libmonero", moneroCommit),
  //    _isHeadCommit("cypherstack", "flutter_libmonero", "main", moneroCommit),
  //  ]);
  //
  //  final commitExists = results[0];
  //  final commitIsHead = results[1];
  //
  //  if (commitExists && commitIsHead) {
  //    _cachedMoneroStatus = CommitStatus.isHead;
  //  } else if (commitExists) {
  //    _cachedMoneroStatus = CommitStatus.isOldCommit;
  //  } else {
  //    _cachedMoneroStatus = CommitStatus.notACommit;
  //  }
  //
  //  return _cachedMoneroStatus!;
  //}

  static TextStyle styleForStatus(CommitStatus status, BuildContext context) {
    final Color color;
    switch (status) {
      case CommitStatus.isHead:
        color = Theme.of(context).extension<StackColors>()!.accentColorGreen;
        break;
      case CommitStatus.isOldCommit:
        color = Theme.of(context).extension<StackColors>()!.accentColorYellow;
        break;
      case CommitStatus.notACommit:
        color = Theme.of(context).extension<StackColors>()!.accentColorRed;
        break;
      default:
        return STextStyles.itemSubtitle(context);
    }

    return STextStyles.itemSubtitle(context).copyWith(color: color);
  }

  static Future<bool> _doesCommitExist(
    String organization,
    String project,
    String commit,
  ) async {
    Logging.instance.d("doesCommitExist");
    final Client client = Client();
    try {
      final uri = Uri.parse(
        "$kGithubAPI$kGithubHead/$organization/$project/commits/$commit",
      );

      final commitQuery = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final response = jsonDecode(commitQuery.body.toString());
      Logging.instance.d("doesCommitExist $project $commit $response");
      bool isThereCommit;
      try {
        isThereCommit = response['sha'] == commit;
        Logging.instance.d("isThereCommit $isThereCommit");
        return isThereCommit;
      } catch (e, s) {
        return false;
      }
    } catch (e, s) {
      Logging.instance.e("$e $s", error: e, stackTrace: s);
      return false;
    }
  }

  static Future<bool> _isHeadCommit(
    String organization,
    String project,
    String branch,
    String commit,
  ) async {
    Logging.instance.d("doesCommitExist");
    final Client client = Client();
    try {
      final uri = Uri.parse(
        "$kGithubAPI$kGithubHead/$organization/$project/commits/$branch",
      );

      final commitQuery = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final response = jsonDecode(commitQuery.body.toString());
      Logging.instance.d("isHeadCommit $project $commit $branch $response");
      bool isHead;
      try {
        isHead = response['sha'] == commit;
        Logging.instance.d("isHead $isHead");
        return isHead;
      } catch (e) {
        rethrow;
      }
    } catch (e, s) {
      Logging.instance.e("", error: e, stackTrace: s);
      return false;
    }
  }
}
