import 'package:dio/dio.dart';

class MetricsClient {
  final Dio _dio;
  bool _enabled = true;

  MetricsClient({
    required String apiKey,
    required String baseUrl,
    bool enabled = true,
  }) : _enabled = enabled,
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
  }) async {
    if (!_enabled) return;

    if (event.isEmpty || screen.isEmpty) return;

    try {
      final future = await _dio.post(
        '/metrics',
        data: {
          'event': event,
          'screen': screen,
          // 'timestamp': DateTime.now().toIso8601String(),
          // if (frameTimeMs != null) 'frame_time': frameTimeMs,
          // if (frameDropped != null) 'frame_dropped': frameDropped,
          // if (renderTimeMs != null) 'render_time': renderTimeMs,
        },
      );
      print(future);
    } catch (e) {
      print(e);
      // Silent failure (by design)
    }
  }
}
