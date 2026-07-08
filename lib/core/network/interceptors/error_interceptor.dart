import 'package:dio/dio.dart';
import '../../errors/exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        throw NetworkException();
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode;
        final msg = err.response?.data['message'] ?? 'Server error';
        throw ServerException(msg, statusCode: code);
      default:
        throw NetworkException();
    }
  }
}
