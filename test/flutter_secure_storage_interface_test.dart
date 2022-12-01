import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:epicmobile/utilities/flutter_secure_storage_interface.dart';

import 'flutter_secure_storage_interface_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage])
void main() {
  test("SecureStorageWrapper write", () async {
    final secureStore = MockFlutterSecureStorage();
    when(secureStore.write(key: "testKey", value: "some value"))
        .thenAnswer((_) async => null);

    final wrapper = SecureStorageWrapper(secureStore);

    await expectLater(
        () async => await wrapper.write(key: "testKey", value: "some value"),
        returnsNormally);

    verify(secureStore.write(key: "testKey", value: "some value")).called(1);
    verifyNoMoreInteractions(secureStore);
  });

  test("SecureStorageWrapper read", () async {
    final secureStore = MockFlutterSecureStorage();
    when(secureStore.read(key: "testKey"))
        .thenAnswer((_) async => "some value");
    final wrapper = SecureStorageWrapper(secureStore);

    final result = await wrapper.read(key: "testKey");

    expect(result, "some value");

    verify(secureStore.read(key: "testKey")).called(1);
    verifyNoMoreInteractions(secureStore);
  });

  test("SecureStorageWrapper delete", () async {
    final secureStore = MockFlutterSecureStorage();
    when(secureStore.delete(key: "testKey")).thenAnswer((_) async {});
    final wrapper = SecureStorageWrapper(secureStore);

    await expectLater(
        () async => await wrapper.delete(key: "testKey"), returnsNormally);

    verify(secureStore.delete(key: "testKey")).called(1);
    verifyNoMoreInteractions(secureStore);
  });
}
