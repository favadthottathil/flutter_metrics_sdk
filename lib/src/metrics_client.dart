import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import 'metric_record.dart';
import 'metrics_event.dart';

/// Entry point for the Flutter Metrics SDK.
///
/// A [MetricsClient] buffers telemetry events in memory and periodically
/// flushes them to the backend in a single batched request, keeping
/// per-event overhead to essentially zero allocations and no network I/O.
///
/// ```dart
/// final metrics = MetricsClient(
///   apiKey: 'app_live_xxxxxxxxx',
///   baseUrl: 'https://your-backend.example.com',
/// );
/// ```
///
/// Call [dispose] when the client is no longer needed (e.g. in
/// `App.dispose`) to flush any buffered events and cancel the flush timer.
class MetricsClient with WidgetsBindingObserver {
  final Dio _dio;
  bool _enabled;
  final int _maxBatchSize;
  final int _maxBufferSize;
  final double _sampleRate;
  final Random _random = Random();

  final List<MetricRecord> _buffer = [];
  Timer? _flushTimer;
  bool _observerAttached = false;

  /// Guards against two flushes running at once — the periodic timer and a
  /// [maxBatchSize] trip can otherwise overlap, letting the second call
  /// observe a buffer the first has already taken.
  bool _flushInProgress = false;

  /// Creates a new client and starts its periodic flush timer.
  ///
  /// - [apiKey]: app-level API key generated from the dashboard, sent as
  ///   the `x-api-key` header.
  /// - [baseUrl]: base URL of the metrics ingestion backend.
  /// - [enabled]: when `false`, all calls to [sendMetric] are no-ops.
  /// - [maxBatchSize]: number of buffered events that triggers an
  ///   immediate flush, independent of [flushInterval]. Defaults to `20`.
  /// - [maxBufferSize]: hard cap on buffered events. Once reached, the
  ///   oldest events are discarded to bound memory use while the device is
  ///   offline. Defaults to `1000`.
  /// - [flushInterval]: how often buffered events are flushed to the
  ///   backend even if [maxBatchSize] hasn't been reached. Defaults to
  ///   5 seconds.
  /// - [sampleRate]: fraction (`0.0`-`1.0`) of high-frequency frame
  ///   render events to keep. Defaults to `1.0` (capture everything).
  ///   Crash, API and screen events are always captured regardless of
  ///   this setting.
  /// - [attachLifecycleObserver]: when `true` (the default), the client
  ///   registers itself as a [WidgetsBindingObserver] and flushes any
  ///   buffered events when the app is paused, inactive or detached.
  /// - [httpClient]: overrides the internal [Dio] instance. Intended for
  ///   tests that need to inject a fake [HttpClientAdapter].
  MetricsClient({
    required String apiKey,
    required String baseUrl,
    bool enabled = true,
    int maxBatchSize = 20,
    int maxBufferSize = 1000,
    Duration flushInterval = const Duration(seconds: 5),
    double sampleRate = 1.0,
    bool attachLifecycleObserver = true,
    @visibleForTesting Dio? httpClient,
  }) : _enabled = enabled,
       // The cap is authoritative: it is the memory bound, so a large
       // maxBatchSize is clamped to it rather than overriding it.
       _maxBatchSize = min(maxBatchSize, maxBufferSize),
       _maxBufferSize = maxBufferSize,
       _sampleRate = sampleRate.clamp(0.0, 1.0),
       _dio =
           httpClient ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               headers: {
                 'x-api-key': apiKey,
                 'Content-Type': 'application/json',
               },
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 15),
             ),
           ) {
    _flushTimer = Timer.periodic(flushInterval, (_) => flush());

    if (attachLifecycleObserver) {
      WidgetsBinding.instance.addObserver(this);
      _observerAttached = true;
    }
  }

  /// Re-enables capturing and sending metrics.
  void enable() => _enabled = true;

  /// Disables the client. While disabled, [sendMetric] is a no-op and the
  /// buffer is not flushed.
  void disable() => _enabled = false;

  /// Number of events currently buffered awaiting delivery.
  @visibleForTesting
  int get bufferedCount => _buffer.length;

  /// Queues a telemetry event for delivery.
  ///
  /// Events are not sent immediately — they are buffered and delivered in
  /// batches by [flush], which runs periodically and whenever the buffer
  /// reaches its configured `maxBatchSize`.
  ///
  /// [screen] must always name a real, user-visible screen. For events
  /// whose subject is something else — an endpoint path, an error handler
  /// — pass that as [target] so the backend can attribute the event to the
  /// screen it happened on without inventing a phantom screen for it.
  ///
  /// Frame-render events ([MetricsEvent.appRender]) are subject to
  /// [sampleRate]; all other event types are always queued.
  void sendMetric({
    required String event,
    required String screen,
    String? target,
    int? frameTimeMs,
    bool? frameDropped,
    int? renderTimeMs,
    int? apiLatencyMs,
    bool? isError,
    String? errorMessage,
    String? stackTrace,
    int? screenLoadTimeMs,
  }) {
    if (!_enabled) return;
    if (event.isEmpty || screen.isEmpty) return;

    if (event == MetricsEvent.appRender && _sampleRate < 1.0) {
      if (_random.nextDouble() > _sampleRate) return;
    }

    // Bound memory growth when the device is offline for a long time.
    // Oldest events are dropped first: recent telemetry is the more useful
    // signal, and an unbounded buffer would eventually exhaust the heap.
    if (_buffer.length >= _maxBufferSize) {
      _buffer.removeRange(0, _buffer.length - _maxBufferSize + 1);
    }

    _buffer.add(
      MetricRecord(
        event: event,
        screen: screen,
        target: target,
        frameTimeMs: frameTimeMs,
        frameDropped: frameDropped,
        renderTimeMs: renderTimeMs,
        apiLatencyMs: apiLatencyMs,
        isError: isError,
        errorMessage: errorMessage,
        stackTrace: stackTrace,
        screenLoadTimeMs: screenLoadTimeMs,
      ),
    );

    if (_buffer.length >= _maxBatchSize) {
      flush();
    }
  }

  /// Sends all currently buffered events to `/metrics/batch` in a single
  /// request and clears the buffer.
  ///
  /// Safe to call manually (e.g. before navigating away from the app).
  /// Failures are swallowed by design — telemetry must never crash or
  /// block the host app. Events lost to a *transient* failure (network
  /// error, timeout, 5xx) are returned to the front of the buffer and
  /// retried on the next flush; events rejected outright (4xx) are dropped,
  /// since retrying them would never succeed.
  Future<void> flush() async {
    if (!_enabled || _buffer.isEmpty || _flushInProgress) return;

    _flushInProgress = true;

    final batch = List<MetricRecord>.from(_buffer);
    _buffer.clear();

    try {
      await _dio.post(
        '/metrics/batch',
        data: {'metrics': batch.map((m) => m.toJson()).toList()},
      );
    } on DioException catch (e) {
      if (_isRetryable(e)) {
        _requeue(batch);
      }
      // Non-retryable (4xx): the payload is rejected, so it is dropped.
    } catch (_) {
      // Unexpected local failure (e.g. serialization). Dropped by design —
      // telemetry must never crash or block the host app.
    } finally {
      _flushInProgress = false;
    }
  }

  /// Whether a failed request is worth retrying. Anything that is not a
  /// definitive rejection by the server is treated as transient.
  static bool _isRetryable(DioException e) {
    final status = e.response?.statusCode;
    if (status == null) return true; // network error, timeout, no response
    return status >= 500 || status == 408 || status == 429;
  }

  /// Returns a failed batch to the front of the buffer, preserving event
  /// order, while respecting the buffer cap.
  void _requeue(List<MetricRecord> batch) {
    _buffer.insertAll(0, batch);

    if (_buffer.length > _maxBufferSize) {
      _buffer.removeRange(0, _buffer.length - _maxBufferSize);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      flush();
    }
  }

  /// Flushes any remaining buffered events, cancels the flush timer and
  /// detaches the lifecycle observer.
  Future<void> dispose() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_observerAttached) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAttached = false;
    }
    await flush();
  }
}
