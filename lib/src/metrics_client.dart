import 'package:dio/dio.dart';

class MetricsClient {
  final Dio _dio;

  MetricsClient({
    required String apiKey,
    required String baseUrl,
  }) : _dio = Dio(
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

  /// Sends a metric safely.
  /// This method MUST NEVER throw.
  Future<void> sendMetric({
    required String event,
    required String screen,
  }) async {
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
      // Silent failure by design
    }
  }
}
