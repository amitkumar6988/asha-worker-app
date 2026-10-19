import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/backend_models.dart';

class OfflineStorageService {
  static const String _keyPatientQueue = 'offline_patient_queue';
  static const String _keyWaterQueue = 'offline_water_queue';
  static const String _keyBulkQueue = 'offline_bulk_queue';

  static Future<void> savePatient(PatientPayload payload) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyPatientQueue) ?? [];
    list.add(jsonEncode(payload.toJson()));
    await prefs.setStringList(_keyPatientQueue, list);
  }

  static Future<List<PatientPayload>> getPatients() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyPatientQueue) ?? [];
    return list.map((s) => PatientPayload.fromJson(jsonDecode(s))).toList();
  }

  static Future<void> clearPatients() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPatientQueue);
  }

  static Future<void> saveWater(WaterQualityPayload payload) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyWaterQueue) ?? [];
    list.add(jsonEncode(payload.toJson()));
    await prefs.setStringList(_keyWaterQueue, list);
  }

  static Future<List<WaterQualityPayload>> getWaterReports() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyWaterQueue) ?? [];
    return list.map((s) => WaterQualityPayload.fromJson(jsonDecode(s))).toList();
  }

  static Future<void> clearWater() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyWaterQueue);
  }

  static Future<void> saveBulk(BulkPatientBatchPayload payload) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyBulkQueue) ?? [];
    list.add(jsonEncode(payload.toJson()));
    await prefs.setStringList(_keyBulkQueue, list);
  }

  static Future<List<BulkPatientBatchPayload>> getBulkReports() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyBulkQueue) ?? [];
    return list.map((s) {
      final json = jsonDecode(s);
      final patientsJson = (json['patients'] as List).map((p) => PatientBatchItem.fromJson(p)).toList();
      return BulkPatientBatchPayload(
        villageId: json['village_id'] ?? 1,
        diagnosis: json['diagnosis'] ?? '',
        severity: json['severity'] ?? 'Moderate',
        notes: json['notes'],
        patients: patientsJson,
      );
    }).toList();
  }

  static Future<void> clearBulk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBulkQueue);
  }

  static Future<int> getPendingCount() async {
    final p = await getPatients();
    final w = await getWaterReports();
    final b = await getBulkReports();
    return p.length + w.length + b.length;
  }
}
