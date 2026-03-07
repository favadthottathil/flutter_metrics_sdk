import 'package:dio/dio.dart';
import 'metrics_client.dart';
import 'metrics_event.dart';

class ApiMetricsInterceptor extends Interceptor {
  final MetricsClient client;
  final Map<RequestOptions, DateTime> _startTimes = {};

  ApiMetricsInterceptor(this.client);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
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
