import 'package:dio/dio.dart';

class MetricsClient {
  final Dio _dio;
  bool _enabled = true;

  MetricsClient({
    required String apiKey,
    required String baseUrl,
    bool enabled = true,
  })  : _enabled = enabled,
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            headers: {'x-api-key': apiKey, 'Content-Type': 'application/json'},
            //  connectTimeout: const Duration(seconds: 15),
            //  receiveTimeout: const Duration(seconds: 15),
          ),
        );

  void enable() => _enabled = true;
  void disable() => _enabled = false;

  Future<void> sendMetric({
    required String event,
    required String screen,
    int? frameTimeMs,
    bool? frameDropped,
    int? renderTimeMs,
    int? apiLatencyMs,
    bool? isError,
    String? errorMessage,
    String? stackTrace,
    int? screenLoadTimeMs,
  }) async {
    if (!_enabled) return;

    if (event.isEmpty || screen.isEmpty) return;

    try {
      await _dio.post(
        '/metrics',
        data: {
          'event': event,
          'screen': screen,
          if (frameTimeMs != null) 'frame_time': frameTimeMs,
          if (frameDropped != null) 'frame_dropped': frameDropped,
          if (renderTimeMs != null) 'render_time': renderTimeMs,
          if (apiLatencyMs != null) 'api_latency': apiLatencyMs,
          if (isError != null) 'is_error': isError,
          if (errorMessage != null) 'error_message': errorMessage,
          if (stackTrace != null) 'stack_trace': stackTrace,
          if (screenLoadTimeMs != null) 'screen_load_time': screenLoadTimeMs,
        },
      );
    } catch (e) {
      // Silent failure (by design)
    }
  }
}
