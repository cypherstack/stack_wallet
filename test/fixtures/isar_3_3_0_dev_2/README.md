# Isar 3.3.0-dev.2 migration fixture

The fixtures contain databases created by `isar_community` 3.3.0-dev.2 using
schemas that match Stack Wallet 2.3.4:

- `isar_3_3_0_dev_2_wallet_data.isar.gz` contains a `TransactionV2` with an
  input, outpoint, and output. Its collection schema ID is
  `-4280912949179256257`, matching Stack Wallet's current wallet database.
- `isar_3_3_0_dev_2_log.isar.gz` contains one legacy Stack Wallet `Log` record.
  Its collection schema ID is `7425915233166922082`.

The committed fixture is gzip-compressed without a filename or timestamp. Its
SHA-256 digest is:

```text
c7bd6db8215a61d888c78c42a18b10541274d340c3c5377a5424bdcb595ad126  isar_3_3_0_dev_2_log.isar.gz
6a0ce2f29c58875985d32253acb54469632fd55111812c39e1a41a87cf93f22a  isar_3_3_0_dev_2_wallet_data.isar.gz
```

Use `tool/isar_migration_fixture_generator` to regenerate it. The migration
tests open temporary copies using Isar 3.3.2, verify the databases and indexed
records, write current records, close the databases, and reopen them.
