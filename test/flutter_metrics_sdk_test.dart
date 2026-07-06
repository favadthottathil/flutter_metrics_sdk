import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_metrics_sdk/flutter_metrics_sdk.dart';

/// A fake [HttpClientAdapter] that records every request it receives and
/// always responds with `200 {}`.
class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A fake [HttpClientAdapter] that always fails, used to verify that
/// failed flushes don't throw.
class _FailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(requestOptions: options, message: 'boom');
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWithAdapter(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.httpClientAdapter = adapter;
  return dio;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MetricsClient batching', () {
    test('sendMetric does not send immediately', () async {
      final adapter = _RecordingAdapter();
      final client = MetricsClient(
        apiKey: 'test-key',
        baseUrl: 'https://example.test',
        httpClient: _dioWithAdapter(adapter),
        attachLifecycleObserver: false,
        flushInterval: const Duration(minutes: 5),
      );

      client.sendMetric(event: MetricsEvent.screenOpen, screen: 'home');

      expect(adapter.requests, isEmpty);
    });

    test(
      'flush sends a single batched request with all queued metrics',
      () async {
        final adapter = _RecordingAdapter();
        final client = MetricsClient(
          apiKey: 'test-key',
          baseUrl: 'https://example.test',
          httpClient: _dioWithAdapter(adapter),
          attachLifecycleObserver: false,
          flushInterval: const Duration(minutes: 5),
        );

        client.sendMetric(event: MetricsEvent.screenOpen, screen: 'home');
        client.sendMetric(
          event: MetricsEvent.appRender,
          screen: 'home',
          renderTimeMs: 20,
          frameDropped: true,
        );

        await client.flush();

        expect(adapter.requests, hasLength(1));
        final request = adapter.requests.single;
        expect(request.path, '/metrics/batch');

        final body = request.data as Map<String, dynamic>;
        final metrics = body['metrics'] as List;
        expect(metrics, hasLength(2));
        expect(metrics[0]['event'], MetricsEvent.screenOpen);
        expect(metrics[0]['screen'], 'home');
        expect(metrics[0]['client_timestamp'], isA<String>());
        expect(metrics[1]['event'], MetricsEvent.appRender);
        expect(metrics[1]['render_time'], 20);
        expect(metrics[1]['frame_dropped'], true);
      },
    );

    test('flush with an empty buffer sends nothing', () async {
      final adapter = _RecordingAdapter();
      final client = MetricsClient(
        apiKey: 'test-key',
        baseUrl: 'https://example.test',
        httpClient: _dioWithAdapter(adapter),
        attachLifecycleObserver: false,
        flushInterval: const Duration(minutes: 5),
      );

      await client.flush();

      expect(adapter.requests, isEmpty);
    });

    test('buffer auto-flushes once maxBatchSize is reached', () async {
      final adapter = _RecordingAdapter();
      final client = MetricsClient(
        apiKey: 'test-key',
        baseUrl: 'https://example.test',
        httpClient: _dioWithAdapter(adapter),
        attachLifecycleObserver: false,
        flushInterval: const Duration(minutes: 5),
        maxBatchSize: 2,
      );

      client.sendMetric(event: MetricsEvent.screenOpen, screen: 'a');
      expect(adapter.requests, isEmpty);

      client.sendMetric(event: MetricsEvent.screenOpen, screen: 'b');
      // The auto-flush triggered by hitting maxBatchSize runs async.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(adapter.requests, hasLength(1));
      final metrics =
          (adapter.requests.single.data as Map<String, dynamic>)['metrics']
              as List;
      expect(metrics, hasLength(2));
    });

    test('failed flush is swallowed and clears the buffer', () async {
      final client = MetricsClient(
        apiKey: 'test-key',
        baseUrl: 'https://example.test',
        httpClient: _dioWithAdapter(_FailingAdapter()),
        attachLifecycleObserver: false,
        flushInterval: const Duration(minutes: 5),
      );

      client.sendMetric(event: MetricsEvent.screenOpen, screen: 'home');

      await expectLater(client.flush(), completes);
    });

    test('disabled client does not buffer or send metrics', () async {
      final adapter = _RecordingAdapter();
      final client = MetricsClient(
        apiKey: 'test-key',
        baseUrl: 'https://example.test',
        httpClient: _dioWithAdapter(adapter),
        attachLifecycleObserver: false,
        flushInterval: const Duration(minutes: 5),
        enabled: false,
      );

      client.sendMetric(event: MetricsEvent.screenOpen, screen: 'home');
      await client.flush();

      expect(adapter.requests, isEmpty);
    });

    test('dispose flushes remaining metrics and stops the timer', () async {
      final adapter = _RecordingAdapter();
      final client = MetricsClient(
        apiKey: 'test-key',
        baseUrl: 'https://example.test',
        httpClient: _dioWithAdapter(adapter),
        attachLifecycleObserver: false,
        flushInterval: const Duration(minutes: 5),
      );

      client.sendMetric(event: MetricsEvent.screenOpen, screen: 'home');
      await client.dispose();

      expect(adapter.requests, hasLength(1));
    });
  });

  group('MetricsClient sampling', () {
    test('sampleRate of 0 drops app_render events', () async {
      final adapter = _RecordingAdapter();
      final client = MetricsClient(
        apiKey: 'test-key',
        baseUrl: 'https://example.test',
        httpClient: _dioWithAdapter(adapter),
        attachLifecycleObserver: false,
        flushInterval: const Duration(minutes: 5),
        sampleRate: 0.0,
      );

      for (var i = 0; i < 10; i++) {
        client.sendMetric(
          event: MetricsEvent.appRender,
          screen: 'home',
          renderTimeMs: 10,
        );
      }
      await client.flush();

      expect(adapter.requests, isEmpty);
    });

    test('sampleRate does not affect non-render events', () async {
      final adapter = _RecordingAdapter();
      final client = MetricsClient(
        apiKey: 'test-key',
        baseUrl: 'https://example.test',
        httpClient: _dioWithAdapter(adapter),
        attachLifecycleObserver: false,
        flushInterval: const Duration(minutes: 5),
        sampleRate: 0.0,
      );

      client.sendMetric(event: MetricsEvent.crash, screen: 'home');
      await client.flush();

      expect(adapter.requests, hasLength(1));
      final metrics =
          (adapter.requests.single.data as Map<String, dynamic>)['metrics']
              as List;
      expect(metrics, hasLength(1));
      expect(metrics.single['event'], MetricsEvent.crash);
    });

    test('sampleRate of 1 keeps all app_render events', () async {
      final adapter = _RecordingAdapter();
      final client = MetricsClient(
        apiKey: 'test-key',
        baseUrl: 'https://example.test',
        httpClient: _dioWithAdapter(adapter),
        attachLifecycleObserver: false,
        flushInterval: const Duration(minutes: 5),
        sampleRate: 1.0,
        maxBatchSize: 1000,
      );

      for (var i = 0; i < 5; i++) {
        client.sendMetric(
          event: MetricsEvent.appRender,
          screen: 'home',
          renderTimeMs: 10,
        );
      }
      await client.flush();

      final metrics =
          (adapter.requests.single.data as Map<String, dynamic>)['metrics']
              as List;
      expect(metrics, hasLength(5));
    });
  });

  group('FrameTracker.isDropped', () {
    test('frame within the default 16ms budget is not dropped', () {
      expect(FrameTracker.isDropped(10), isFalse);
      expect(FrameTracker.isDropped(16), isFalse);
    });

    test('frame exceeding the default 16ms budget is dropped', () {
      expect(FrameTracker.isDropped(17), isTrue);
    });

    test('respects a custom frame budget (e.g. 120Hz displays)', () {
      expect(FrameTracker.isDropped(10, frameBudgetMs: 8), isTrue);
      expect(FrameTracker.isDropped(8, frameBudgetMs: 8), isFalse);
    });
  });

  group('ApiMetricsInterceptor', () {
    test('records latency for a successful request', () async {
      final metricsAdapter = _RecordingAdapter();
      final metrics = MetricsClient(
        apiKey: 'test-key',
        baseUrl: 'https://example.test',
        httpClient: _dioWithAdapter(metricsAdapter),
        attachLifecycleObserver: false,
        flushInterval: const Duration(minutes: 5),
      );

      final apiAdapter = _RecordingAdapter();
      final api = _dioWithAdapter(apiAdapter);
      api.interceptors.add(ApiMetricsInterceptor(metrics));

      await api.get('/users/42');
      await metrics.flush();

      final batch =
          (metricsAdapter.requests.single.data
                  as Map<String, dynamic>)['metrics']
              as List;
      expect(batch, hasLength(1));
      expect(batch.single['event'], MetricsEvent.apiCall);
      expect(batch.single['screen'], '/users/42');
      expect(batch.single['api_latency'], isA<int>());
    });

    test('records an api_error event for a failed request', () async {
      final metricsAdapter = _RecordingAdapter();
      final metrics = MetricsClient(
        apiKey: 'test-key',
        baseUrl: 'https://example.test',
        httpClient: _dioWithAdapter(metricsAdapter),
        attachLifecycleObserver: false,
        flushInterval: const Duration(minutes: 5),
      );

      final api = _dioWithAdapter(_FailingAdapter());
      api.interceptors.add(ApiMetricsInterceptor(metrics));

      await expectLater(api.get('/users/42'), throwsA(isA<DioException>()));
      await metrics.flush();

      final batch =
          (metricsAdapter.requests.single.data
                  as Map<String, dynamic>)['metrics']
              as List;
      expect(batch, hasLength(1));
      expect(batch.single['event'], MetricsEvent.apiError);
      expect(batch.single['is_error'], true);
    });
  });

  group('CrashTracker', () {
    test(
      'reports an app_crash event when FlutterError.onError fires',
      () async {
        final adapter = _RecordingAdapter();
        final metrics = MetricsClient(
          apiKey: 'test-key',
          baseUrl: 'https://example.test',
          httpClient: _dioWithAdapter(adapter),
          attachLifecycleObserver: false,
          flushInterval: const Duration(minutes: 5),
        );

        final originalOnError = FlutterError.onError;
        final originalPlatformOnError = PlatformDispatcher.instance.onError;
        addTearDown(() {
          FlutterError.onError = originalOnError;
          PlatformDispatcher.instance.onError = originalPlatformOnError;
        });

        CrashTracker.initialize(metrics);

        FlutterError.onError!(
          FlutterErrorDetails(exception: Exception('boom')),
        );

        await metrics.flush();

        final batch =
            (adapter.requests.single.data as Map<String, dynamic>)['metrics']
                as List;
        expect(batch, hasLength(1));
        expect(batch.single['event'], MetricsEvent.crash);
        expect(batch.single['is_error'], true);
        expect(batch.single['error_message'], contains('boom'));
      },
    );
  });
}
