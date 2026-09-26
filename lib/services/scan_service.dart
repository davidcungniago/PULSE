import '../models/component_model.dart';
import '../models/drift_event_model.dart';
import '../models/scan_result_model.dart';

class ScanService {
  Future<ScanResult> startScan(String assetId) async => ScanResult(id: 'scan-baru', assetId: assetId, componentCount: 0, criticalVulnerabilityCount: 0, startedAt: DateTime.now(), finishedAt: DateTime.now(), status: 'selesai');
  Future<List<ScanResult>> getScanResults(String assetId) async => [await getLatestScanResult(assetId)];
  Future<ScanResult> getLatestScanResult(String assetId) async { await Future<void>.delayed(const Duration(milliseconds: 400)); return ScanResult(id: 'scan-1', assetId: assetId, componentCount: 48, criticalVulnerabilityCount: 2, startedAt: DateTime.now().subtract(const Duration(hours: 2)), finishedAt: DateTime.now().subtract(const Duration(hours: 2)), status: 'selesai'); }
  Future<List<Component>> getComponents(String assetId) async { await Future<void>.delayed(const Duration(milliseconds: 400)); return const [Component(id: 'component-1', scanResultId: 'scan-1', name: 'lodash', version: '4.17.20', ecosystem: 'npm', purl: 'pkg:npm/lodash@4.17.20', license: 'MIT'), Component(id: 'component-2', scanResultId: 'scan-1', name: 'axios', version: '0.21.1', ecosystem: 'npm', purl: 'pkg:npm/axios@0.21.1', license: 'MIT'), Component(id: 'component-3', scanResultId: 'scan-1', name: 'openssl', version: '1.1.1', ecosystem: 'deb', purl: 'pkg:deb/openssl@1.1.1', license: 'Apache-2.0')]; }
  Future<List<DriftEvent>> getDriftEvents(String assetId) async => [DriftEvent(id: 'drift-1', assetId: assetId, type: DriftEventType.added, componentName: 'axios', details: 'Komponen baru ditemukan.', detectedAt: DateTime.now().subtract(const Duration(hours: 2))), DriftEvent(id: 'drift-2', assetId: assetId, type: DriftEventType.changed, componentName: 'lodash', details: 'Versi berubah dari 4.17.19 ke 4.17.20.', detectedAt: DateTime.now().subtract(const Duration(hours: 2)))];
}
