# Isar migration fixture generator

This standalone Dart package intentionally pins the Isar version used before
Stack Wallet's 3.3.2 upgrade. Its `Log` model must remain structurally identical
to `lib/models/isar/models/log.dart`, and its `TransactionV2` plus embedded
models must remain structurally identical to the production wallet schema.

From this directory, regenerate the fixture with:

```sh
dart pub get --enforce-lockfile
dart run build_runner build --delete-conflicting-outputs
dart run bin/generate.dart ../../test/fixtures/isar_3_3_0_dev_2 \
  /path/to/isar_community_flutter_libs-3.3.0-dev.2/<platform>/libisar
```

On macOS the library is `macos/libisar.dylib`; Linux uses
`linux/libisar.so`; Windows uses `windows/libisar.dll`.

Isar may vary internal database bytes between generations. Regenerating the
fixture therefore requires an intentional review and update of the SHA-256 in
the fixture README and migration test.
