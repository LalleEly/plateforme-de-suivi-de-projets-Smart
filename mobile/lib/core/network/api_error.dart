import 'package:dio/dio.dart';

/// Extrait un message d'erreur lisible depuis une exception API.
/// Si le backend a renvoyé { "message": "..." } (voir GlobalExceptionHandler),
/// ce message est utilisé ; sinon [fallback] est retourné.
String apiErrorMessage(Object error, {required String fallback}) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
  }
  return fallback;
}
