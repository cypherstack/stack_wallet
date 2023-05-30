import 'package:flutter/services.dart';

abstract class ClipboardInterface {
  Future<void> setData(ClipboardData data);
  Future<ClipboardData?> getData(String format);
}

class ClipboardWrapper implements ClipboardInterface {
  const ClipboardWrapper();

  @override
  Future<ClipboardData?> getData(String format) {
    return Clipboard.getData(format);
  }

  @override
  Future<void> setData(ClipboardData data) async {
    await Clipboard.setData(data);
  }
}

class FakeClipboard implements ClipboardInterface {
  String? _value;

  @override
  Future<ClipboardData?> getData(String format) async {
    return _value == null ? null : ClipboardData(text: _value!);
  }

  @override
  Future<void> setData(ClipboardData data) async {
    _value = data.text;
  }
}
