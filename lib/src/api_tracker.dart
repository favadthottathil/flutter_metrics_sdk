import 'package:dio/dio.dart';
import 'metrics_client.dart';
import 'metrics_event.dart';

/// A Dio [Interceptor] that measures the latency of every request made
/// through the interceptor's [Dio] instance and reports it as either an
/// [MetricsEvent.apiCall] or [MetricsEvent.apiError] event.
///
/// Add it to a [Dio] client's interceptors:
///
/// ```dart
/// dio.interceptors.add(ApiMetricsInterceptor(metrics));
/// ```
class ApiMetricsInterceptor extends Interceptor {
  final MetricsClient client;
  final Map<RequestOptions, DateTime> _startTimes = {};

  /// Safety cap on the number of in-flight requests tracked at once.
  /// Prevents unbounded growth if a request never reaches [onResponse]
  /// or [onError] (e.g. it is dropped without completing).
  static const int _maxTrackedRequests = 200;

  ApiMetricsInterceptor(this.client);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_startTimes.length >= _maxTrackedRequests) {
      _startTimes.remove(_startTimes.keys.first);
    }
    _startTimes[options] = DateTime.now();
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
    final startTime = _startTimes.remove(options);
    if (startTime == null) return;

    final latencyMs = DateTime.now().difference(startTime).inMilliseconds;

    client.sendMetric(
      event: isError ? MetricsEvent.apiError : MetricsEvent.apiCall,
      screen: options.path, // Using path as the target for API requests
      apiLatencyMs: latencyMs,
      isError: isError,
      errorMessage: errorMessage ?? (isError ? 'API Error $statusCode' : null),
    );
  }
}
