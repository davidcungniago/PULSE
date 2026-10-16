import 'package:dio/dio.dart';

String mapApiErrorToMessage(DioException error) {
  final data = error.response?.data;
  if (data is Map && data['Message'] is String) {
    final message = (data['Message'] as String).trim();
    if (message.isNotEmpty) return message;
  }

  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout =>
      'Koneksi ke server habis waktu. Silakan coba lagi.',
    DioExceptionType.connectionError ||
    DioExceptionType.unknown =>
      'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
    DioExceptionType.badResponse =>
      'Server mengembalikan respons yang tidak terduga.',
    DioExceptionType.cancel => 'Permintaan dibatalkan.',
    DioExceptionType.badCertificate => 'Sertifikat server tidak valid.',
  };
}
