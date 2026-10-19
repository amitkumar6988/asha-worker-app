import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_storage_service.dart';
import 'api_service.dart';
import '../models/backend_models.dart';

class SyncService {
  static Future<bool> isConnected() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      return !connectivityResults.contains(ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  static Future<Map<String, dynamic>> syncAllPending() async {
    final online = await isConnected();
    if (!online) {
      return {'success': false, 'message': 'No internet connection. Data remains securely cached offline.'};
    }

    try {
      final patients = await OfflineStorageService.getPatients();
      final water = await OfflineStorageService.getWaterReports();
      final bulk = await OfflineStorageService.getBulkReports();

      int synced = 0;

      for (var p in patients) {
        final success = await ApiService.submitPatientReport(p);
        if (success) synced++;
      }
      if (patients.isNotEmpty) await OfflineStorageService.clearPatients();

      for (var w in water) {
        final success = await ApiService.submitWaterReport(w);
        if (success) synced++;
      }
      if (water.isNotEmpty) await OfflineStorageService.clearWater();

      for (var b in bulk) {
        bool allSuccess = true;
        for (var item in b.patients) {
          final p = PatientPayload(
            villageId: b.villageId,
            name: item.name,
            age: item.age,
            gender: item.gender,
            contactNumber: item.contactNumber,
            diagnosis: b.diagnosis,
            severity: b.severity,
            notes: b.notes,
          );
          final res = await ApiService.submitPatientReport(p);
          if (!res) allSuccess = false;
        }
        if (allSuccess) synced++;
      }
      if (bulk.isNotEmpty) await OfflineStorageService.clearBulk();

      return {'success': true, 'message': 'Successfully synced $synced pending batch/item(s) to FastAPI backend!'};
    } catch (e) {
      return {'success': false, 'message': 'Sync error: $e'};
    }
  }
}
