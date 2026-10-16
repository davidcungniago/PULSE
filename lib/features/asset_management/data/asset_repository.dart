import '../../../models/asset_model.dart';
import '../../../services/asset_service.dart';

class AssetRepository {
  AssetRepository({required AssetService assetService})
      : _assetService = assetService;

  final AssetService _assetService;

  Future<List<Asset>> getAssets(String projectId) =>
      _assetService.getAssets(projectId);

  Future<Asset> addAsset(String projectId, String repositoryUrl) =>
      _assetService.createAsset(projectId, repositoryUrl: repositoryUrl);
}
