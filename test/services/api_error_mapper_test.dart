import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/services/api_error_mapper.dart';

DioException _exception(DioExceptionType type, {Response<dynamic>? response}) =>
    DioException(
        requestOptions: RequestOptions(path: '/'),
        type: type,
        response: response);

void main() {
  test('memprioritaskan pesan Message dari server', () {
    final error = _exception(
      DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/'),
        statusCode: 409,
        data: {'Message': 'URL repositori ini sudah ada di project ini.'},
      ),
    );
    expect(mapApiErrorToMessage(error),
        'URL repositori ini sudah ada di project ini.');
  });

  test('memakai pesan koneksi saat tidak dapat terhubung', () {
    expect(mapApiErrorToMessage(_exception(DioExceptionType.connectionError)),
        'Tidak dapat terhubung ke server. Periksa koneksi Anda.');
  });

  test('memakai pesan koneksi saat unknown', () {
    expect(mapApiErrorToMessage(_exception(DioExceptionType.unknown)),
        'Tidak dapat terhubung ke server. Periksa koneksi Anda.');
  });

  test('memakai pesan timeout saat koneksi habis waktu', () {
    expect(mapApiErrorToMessage(_exception(DioExceptionType.connectionTimeout)),
        'Koneksi ke server habis waktu. Silakan coba lagi.');
  });

  test('memakai pesan respons tidak terduga saat badResponse tanpa Message',
      () {
    final error = _exception(
      DioExceptionType.badResponse,
      response:
          Response(requestOptions: RequestOptions(path: '/'), statusCode: 500),
    );
    expect(mapApiErrorToMessage(error),
        'Server mengembalikan respons yang tidak terduga.');
  });
}
