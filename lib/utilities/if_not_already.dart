import 'dart:async';

class IfNotAlready {
  final void Function() _function;

  bool _locked = false;

  IfNotAlready(this._function);

  void execute() {
    if (_locked) return;
    _locked = true;
    try {
      _function();
    } finally {
      _locked = false;
    }
  }
}

class IfNotAlreadyAsync<T> {
  final Future<void> Function()? _function;
  final Future<void> Function(T? args)? _functionWithArgs;

  bool _locked = false;

  IfNotAlreadyAsync(this._function) : _functionWithArgs = null;
  IfNotAlreadyAsync.withArgs(this._functionWithArgs) : _function = null;

  Future<void> execute([T? args]) async {
    if (!_locked) {
      _locked = true;
      try {
        if (_function != null) {
          await _function();
        } else {
          await _functionWithArgs!(args);
        }
      } finally {
        _locked = false;
      }
    }
  }
}
