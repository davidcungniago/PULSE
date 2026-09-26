import '../../../models/asset_model.dart';
import '../../../services/asset_service.dart';

class AssetRepository {
  AssetRepository({AssetService? assetService}) : _assetService = assetService ?? AssetService();

  final AssetService _assetService;

  Future<List<Asset>> getAssets(String projectId) => _assetService.getAssets(projectId);

  Future<Asset> addAsset(String projectId, String repositoryUrl) {
    final uri = Uri.parse(repositoryUrl);
    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    final repositoryName = segments.last.replaceFirst(RegExp(r'\.git$'), '');
    return _assetService.createAsset(projectId, name: repositoryName, repositoryUrl: repositoryUrl);
  }
}
