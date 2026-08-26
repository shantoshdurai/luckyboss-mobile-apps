import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/job_model.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

  /// Fetch live jobs from the Laravel API backend with graceful fallback
  static Future<List<JobModel>?> fetchLiveJobs({String? country, String? keyword}) async {
    try {
      final uri = Uri.parse('$baseUrl/jobs').replace(queryParameters: {
        if (country != null && country.isNotEmpty) 'country': country,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> jobsList = data['data'] ?? [];

        if (jobsList.isNotEmpty) {
          return jobsList.map((j) {
            final salary = j['salary'] as Map<String, dynamic>?;
            return JobModel(
              id: 'job-${j['id']}',
              title: j['title'] ?? 'Open Role',
              companyName: j['company'] ?? 'Lucky Boss Enterprise',
              countryCode: j['country'] ?? 'SG',
              location: j['location'] ?? 'Singapore',
              workMode: j['work_mode'] ?? 'On-site',
              minSalary: salary != null ? '${salary['min'] ?? '3,000'}' : '3,000',
              maxSalary: salary != null ? '${salary['max'] ?? '5,000'}' : '5,000',
              currency: salary != null ? (salary['currency'] ?? 'SGD') : 'SGD',
              category: 'IT & Software',
              description: 'Position verified and published via Lucky Boss Corporate Recruitment Portal.',
              requiredSkills: ['Problem Solving', 'Communication', 'Industry Experience'],
              postedDate: DateTime.now(),
            );
          }).toList();
        }
      }
    } catch (_) {
      // Graceful fallback to offline/cached dataset
    }
    return null;
  }
}
