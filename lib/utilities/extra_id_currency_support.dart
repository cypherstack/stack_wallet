/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2026 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

/// Currencies whose custodial deposits commonly require a destination
/// tag/memo ("extra ID") attached to the payout transaction. A payout sent
/// to such a platform without its tag lands unattributed.
abstract final class ExtraIdCurrencySupport {
  static const Set<String> _tickers = {
    "atom",
    "eos",
    "hbar",
    "ton",
    "xlm",
    "xrp",
  };

  static bool mayRequire(String ticker) =>
      _tickers.contains(ticker.trim().toLowerCase());
}
