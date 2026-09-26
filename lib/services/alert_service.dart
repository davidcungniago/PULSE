import '../models/alert_log_model.dart';

class AlertService {
  Future<List<AlertLog>> getAlerts(String projectId) async { await Future<void>.delayed(const Duration(milliseconds: 400)); return [AlertLog(id: 'alert-1', projectId: projectId, type: 'CVE Kritis', message: '2 kerentanan kritis ditemukan pada API Utama.', sentAt: DateTime.now().subtract(const Duration(hours: 2))), AlertLog(id: 'alert-2', projectId: projectId, type: 'Perubahan dependensi', message: 'Perubahan komponen terdeteksi pada Aplikasi Web.', sentAt: DateTime.now().subtract(const Duration(days: 1)))]; }
}
