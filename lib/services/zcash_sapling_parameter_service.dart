import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:socks5_proxy/socks_client.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import '../app_config.dart';
import '../utilities/prefs.dart';
import '../utilities/stack_file_system.dart';
import 'tor_service.dart';

enum SaplingParameterAccess { cachedOnly, downloadIfMissing }

sealed class SaplingParameterState {
  const SaplingParameterState();
}

final class SaplingParametersChecking extends SaplingParameterState {
  const SaplingParametersChecking();
}

final class SaplingParametersDownloading extends SaplingParameterState {
  const SaplingParametersDownloading({
    required this.fileName,
    required this.receivedBytes,
    required this.totalReceivedBytes,
    required this.totalExpectedBytes,
  });

  final String fileName;
  final int receivedBytes;
  final int totalReceivedBytes;
  final int totalExpectedBytes;
}

final class SaplingParametersVerifying extends SaplingParameterState {
  const SaplingParametersVerifying();
}

final class SaplingParametersReady extends SaplingParameterState {
  const SaplingParametersReady();
}

final class SaplingParametersFailed extends SaplingParameterState {
  const SaplingParametersFailed(this.error);

  final Object error;
}

final class ZcashSaplingParametersRequired implements Exception {
  const ZcashSaplingParametersRequired();

  @override
  String toString() =>
      'Additional verified Sapling proving data must be downloaded';
}

final class ZcashSaplingParameterDownloadCancelled implements Exception {
  const ZcashSaplingParameterDownloadCancelled();

  @override
  String toString() => 'Sapling proving-data download was cancelled';
}

abstract interface class SaplingParameterTask {
  Future<zcash.SaplingProvingParameters> get result;

  Stream<SaplingParameterState> get states;

  Future<void> cancel();
}

typedef SaplingParameterCacheRoot = Future<Directory> Function();
typedef SaplingParameterProxy = ({InternetAddress host, int port});
typedef SaplingParameterProxyResolver = SaplingParameterProxy? Function();
typedef SaplingParameterHttpClientFactory = http.Client Function(
  SaplingParameterProxy? proxy,
);
typedef SaplingParameterCacheReady = Future<void> Function(Directory root);

final class ZcashSaplingParameterService {
  static final ZcashSaplingParameterService instance =
      ZcashSaplingParameterService(
        cacheRoot: StackFileSystem.saplingParameterCacheRoot,
        manifest: zcash.officialSaplingParameterManifestV1,
        locations: {
          'sapling-spend.params': Uri.https(
            'download.z.cash',
            '/downloads/sapling-spend.params',
          ),
          'sapling-output.params': Uri.https(
            'download.z.cash',
            '/downloads/sapling-output.params',
          ),
        },
        clientFactory: _productionHttpClient,
        proxyResolver: _productionProxy,
        onCacheReady: (_) =>
            StackFileSystem.excludeSaplingParametersFromBackup(),
      );

  factory ZcashSaplingParameterService({
    required SaplingParameterCacheRoot cacheRoot,
    required zcash.SaplingParameterManifest manifest,
    required Map<String, Uri> locations,
    required SaplingParameterHttpClientFactory clientFactory,
    required SaplingParameterProxyResolver proxyResolver,
    SaplingParameterCacheReady? onCacheReady,
  }) => ZcashSaplingParameterService._(
    cacheRoot,
    manifest,
    Map.unmodifiable(locations),
    clientFactory,
    proxyResolver,
    onCacheReady ?? _ignoreReadyCache,
  );

  ZcashSaplingParameterService._(
    this._cacheRoot,
    this.manifest,
    this.locations,
    this._clientFactory,
    this._proxyResolver,
    this._onCacheReady,
  );

  final SaplingParameterCacheRoot _cacheRoot;
  final zcash.SaplingParameterManifest manifest;
  final Map<String, Uri> locations;
  final SaplingParameterHttpClientFactory _clientFactory;
  final SaplingParameterProxyResolver _proxyResolver;
  final SaplingParameterCacheReady _onCacheReady;
  _SharedSaplingParameterOperation? _activeDownload;

  SaplingParameterTask resolve({
    SaplingParameterAccess access = SaplingParameterAccess.cachedOnly,
  }) {
    if (access == SaplingParameterAccess.downloadIfMissing) {
      final active = _activeDownload;
      if (active != null) {
        if (!active.abort.isCompleted) {
          return active.attach();
        }
        return _startDownload(after: active.settled);
      }
      return _startDownload();
    }
    final states = StreamController<SaplingParameterState>.broadcast();
    final result = Future<zcash.SaplingProvingParameters>.microtask(() {
      if (_activeDownload != null) {
        unawaited(states.close());
        throw const ZcashSaplingParametersRequired();
      }
      return _resolveCached(states);
    });
    return _SimpleSaplingParameterTask(
      result: result,
      states: states.stream,
      onCancel: _ignoreCancellation,
    );
  }

  SaplingParameterTask _startDownload({Future<void>? after}) {
    final states = StreamController<SaplingParameterState>.broadcast();
    final abort = Completer<void>();
    late final _SharedSaplingParameterOperation operation;
    final result =
        Future<zcash.SaplingProvingParameters>.microtask(() async {
          await after;
          return _resolveWithDownload(states, abort);
        }).whenComplete(() {
          if (identical(_activeDownload, operation)) {
            _activeDownload = null;
          }
        });
    operation = _SharedSaplingParameterOperation(
      result: result,
      states: states.stream,
      abort: abort,
    );
    _activeDownload = operation;
    return operation.attach();
  }

  Future<zcash.SaplingProvingParameters> _resolveCached(
    StreamController<SaplingParameterState> states,
  ) async {
    states.add(const SaplingParametersChecking());
    try {
      final root = await _cacheRoot();
      final parameters = await zcash.SaplingProvingParameterCache(
        cacheRoot: root,
        manifest: manifest,
      ).resolve();
      await _onCacheReady(root);
      states.add(const SaplingParametersReady());
      return parameters;
    } on zcash.SaplingParameterException catch (error) {
      if (error.failure == zcash.SaplingParameterFailure.unavailable) {
        throw const ZcashSaplingParametersRequired();
      }
      rethrow;
    } finally {
      unawaited(states.close());
    }
  }

  Future<zcash.SaplingProvingParameters> _resolveWithDownload(
    StreamController<SaplingParameterState> states,
    Completer<void> abort,
  ) async {
    states.add(const SaplingParametersChecking());
    http.Client? client;
    try {
      if (abort.isCompleted) {
        throw const zcash.SaplingParameterException(
          zcash.SaplingParameterFailure.cancelled,
          'Sapling parameter acquisition was cancelled',
        );
      }
      final root = await _cacheRoot();
      final cache = zcash.SaplingProvingParameterCache(
        cacheRoot: root,
        manifest: manifest,
        requestTimeout: const Duration(seconds: 60),
        totalTimeout: const Duration(minutes: 30),
      );
      try {
        final cached = await cache.resolve();
        await _onCacheReady(root);
        states.add(const SaplingParametersReady());
        return cached;
      } on zcash.SaplingParameterException catch (error) {
        if (error.failure != zcash.SaplingParameterFailure.unavailable) {
          rethrow;
        }
      }
      final proxy = _proxyResolver();
      client = _clientFactory(proxy);
      final receivedByFile = <String, int>{};
      final totalExpectedBytes =
          manifest.spend.expectedBytes + manifest.output.expectedBytes;
      final source = _HttpsSaplingParameterSource(
        manifest: manifest,
        locations: locations,
        client: client,
        abortTrigger: abort.future,
        onProgress: (artifact, receivedBytes) {
          receivedByFile[artifact.fileName] = receivedBytes;
          final totalReceivedBytes = receivedByFile.values.fold<int>(
            0,
            (sum, value) => sum + value,
          );
          states.add(
            SaplingParametersDownloading(
              fileName: artifact.fileName,
              receivedBytes: receivedBytes,
              totalReceivedBytes: totalReceivedBytes,
              totalExpectedBytes: totalExpectedBytes,
            ),
          );
          if (totalReceivedBytes == totalExpectedBytes) {
            states.add(const SaplingParametersVerifying());
          }
        },
      );
      final parameters = await cache.resolve(
        source: source,
        isCancelled: () => abort.isCompleted,
      );
      await _onCacheReady(root);
      states.add(const SaplingParametersReady());
      return parameters;
    } catch (error) {
      states.add(SaplingParametersFailed(error));
      rethrow;
    } finally {
      client?.close();
      unawaited(states.close());
    }
  }
}

Future<void> _ignoreReadyCache(Directory _) async {}

Future<void> _ignoreCancellation() async {}

SaplingParameterProxy? _productionProxy() {
  if (!AppConfig.hasFeature(AppFeature.tor) || !Prefs.instance.useTor) {
    return null;
  }
  return TorService.sharedInstance.getProxyInfo();
}

http.Client _productionHttpClient(SaplingParameterProxy? proxy) {
  final client = HttpClient()
    ..autoUncompress = false
    ..connectionTimeout = const Duration(seconds: 30);
  if (proxy != null) {
    SocksTCPClient.assignToHttpClient(client, [
      ProxySettings(proxy.host, proxy.port),
    ]);
  }
  return IOClient(client);
}

typedef _SaplingParameterProgress = void Function(
  zcash.SaplingParameterArtifact artifact,
  int receivedBytes,
);

final class _HttpsSaplingParameterSource
    implements zcash.SaplingParameterSource {
  const _HttpsSaplingParameterSource({
    required this.manifest,
    required this.locations,
    required this.client,
    required this.abortTrigger,
    required this.onProgress,
  });

  final zcash.SaplingParameterManifest manifest;
  final Map<String, Uri> locations;
  final http.Client client;
  final Future<void> abortTrigger;
  final _SaplingParameterProgress onProgress;

  @override
  Stream<List<int>> open(zcash.SaplingParameterArtifact artifact) async* {
    final uri = locations[artifact.fileName];
    if (uri == null || uri.scheme != 'https') {
      throw const zcash.SaplingParameterException(
        zcash.SaplingParameterFailure.invalidManifest,
        'a Sapling parameter source location is invalid',
      );
    }
    final request =
        http.AbortableRequest('GET', uri, abortTrigger: abortTrigger)
          ..followRedirects = false
          ..headers[HttpHeaders.acceptEncodingHeader] = 'identity';
    try {
      final response = await client.send(request);
      if (response.statusCode != HttpStatus.ok || response.isRedirect) {
        throw const zcash.SaplingParameterException(
          zcash.SaplingParameterFailure.sourceInterrupted,
          'a Sapling parameter source returned an invalid response',
        );
      }
      final contentLength = response.contentLength;
      if (contentLength != null && contentLength != artifact.expectedBytes) {
        throw const zcash.SaplingParameterException(
          zcash.SaplingParameterFailure.wrongSize,
          'a Sapling parameter source declared an invalid size',
        );
      }
      var receivedBytes = 0;
      await for (final chunk in response.stream) {
        receivedBytes += chunk.length;
        onProgress(artifact, receivedBytes);
        yield chunk;
      }
    } on http.RequestAbortedException {
      throw const zcash.SaplingParameterException(
        zcash.SaplingParameterFailure.cancelled,
        'Sapling parameter acquisition was cancelled',
      );
    }
  }
}

final class _SimpleSaplingParameterTask implements SaplingParameterTask {
  _SimpleSaplingParameterTask({
    required this.result,
    required this.states,
    required this.onCancel,
  });

  @override
  final Future<zcash.SaplingProvingParameters> result;

  @override
  final Stream<SaplingParameterState> states;

  final Future<void> Function() onCancel;

  @override
  Future<void> cancel() => onCancel();
}

final class _SharedSaplingParameterOperation {
  _SharedSaplingParameterOperation({
    required this.result,
    required this.states,
    required this.abort,
  });

  final Future<zcash.SaplingProvingParameters> result;
  final Stream<SaplingParameterState> states;
  final Completer<void> abort;
  int _consumers = 0;

  Future<void> get settled =>
      result.then<void>((_) {}, onError: (Object _, StackTrace __) {});

  SaplingParameterTask attach() {
    _consumers++;
    var attached = true;
    final consumerResult = Completer<zcash.SaplingProvingParameters>();
    unawaited(
      result.then(
        (parameters) {
          if (!consumerResult.isCompleted) {
            consumerResult.complete(parameters);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!consumerResult.isCompleted) {
            consumerResult.completeError(error, stackTrace);
          }
        },
      ),
    );
    return _SimpleSaplingParameterTask(
      result: consumerResult.future,
      states: states,
      onCancel: () async {
        if (!attached) return;
        attached = false;
        _consumers--;
        if (!consumerResult.isCompleted) {
          consumerResult.completeError(
            const ZcashSaplingParameterDownloadCancelled(),
          );
        }
        if (_consumers == 0 && !abort.isCompleted) {
          abort.complete();
        }
      },
    );
  }
}
