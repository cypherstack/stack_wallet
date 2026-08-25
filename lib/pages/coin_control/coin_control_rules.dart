/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 */

import '../../db/isar/main_db.dart';

CCFilter coinControlFilter({
  required bool isSearching,
  required bool showBlocked,
}) => isSearching
    ? CCFilter.all
    : showBlocked
    ? CCFilter.frozen
    : CCFilter.available;

bool canSelectCoinControlOutput({
  required bool isManageMode,
  required bool isBlocked,
  required bool isConfirmed,
}) => isManageMode || (!isBlocked && isConfirmed);
