import '../models/asset_model.dart';

class AssetService {
  Future<List<Asset>> getAssets(String projectId) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return [Asset(id: 'asset-1', projectId: projectId, name: 'API Utama', repositoryUrl: 'https://github.com/pulse/api', owner: 'pulse', repositoryName: 'api', isActive: true, lastScannedAt: DateTime.now().subtract(const Duration(hours: 2))), Asset(id: 'asset-2', projectId: projectId, name: 'Aplikasi Web', repositoryUrl: 'https://github.com/pulse/web', owner: 'pulse', repositoryName: 'web', isActive: true, lastScannedAt: DateTime.now().subtract(const Duration(days: 1)))];
  }
  Future<Asset> createAsset(String projectId, {required String name, required String repositoryUrl}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final segments = Uri.parse(repositoryUrl).pathSegments.where((segment) => segment.isNotEmpty).toList();
    final owner = segments[segments.length - 2];
    final repositoryName = segments.last.replaceFirst(RegExp(r'\.git$'), '');
    return Asset(id: 'asset-baru', projectId: projectId, name: name, repositoryUrl: repositoryUrl, owner: owner, repositoryName: repositoryName, isActive: true);
  }
  Future<Asset> updateAsset(String id, Asset asset) async => asset;
  Future<void> deleteAsset(String id) async => Future<void>.delayed(const Duration(milliseconds: 300));
}
