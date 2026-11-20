import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:stackwallet/services/zcash_sapling_parameter_service.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('stack-sapling-params-');
  });

  tearDown(() async {
    if (await temp.exists()) {
      await temp.delete(recursive: true);
    }
  });

  test(
    'cached-only resolution never starts a download when data is absent',
    () async {
      var clientCreations = 0;
      final service = ZcashSaplingParameterService(
        cacheRoot: () async => temp,
        manifest: _manifest,
        locations: _locations,
        clientFactory: (_) {
          clientCreations++;
          return http.Client();
        },
        proxyResolver: () => null,
      );

      await expectLater(
        service.resolve().result,
        throwsA(isA<ZcashSaplingParametersRequired>()),
      );
      expect(clientCreations, 0);
    },
  );

  test(
    'cache-root failures emit a failure and close the state stream',
    () async {
      final failure = StateError('cache root unavailable');
      final service = ZcashSaplingParameterService(
        cacheRoot: () async => throw failure,
        manifest: _manifest,
        locations: _locations,
        clientFactory: (_) => http.Client(),
        proxyResolver: () => null,
      );
      final task = service.resolve(
        access: SaplingParameterAccess.downloadIfMissing,
      );
      final states = task.states.toList();

      await expectLater(task.result, throwsA(same(failure)));
      expect(
        await states,
        containsAllInOrder([
          isA<SaplingParametersChecking>(),
          isA<SaplingParametersFailed>().having(
            (state) => state.error,
            'error',
            same(failure),
          ),
        ]),
      );
    },
  );

  test(
    'explicit acquisition streams both artifacts and reuses them offline',
    () async {
      final client = _RecordingClient({
        _locations[_manifest.spend.fileName]!: _spendBytes,
        _locations[_manifest.output.fileName]!: _outputBytes,
      });
      var clientCreations = 0;
      final service = ZcashSaplingParameterService(
        cacheRoot: () async => temp,
        manifest: _manifest,
        locations: _locations,
        clientFactory: (_) {
          clientCreations++;
          return client;
        },
        proxyResolver: () => null,
      );

      final acquisition = service.resolve(
        access: SaplingParameterAccess.downloadIfMissing,
      );
      final states = acquisition.states.toList();
      final installed = await acquisition.result;

      expect(client.requests, [
        _locations[_manifest.spend.fileName],
        _locations[_manifest.output.fileName],
      ]);
      expect(clientCreations, 1);
      expect(await File(installed.spendParamsPath).readAsBytes(), _spendBytes);
      expect(
        await File(installed.outputParamsPath).readAsBytes(),
        _outputBytes,
      );
      expect(
        await states,
        containsAllInOrder([
          isA<SaplingParametersChecking>(),
          isA<SaplingParametersDownloading>(),
          isA<SaplingParametersVerifying>(),
          isA<SaplingParametersReady>(),
        ]),
      );

      final offline = await service.resolve().result;
      expect(offline.spendParamsPath, installed.spendParamsPath);
      expect(clientCreations, 1);
    },
  );

  test('concurrent explicit callers share one acquisition', () async {
    final client = _RecordingClient({
      _locations[_manifest.spend.fileName]!: _spendBytes,
      _locations[_manifest.output.fileName]!: _outputBytes,
    });
    var clientCreations = 0;
    final service = ZcashSaplingParameterService(
      cacheRoot: () async => temp,
      manifest: _manifest,
      locations: _locations,
      clientFactory: (_) {
        clientCreations++;
        return client;
      },
      proxyResolver: () => null,
    );

    final first = service.resolve(
      access: SaplingParameterAccess.downloadIfMissing,
    );
    final second = service.resolve(
      access: SaplingParameterAccess.downloadIfMissing,
    );
    final installed = await Future.wait([first.result, second.result]);

    expect(clientCreations, 1);
    expect(client.requests, hasLength(2));
    expect(installed[0].spendParamsPath, installed[1].spendParamsPath);
  });

  test('a shared caller can read the current acquisition stage', () async {
    final client = _PartiallyGatedClient({
      _locations[_manifest.spend.fileName]!: _spendBytes,
      _locations[_manifest.output.fileName]!: _outputBytes,
    });
    final service = ZcashSaplingParameterService(
      cacheRoot: () async => temp,
      manifest: _manifest,
      locations: _locations,
      clientFactory: (_) => client,
      proxyResolver: () => null,
    );

    final first = service.resolve(
      access: SaplingParameterAccess.downloadIfMissing,
    );
    final downloading = first.states.firstWhere(
      (state) => state is SaplingParametersDownloading,
    );
    await client.firstChunkDelivered.future;
    await downloading;
    final second = service.resolve(
      access: SaplingParameterAccess.downloadIfMissing,
    );

    expect(second, isA<SaplingParameterTaskStateSnapshot>());
    expect(
      (second as SaplingParameterTaskStateSnapshot).currentState,
      isA<SaplingParametersDownloading>(),
    );

    client.releaseFirst.complete();
    await Future.wait([first.result, second.result]);
  });

  test(
    'cancelling one shared caller detaches it without aborting another',
    () async {
      final client = _GatedClient({
        _locations[_manifest.spend.fileName]!: _spendBytes,
        _locations[_manifest.output.fileName]!: _outputBytes,
      });
      final service = ZcashSaplingParameterService(
        cacheRoot: () async => temp,
        manifest: _manifest,
        locations: _locations,
        clientFactory: (_) => client,
        proxyResolver: () => null,
      );

      final first = service.resolve(
        access: SaplingParameterAccess.downloadIfMissing,
      );
      final second = service.resolve(
        access: SaplingParameterAccess.downloadIfMissing,
      );
      await client.firstRequestStarted.future;
      final firstCancelled = expectLater(
        first.result.timeout(const Duration(milliseconds: 100)),
        throwsA(isA<ZcashSaplingParameterDownloadCancelled>()),
      );
      await first.cancel();
      await firstCancelled;
      expect(client.aborted, isFalse);

      client.releaseFirst.complete();
      final installed = await second.result;
      expect(await File(installed.spendParamsPath).readAsBytes(), _spendBytes);
    },
  );

  test(
    'download policy uses an installed pair before resolving its route',
    () async {
      final installer = ZcashSaplingParameterService(
        cacheRoot: () async => temp,
        manifest: _manifest,
        locations: _locations,
        clientFactory: (_) => _RecordingClient({
          _locations[_manifest.spend.fileName]!: _spendBytes,
          _locations[_manifest.output.fileName]!: _outputBytes,
        }),
        proxyResolver: () => null,
      );
      final installed = await installer
          .resolve(access: SaplingParameterAccess.downloadIfMissing)
          .result;
      var clientCreations = 0;
      final offline = ZcashSaplingParameterService(
        cacheRoot: () async => temp,
        manifest: _manifest,
        locations: _locations,
        clientFactory: (_) {
          clientCreations++;
          throw StateError('network client must not be created');
        },
        proxyResolver: () => throw StateError('Tor is unavailable'),
      );

      final reused = await offline
          .resolve(access: SaplingParameterAccess.downloadIfMissing)
          .result;

      expect(reused.spendParamsPath, installed.spendParamsPath);
      expect(clientCreations, 0);
    },
  );

  test(
    'successful publication and cached resolution reassert cache policy',
    () async {
      var cacheReadyCalls = 0;
      final service = ZcashSaplingParameterService(
        cacheRoot: () async => temp,
        manifest: _manifest,
        locations: _locations,
        clientFactory: (_) => _RecordingClient({
          _locations[_manifest.spend.fileName]!: _spendBytes,
          _locations[_manifest.output.fileName]!: _outputBytes,
        }),
        proxyResolver: () => null,
        onCacheReady: (_) async => cacheReadyCalls++,
      );

      await service
          .resolve(access: SaplingParameterAccess.downloadIfMissing)
          .result;
      await service.resolve().result;

      expect(cacheReadyCalls, 2);
    },
  );

  test('rejects a response that declares the wrong content length', () async {
    final service = ZcashSaplingParameterService(
      cacheRoot: () async => temp,
      manifest: _manifest,
      locations: _locations,
      clientFactory: (_) => _WrongLengthClient(_spendBytes),
      proxyResolver: () => null,
    );

    await expectLater(
      service.resolve(access: SaplingParameterAccess.downloadIfMissing).result,
      throwsA(
        isA<zcash.SaplingParameterException>().having(
          (error) => error.failure,
          'failure',
          zcash.SaplingParameterFailure.wrongSize,
        ),
      ),
    );
  });

  test(
    'accepts chunked responses after exact byte and hash verification',
    () async {
      final service = ZcashSaplingParameterService(
        cacheRoot: () async => temp,
        manifest: _manifest,
        locations: _locations,
        clientFactory: (_) => _RecordingClient({
          _locations[_manifest.spend.fileName]!: _spendBytes,
          _locations[_manifest.output.fileName]!: _outputBytes,
        }, includeContentLength: false),
        proxyResolver: () => null,
      );

      final installed = await service
          .resolve(access: SaplingParameterAccess.downloadIfMissing)
          .result;

      expect(await File(installed.spendParamsPath).readAsBytes(), _spendBytes);
      expect(
        await File(installed.outputParamsPath).readAsBytes(),
        _outputBytes,
      );
    },
  );

  test('passes the selected proxy to exactly one client factory', () async {
    final proxy = (host: InternetAddress.loopbackIPv4, port: 19050);
    SaplingParameterProxy? selectedProxy;
    var proxyResolutions = 0;
    final service = ZcashSaplingParameterService(
      cacheRoot: () async => temp,
      manifest: _manifest,
      locations: _locations,
      clientFactory: (value) {
        selectedProxy = value;
        return _RecordingClient({
          _locations[_manifest.spend.fileName]!: _spendBytes,
          _locations[_manifest.output.fileName]!: _outputBytes,
        });
      },
      proxyResolver: () {
        proxyResolutions++;
        return proxy;
      },
    );

    await service
        .resolve(access: SaplingParameterAccess.downloadIfMissing)
        .result;

    expect(proxyResolutions, 1);
    expect(selectedProxy, proxy);
  });

  test('clears a failed operation so an explicit retry can succeed', () async {
    var attempts = 0;
    final service = ZcashSaplingParameterService(
      cacheRoot: () async => temp,
      manifest: _manifest,
      locations: _locations,
      clientFactory: (_) {
        attempts++;
        if (attempts == 1) return _StatusClient(HttpStatus.badGateway);
        return _RecordingClient({
          _locations[_manifest.spend.fileName]!: _spendBytes,
          _locations[_manifest.output.fileName]!: _outputBytes,
        });
      },
      proxyResolver: () => null,
    );

    await expectLater(
      service.resolve(access: SaplingParameterAccess.downloadIfMissing).result,
      throwsA(
        isA<zcash.SaplingParameterException>().having(
          (error) => error.failure,
          'failure',
          zcash.SaplingParameterFailure.sourceInterrupted,
        ),
      ),
    );

    final installed = await service
        .resolve(access: SaplingParameterAccess.downloadIfMissing)
        .result;
    expect(attempts, 2);
    expect(await File(installed.spendParamsPath).readAsBytes(), _spendBytes);
  });

  test(
    'aborting the last caller reports a typed cancelled source failure',
    () async {
      final client = _GatedClient({
        _locations[_manifest.spend.fileName]!: _spendBytes,
        _locations[_manifest.output.fileName]!: _outputBytes,
      });
      final service = ZcashSaplingParameterService(
        cacheRoot: () async => temp,
        manifest: _manifest,
        locations: _locations,
        clientFactory: (_) => client,
        proxyResolver: () => null,
      );
      final task = service.resolve(
        access: SaplingParameterAccess.downloadIfMissing,
      );
      final states = task.states.toList();
      final cancelled = expectLater(
        task.result,
        throwsA(isA<ZcashSaplingParameterDownloadCancelled>()),
      );
      await client.firstRequestStarted.future;

      await task.cancel();
      await cancelled;
      final failure = (await states)
          .whereType<SaplingParametersFailed>()
          .single;

      expect(client.aborted, isTrue);
      expect(
        failure.error,
        isA<zcash.SaplingParameterException>().having(
          (error) => error.failure,
          'failure',
          zcash.SaplingParameterFailure.cancelled,
        ),
      );
    },
  );

  test(
    'an immediate retry waits for an aborted acquisition to unwind',
    () async {
      final firstClient = _GatedClient({
        _locations[_manifest.spend.fileName]!: _spendBytes,
        _locations[_manifest.output.fileName]!: _outputBytes,
      });
      var clientCreations = 0;
      final service = ZcashSaplingParameterService(
        cacheRoot: () async => temp,
        manifest: _manifest,
        locations: _locations,
        clientFactory: (_) {
          clientCreations++;
          if (clientCreations == 1) return firstClient;
          return _RecordingClient({
            _locations[_manifest.spend.fileName]!: _spendBytes,
            _locations[_manifest.output.fileName]!: _outputBytes,
          });
        },
        proxyResolver: () => null,
      );
      final first = service.resolve(
        access: SaplingParameterAccess.downloadIfMissing,
      );
      final firstCancelled = expectLater(
        first.result,
        throwsA(isA<ZcashSaplingParameterDownloadCancelled>()),
      );
      await firstClient.firstRequestStarted.future;
      await first.cancel();

      final retry = service.resolve(
        access: SaplingParameterAccess.downloadIfMissing,
      );
      final installed = await retry.result;
      await firstCancelled;

      expect(clientCreations, 2);
      expect(await File(installed.spendParamsPath).readAsBytes(), _spendBytes);
    },
  );
}

final class _RecordingClient extends http.BaseClient {
  _RecordingClient(this.bytesByUri, {this.includeContentLength = true});

  final Map<Uri, List<int>> bytesByUri;
  final bool includeContentLength;
  final List<Uri> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request.url);
    final bytes = bytesByUri[request.url]!;
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable([
        bytes.sublist(0, bytes.length ~/ 2),
        bytes.sublist(bytes.length ~/ 2),
      ]),
      HttpStatus.ok,
      contentLength: includeContentLength ? bytes.length : null,
    );
  }
}

final class _GatedClient extends http.BaseClient {
  _GatedClient(this.bytesByUri);

  final Map<Uri, List<int>> bytesByUri;
  final Completer<void> firstRequestStarted = Completer<void>();
  final Completer<void> releaseFirst = Completer<void>();
  bool aborted = false;
  var _requests = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = bytesByUri[request.url]!;
    _requests++;
    if (_requests > 1) {
      return http.StreamedResponse(
        Stream.value(bytes),
        HttpStatus.ok,
        contentLength: bytes.length,
      );
    }
    firstRequestStarted.complete();
    final controller = StreamController<List<int>>();
    if (request case http.Abortable(:final abortTrigger?)) {
      unawaited(
        abortTrigger.then((_) {
          aborted = true;
          controller
            ..addError(http.RequestAbortedException(request.url))
            ..close();
        }),
      );
    }
    unawaited(
      releaseFirst.future.then((_) {
        if (!controller.isClosed) {
          controller
            ..add(bytes)
            ..close();
        }
      }),
    );
    return http.StreamedResponse(
      controller.stream,
      HttpStatus.ok,
      contentLength: bytes.length,
    );
  }
}

final class _PartiallyGatedClient extends http.BaseClient {
  _PartiallyGatedClient(this.bytesByUri);

  final Map<Uri, List<int>> bytesByUri;
  final Completer<void> firstChunkDelivered = Completer<void>();
  final Completer<void> releaseFirst = Completer<void>();
  var _requests = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = bytesByUri[request.url]!;
    _requests++;
    if (_requests > 1) {
      return http.StreamedResponse(
        Stream.value(bytes),
        HttpStatus.ok,
        contentLength: bytes.length,
      );
    }

    final controller = StreamController<List<int>>();
    scheduleMicrotask(() {
      controller.add(bytes.sublist(0, 1));
      firstChunkDelivered.complete();
    });
    unawaited(
      releaseFirst.future.then((_) {
        controller
          ..add(bytes.sublist(1))
          ..close();
      }),
    );
    return http.StreamedResponse(
      controller.stream,
      HttpStatus.ok,
      contentLength: bytes.length,
    );
  }
}

final class _WrongLengthClient extends http.BaseClient {
  _WrongLengthClient(this.bytes);

  final List<int> bytes;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(
        Stream.value(bytes),
        HttpStatus.ok,
        contentLength: bytes.length + 1,
      );
}

final class _StatusClient extends http.BaseClient {
  _StatusClient(this.statusCode);

  final int statusCode;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(const Stream.empty(), statusCode);
}

final _spendBytes = <int>[1, 2, 3, 4];
final _outputBytes = <int>[5, 6, 7];

final _manifest = zcash.SaplingParameterManifest(
  version: 'test-v1',
  spend: zcash.SaplingParameterArtifact(
    fileName: 'sapling-spend.params',
    expectedBytes: _spendBytes.length,
    sha256Hex: sha256.convert(_spendBytes).toString(),
  ),
  output: zcash.SaplingParameterArtifact(
    fileName: 'sapling-output.params',
    expectedBytes: _outputBytes.length,
    sha256Hex: sha256.convert(_outputBytes).toString(),
  ),
);

final _locations = <String, Uri>{
  _manifest.spend.fileName: Uri.parse('https://params.test/spend'),
  _manifest.output.fileName: Uri.parse('https://params.test/output'),
};
