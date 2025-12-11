class DynamicObjectTypeException implements Exception {
  final Type actual, expected;

  DynamicObjectTypeException({required this.actual, required this.expected});

  @override
  String toString() =>
      "DynamicObjectException: Found $actual, expected $expected";
}

class DynamicObject {
  final Object _value;

  DynamicObject(this._value);

  T get<T>() {
    if (_value is T) return _value as T;
    throw DynamicObjectTypeException(actual: _value.runtimeType, expected: T);
  }

  T? getIfMatch<T>() {
    if (_value is T) return _value as T;
    return null;
  }
}
