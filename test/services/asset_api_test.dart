import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/asset_management/data/asset_repository.dart';
import 'package:pulse/models/asset_model.dart';
import 'package:pulse/services/api_client.dart';
import 'package:pulse/services/asset_service.dart';

const assetJson = {
  'Id': 'asset-1',
  'ProjectId': 'project-1',
  'Name': 'api',
  'RepositoryUrl': 'https://github.com/pulse/api',
  'Owner': 'pulse',
  'RepositoryName': 'api',
  'IsActive': true,
  'LastScannedAt': null,
};

class FixtureAdapter implements HttpClientAdapter {
  FixtureAdapter(this.body, {this.status = 200});
  final String body;
  final int status;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    request = options;
    return ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

AssetRepository repository(FixtureAdapter adapter) {
  final client = ApiClient();
  client.dio.httpClientAdapter = adapter;
  return AssetRepository(assetService: AssetService(client: client));
}

void main() {
  test('model valid mempertahankan kontrak PascalCase', () {
    final asset = Asset.fromJson(assetJson);
    expect(asset.owner, 'pulse');
    expect(asset.toJson(), assetJson);
  });

  test('model invalid menolak tipe field yang salah', () {
    expect(() => Asset.fromJson({...assetJson, 'IsActive': 'true'}),
        throwsA(isA<TypeError>()));
    expect(() => Asset.fromJson({}), throwsA(isA<TypeError>()));
  });

  test('API sukses mengirim URL dan mengembalikan model aset', () async {
    final adapter = FixtureAdapter(
      '{"Id":"a","ProjectId":"p","Name":"api","RepositoryUrl":"https://github.com/pulse/api","Owner":"pulse","RepositoryName":"api","IsActive":true}',
      status: 201,
    );
    final asset =
        await repository(adapter).addAsset('p', 'https://github.com/pulse/api');
    expect(asset.id, 'a');
    expect(adapter.request!.method, 'POST');
    expect(adapter.request!.path, '/api/projects/p/assets');
    expect(adapter.request!.data,
        {'RepositoryUrl': 'https://github.com/pulse/api'});
  });

  test('data kosong menghasilkan daftar kosong', () async {
    expect(await repository(FixtureAdapter('[]')).getAssets('p'), isEmpty);
  });

  test('HTTP gagal mempertahankan status dan pesan server', () async {
    await expectLater(
      repository(FixtureAdapter('{"Message":"Server tidak tersedia."}',
              status: 503))
          .getAssets('p'),
      throwsA(isA<DioException>()
          .having((e) => e.response?.statusCode, 'status', 503)),
    );
  });

  test('JSON rusak ditolak dan bukan dianggap daftar kosong', () async {
    await expectLater(repository(FixtureAdapter('[{rusak')).getAssets('p'),
        throwsA(isA<DioException>()));
  });

  test('respons null bukan daftar kosong yang sah', () async {
    await expectLater(repository(FixtureAdapter('null')).getAssets('p'),
        throwsA(isA<FormatException>()));
  });
}
