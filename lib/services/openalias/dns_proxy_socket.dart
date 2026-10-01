import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// Adapts raw transports to HttpClient without giving up the cancellation handle
// during a TLS upgrade. Only detachForTls may transfer the raw subscription.
class DnsProxySocket extends Stream<Uint8List> implements Socket {
  final RawSocket _raw;
  final _input = StreamController<Uint8List>();
  final _closed = Completer<void>();
  late final StreamSubscription<RawSocketEvent> _subscription;
  late final _SocketConsumer _consumer;
  late final IOSink _sink;
  Completer<void>? _writable;
  bool _destroyed = false;
  bool _detached = false;
  Object? _error;

  DnsProxySocket(this._raw) {
    _raw.readEventsEnabled = false;
    _raw.writeEventsEnabled = false;
    _input.onListen = () => _setReading(true);
    _input.onPause = () => _setReading(false);
    _input.onResume = () => _setReading(true);
    _input.onCancel = () {
      if (!_detached && !_destroyed) {
        _raw.shutdown(SocketDirection.receive);
      }
    };
    _consumer = _SocketConsumer(this);
    _sink = IOSink(_consumer);
    // Errors are still available to flush/close callers; a remote disconnect
    // must not also produce an unhandled error on an unobserved sink future.
    _sink.done.ignore();
    _subscription = _raw.listen(
      _onEvent,
      onError: (Object error, StackTrace stack) {
        _error = error;
        if (!_input.isClosed) _input.addError(error, stack);
        destroy();
      },
      onDone: destroy,
    );
  }

  factory DnsProxySocket.secure(RawSecureSocket raw) = _DnsSecureSocket;

  void _setReading(bool enabled) {
    if (!_detached && !_destroyed) _raw.readEventsEnabled = enabled;
  }

  void _onEvent(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final bytes = _raw.read();
      if (bytes != null) _input.add(bytes);
    } else if (event == RawSocketEvent.write) {
      _writable?.complete();
      _writable = null;
    } else if (event == RawSocketEvent.readClosed) {
      unawaited(_input.close());
    }
  }

  Future<void> _write(List<int> bytes) async {
    var offset = 0;
    while (offset < bytes.length) {
      if (_destroyed || _detached) {
        throw _error ?? const SocketException('DNS connection closed');
      }
      offset += _raw.write(bytes, offset, bytes.length - offset);
      if (offset < bytes.length) {
        final writable = _writable = Completer<void>();
        _raw.writeEventsEnabled = true;
        await writable.future;
      }
    }
  }

  Future<void> _closeWrite() async {
    if (!_destroyed && !_detached) _raw.shutdown(SocketDirection.send);
    if (!_closed.isCompleted) _closed.complete();
  }

  Future<StreamSubscription<RawSocketEvent>> detachForTls() async {
    await flush();
    if (_destroyed) throw const SocketException('DNS connection closed');
    _detached = true;
    _raw.readEventsEnabled = false;
    await _sink.close();
    unawaited(_input.close());
    return _subscription;
  }

  @override
  void destroy() {
    if (_destroyed || _detached) return;
    _destroyed = true;
    _writable?.complete();
    _writable = null;
    _consumer.stop();
    unawaited(_raw.close());
    unawaited(_subscription.cancel());
    unawaited(_input.close());
    if (!_closed.isCompleted) _closed.complete();
  }

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _input.stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  void add(List<int> data) => _sink.add(data);
  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      throw UnsupportedError('Cannot send errors on sockets');
  @override
  Future<void> addStream(Stream<List<int>> stream) => _sink.addStream(stream);
  @override
  Future<void> flush() => _sink.flush();
  @override
  Future<void> close() => _sink.close();
  @override
  Future<void> get done => _closed.future;
  @override
  Encoding get encoding => _sink.encoding;
  @override
  set encoding(Encoding value) => _sink.encoding = value;
  @override
  void write(Object? object) => _sink.write(object);
  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) =>
      _sink.writeAll(objects, separator);
  @override
  void writeCharCode(int charCode) => _sink.writeCharCode(charCode);
  @override
  void writeln([Object? object = '']) => _sink.writeln(object);
  @override
  InternetAddress get address => _raw.address;
  @override
  InternetAddress get remoteAddress => _raw.remoteAddress;
  @override
  int get port => _raw.port;
  @override
  int get remotePort => _raw.remotePort;
  @override
  bool setOption(SocketOption option, bool enabled) =>
      _raw.setOption(option, enabled);
  @override
  Uint8List getRawOption(RawSocketOption option) => _raw.getRawOption(option);
  @override
  void setRawOption(RawSocketOption option) => _raw.setRawOption(option);
}

class _SocketConsumer implements StreamConsumer<List<int>> {
  final DnsProxySocket socket;
  StreamIterator<List<int>>? _iterator;

  _SocketConsumer(this.socket);

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    final iterator = _iterator = StreamIterator(stream);
    try {
      while (await iterator.moveNext()) {
        await socket._write(iterator.current);
      }
    } finally {
      await iterator.cancel();
      _iterator = null;
    }
  }

  void stop() {
    final iterator = _iterator;
    if (iterator != null) unawaited(iterator.cancel());
  }

  @override
  Future<void> close() => socket._closeWrite();
}

class _DnsSecureSocket extends DnsProxySocket implements SecureSocket {
  final RawSecureSocket _secure;

  _DnsSecureSocket(this._secure) : super(_secure);

  @override
  X509Certificate? get peerCertificate => _secure.peerCertificate;
  @override
  String? get selectedProtocol => _secure.selectedProtocol;
  @override
  void renegotiate({
    bool useSessionCache = true,
    bool requestClientCertificate = false,
    bool requireClientCertificate = false,
  }) {
    // Like dart:io SecureSocket, renegotiation is not implemented.
  }
}
