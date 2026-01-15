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
            headers: {
              'x-api-key': apiKey,
              'Content-Type': 'application/json',
            },
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );

  void enable() => _enabled = true;
  void disable() => _enabled = false;

  Future<void> sendMetric({
    required String event,
    required String screen,
  }) async {
    if (!_enabled) return;

    if (event.isEmpty || screen.isEmpty) return;

    try {
      await _dio.post(
        '/metrics',
        data: {
          'event': event,
          'screen': screen,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (_) {
      // Silent failure (by design)
    }
  }
}
