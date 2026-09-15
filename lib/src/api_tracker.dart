import 'package:dio/dio.dart';
import 'metrics_client.dart';
import 'metrics_event.dart';
import 'screen_context.dart';

/// A Dio [Interceptor] that measures the latency of every request made
/// through the interceptor's [Dio] instance and reports it as either an
/// [MetricsEvent.apiCall] or [MetricsEvent.apiError] event.
///
/// The request path is reported as the event's `target`, while `screen`
/// holds the screen that was visible when the request completed, so API
/// latency is attributed to the screen that incurred it.
///
/// Add it to a [Dio] client's interceptors:
///
/// ```dart
/// dio.interceptors.add(ApiMetricsInterceptor(metrics));
/// ```
class ApiMetricsInterceptor extends Interceptor {
  final MetricsClient client;

  /// Supplies the screen that is currently visible. Defaults to the
  /// ambient [ScreenContext], which [ScreenTracker] keeps up to date.
  final ScreenContext _screenContext;

  /// Start times are keyed by a token stored on the request itself rather
  /// than by [RequestOptions] identity, because Dio reuses (and sometimes
  /// copies) the options object across retries and redirects.
  static const String _startTimeKey = '_metricsSdkStartedAtMicros';

  ApiMetricsInterceptor(this.client, {ScreenContext? screenContext})
    : _screenContext = screenContext ?? ScreenContext.instance;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startTimeKey] = DateTime.now().microsecondsSinceEpoch;
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _recordApiLatency(response.requestOptions, response.statusCode);
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _recordApiLatency(
      err.requestOptions,
      err.response?.statusCode,
      isError: true,
      errorMessage: err.message,
    );
    super.onError(err, handler);
  }

  void _recordApiLatency(
    RequestOptions options,
    int? statusCode, {
    bool isError = false,
    String? errorMessage,
  }) {
    final startedAt = options.extra[_startTimeKey];
    if (startedAt is! int) return;

    // Consumed so a retried request cannot report the original start time.
    options.extra.remove(_startTimeKey);

    final latencyMs =
        (DateTime.now().microsecondsSinceEpoch - startedAt) ~/
        Duration.microsecondsPerMillisecond;

    client.sendMetric(
      event: isError ? MetricsEvent.apiError : MetricsEvent.apiCall,
      screen: _screenContext.currentScreen,
      target: options.path,
      apiLatencyMs: latencyMs,
      isError: isError,
      errorMessage: errorMessage ?? (isError ? 'API Error $statusCode' : null),
    );
  }
}
