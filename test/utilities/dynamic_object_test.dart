import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/dynamic_object.dart';

void main() {
  test("DynamicObject get success", () {
    final object = DynamicObject(1);
    expect(object.get<int>(), isA<int>());
  });

  test("DynamicObject get failure", () {
    final object = DynamicObject(1);
    expect(object.get<String>(), throwsA(isA<DynamicObjectTypeException>()));
  });
  test("DynamicObject get if match success", () {
    final object = DynamicObject(1);
    expect(object.getIfMatch<int>(), isA<int?>());
  });

  test("DynamicObject get if match failure", () {
    final object = DynamicObject(1);
    expect(object.getIfMatch<String>(), isNull);
  });
}
