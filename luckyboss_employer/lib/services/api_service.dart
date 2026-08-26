import 'dart:convert';
import 'package:http/http.dart' as http;

class EmployerApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

  /// Sync newly published job to the Laravel Backend
  static Future<bool> postJobToBackend({
    required String title,
    required String category,
    required String location,
    required String minSalary,
    required String maxSalary,
    required String currency,
    required String countryCode,
    required String workMode,
    required String description,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/jobs');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'title': title,
          'category': category,
          'location': location,
          'salary_min': minSalary,
          'salary_max': maxSalary,
          'currency_code': currency,
          'country_code': countryCode,
          'work_mode': workMode,
          'description': description,
        }),
      ).timeout(const Duration(seconds: 3));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      // Local state is always updated in Flutter provider
      return false;
    }
  }
}
