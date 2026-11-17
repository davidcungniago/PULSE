import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/services/api_endpoint.dart';

void main() {
  test('web deployment memakai origin HTTPS tanpa path aplikasi', () {
    expect(
      resolveApiEndpoint(
        configuredUrl: '',
        isWeb: true,
        pageUri: Uri.parse('https://pulse.example.com/pulse/#/register'),
      ),
      'https://pulse.example.com',
    );
  });

  test('origin web mempertahankan port deployment', () {
    expect(
      resolveApiEndpoint(
        configuredUrl: '',
        isWeb: true,
        pageUri: Uri.parse('https://pulse.example.com:8443/pulse/'),
      ),
      'https://pulse.example.com:8443',
    );
  });

  test('konfigurasi lokal tetap mengarah ke backend terpisah', () {
    expect(
      resolveApiEndpoint(
        configuredUrl: 'http://127.0.0.1:8000',
        isWeb: true,
        pageUri: Uri.parse('http://localhost:8080/'),
      ),
      'http://127.0.0.1:8000',
    );
  });

  test('native tetap memakai backend lokal tanpa URI browser', () {
    expect(
      resolveApiEndpoint(
        configuredUrl: '',
        isWeb: false,
        pageUri: Uri.parse('file:///app/'),
      ),
      'http://localhost:8000',
    );
  });
}
