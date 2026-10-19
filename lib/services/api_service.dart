// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'shared_prefs_helper.dart';
import '../models/backend_models.dart';

class ApiService {
  // FastAPI backend base URL
  static const String baseUrl = 'https://community-health-monitoring.onrender.com';

  // Login against FastAPI backend POST /auth/login (No trailing slash in backend)
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        final villageId = data['village_id'] ?? 1;
        final name = data['name'] ?? 'ASHA Worker';
        await SharedPrefsHelper.saveToken(token);
        await SharedPrefsHelper.saveUserEmail(email);
        await SharedPrefsHelper.saveVillageId(villageId);
        await SharedPrefsHelper.saveUserName(name);
        return {'success': true, 'token': token};
      } else {
        final errorData = jsonDecode(response.body);
        return {'success': false, 'message': errorData['detail'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e. Operating in offline cache mode.'};
    }
  }

  // Get Single Village GET /villages/{villageId}
  static Future<Map<String, dynamic>?> getVillageById(int villageId) async {
    try {
      final token = await SharedPrefsHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/villages/$villageId'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // Get Villages GET /villages/
  static Future<List<Map<String, dynamic>>> getVillages() async {
    try {
      final token = await SharedPrefsHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/villages/'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (_) {}
    return [];
  }

  // Get Water Sources by Village GET /water-sources/village/{villageId}
  static Future<List<Map<String, dynamic>>> getWaterSourcesByVillage(int villageId) async {
    try {
      final token = await SharedPrefsHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/water-sources/village/$villageId'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (_) {}
    return [];
  }

  // Create Water Source POST /water-sources/
  static Future<int?> createWaterSource({
    required int villageId,
    required String name,
    required String sourceType,
    String? location,
    required String status,
  }) async {
    try {
      final token = await SharedPrefsHelper.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/water-sources/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'village_id': villageId,
          'name': name,
          'source_type': sourceType,
          'location': location,
          'status': status,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'];
      }
    } catch (_) {}
    return null;
  }

  // Submit Patient to FastAPI backend POST /patients/ (Has trailing slash in backend)
  static Future<bool> submitPatientReport(PatientPayload payload) async {
    try {
      final token = await SharedPrefsHelper.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/patients/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Submit Water Quality Report to FastAPI backend POST /water-quality-reports/ (Has trailing slash in backend)
  static Future<bool> submitWaterReport(WaterQualityPayload payload) async {
    try {
      final token = await SharedPrefsHelper.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/water-quality-reports/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
