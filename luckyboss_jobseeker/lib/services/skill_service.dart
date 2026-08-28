import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';

/// A skill as the taxonomy knows it.
class SkillSuggestion {
  final int id;
  final String name;
  final String? category;

  const SkillSuggestion({required this.id, required this.name, this.category});

  factory SkillSuggestion.fromJson(Map<String, dynamic> j) => SkillSuggestion(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String,
        category: j['category'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is SkillSuggestion && other.name.toLowerCase() == name.toLowerCase();

  @override
  int get hashCode => name.toLowerCase().hashCode;
}

/// Client for the Laravel skill taxonomy.
///
/// Backs the key-skills step: type-ahead, an opening list derived from the
/// candidate's category, and the related-skill graph that makes selecting
/// Flutter surface Dart, Kotlin and React Native.
///
/// Every method fails soft and returns an empty list. A suggestion engine is an
/// accelerator, not a gate — if it is unreachable the candidate can still type
/// their skills and finish onboarding, which is the part that actually matters.
class SkillService {
  SkillService._();

  static const Duration _timeout = Duration(seconds: 10);

  /// In-memory memo. Onboarding asks for the same relations repeatedly as chips
  /// are added and removed, and the answers do not change within a session.
  static final Map<String, List<SkillSuggestion>> _relatedCache = {};

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// Type-ahead for the "Type your skills" field.
  ///
  /// Returns nothing under two characters — the server enforces the same floor,
  /// and a one-letter query would return a near-random slice of the taxonomy.
  static Future<List<SkillSuggestion>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];

    try {
      final uri = Uri.parse('${ApiConfig.v1}/skills/search')
          .replace(queryParameters: {'q': q, 'limit': '20'});
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final parsed = _parse(res.body);
        if (parsed.isNotEmpty) return parsed;
      }
    } catch (_) {
      // Fall through to offline taxonomy
    }

    // Offline taxonomy search
    return _offlineTaxonomy
        .where((s) => s.name.toLowerCase().contains(q.toLowerCase()))
        .take(20)
        .toList();
  }

  /// The opening list, shown before the candidate has picked anything —
  /// "Suggested skills based on your education".
  static Future<List<SkillSuggestion>> suggested({String? category}) async {
    try {
      final uri = Uri.parse('${ApiConfig.v1}/skills/suggested').replace(
        queryParameters: {
          if (category != null && category.isNotEmpty) 'category': category,
          'limit': '14',
        },
      );
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final parsed = _parse(res.body);
        if (parsed.isNotEmpty) return parsed;
      }
    } catch (_) {
      // Fall through to offline taxonomy
    }

    // Offline suggested list
    if (category != null && category.isNotEmpty) {
      final catMatches = _offlineTaxonomy
          .where((s) => s.category?.toLowerCase() == category.toLowerCase())
          .take(14)
          .toList();
      if (catMatches.isNotEmpty) return catMatches;
    }
    return _offlineTaxonomy.take(14).toList();
  }

  /// Skills that co-occur with everything in [selected].
  static Future<List<SkillSuggestion>> related(List<String> selected) async {
    if (selected.isEmpty) return const [];

    final key = (selected.map((s) => s.toLowerCase()).toList()..sort()).join('|');
    final cached = _relatedCache[key];
    if (cached != null) return cached;

    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.v1}/skills/related'),
            headers: _headers,
            body: jsonEncode({'skills': selected, 'limit': 14}),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final parsed = _parse(res.body);
        if (parsed.isNotEmpty) {
          _relatedCache[key] = parsed;
          return parsed;
        }
      }
    } catch (_) {
      // Fall through to offline graph
    }

    // Offline related graph: Find categories of picked skills and suggest adjacent skills
    final pickedLower = selected.map((s) => s.toLowerCase()).toSet();
    final matchingCategories = _offlineTaxonomy
        .where((s) => pickedLower.contains(s.name.toLowerCase()))
        .map((s) => s.category)
        .whereType<String>()
        .toSet();

    final relatedSkills = _offlineTaxonomy
        .where((s) =>
            !pickedLower.contains(s.name.toLowerCase()) &&
            (matchingCategories.isEmpty || matchingCategories.contains(s.category)))
        .take(14)
        .toList();

    _relatedCache[key] = relatedSkills;
    return relatedSkills;
  }

  static List<SkillSuggestion> _parse(String body) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final list = (decoded['data'] as List<dynamic>?) ?? const [];
    return list
        .map((e) => SkillSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static const List<SkillSuggestion> _offlineTaxonomy = [
    // IT & Software
    SkillSuggestion(id: 1, name: 'Flutter', category: 'IT & Software'),
    SkillSuggestion(id: 2, name: 'Dart', category: 'IT & Software'),
    SkillSuggestion(id: 3, name: 'React Native', category: 'IT & Software'),
    SkillSuggestion(id: 4, name: 'Python', category: 'IT & Software'),
    SkillSuggestion(id: 5, name: 'Firebase', category: 'IT & Software'),
    SkillSuggestion(id: 6, name: 'REST APIs', category: 'IT & Software'),
    SkillSuggestion(id: 7, name: 'JavaScript', category: 'IT & Software'),
    SkillSuggestion(id: 8, name: 'TypeScript', category: 'IT & Software'),
    SkillSuggestion(id: 9, name: 'Node.js', category: 'IT & Software'),
    SkillSuggestion(id: 10, name: 'SQL', category: 'IT & Software'),
    SkillSuggestion(id: 11, name: 'Docker', category: 'IT & Software'),
    SkillSuggestion(id: 12, name: 'Kubernetes', category: 'IT & Software'),
    SkillSuggestion(id: 13, name: 'AWS', category: 'IT & Software'),
    SkillSuggestion(id: 14, name: 'Git', category: 'IT & Software'),
    SkillSuggestion(id: 15, name: 'CI/CD', category: 'IT & Software'),
    SkillSuggestion(id: 16, name: 'Kotlin', category: 'IT & Software'),
    SkillSuggestion(id: 17, name: 'Swift', category: 'IT & Software'),
    SkillSuggestion(id: 18, name: 'Java', category: 'IT & Software'),
    SkillSuggestion(id: 19, name: 'UI/UX Design', category: 'IT & Software'),
    SkillSuggestion(id: 20, name: 'Figma', category: 'IT & Software'),

    // Logistics & Warehouse
    SkillSuggestion(id: 21, name: 'Warehouse Operations', category: 'Logistics & Warehouse'),
    SkillSuggestion(id: 22, name: 'Supply Chain', category: 'Logistics & Warehouse'),
    SkillSuggestion(id: 23, name: 'Forklift Operator', category: 'Logistics & Warehouse'),
    SkillSuggestion(id: 24, name: 'Inventory Control', category: 'Logistics & Warehouse'),
    SkillSuggestion(id: 25, name: 'WMS Systems', category: 'Logistics & Warehouse'),
    SkillSuggestion(id: 26, name: 'Site Safety', category: 'Logistics & Warehouse'),
    SkillSuggestion(id: 27, name: 'Fleet Management', category: 'Logistics & Warehouse'),
    SkillSuggestion(id: 28, name: 'Procurement', category: 'Logistics & Warehouse'),

    // Finance & Accounting
    SkillSuggestion(id: 31, name: 'Financial Analysis', category: 'Finance'),
    SkillSuggestion(id: 32, name: 'Accounting', category: 'Finance'),
    SkillSuggestion(id: 33, name: 'QuickBooks', category: 'Finance'),
    SkillSuggestion(id: 34, name: 'Tally Prime', category: 'Finance'),
    SkillSuggestion(id: 35, name: 'Auditing', category: 'Finance'),
    SkillSuggestion(id: 36, name: 'Taxation', category: 'Finance'),
    SkillSuggestion(id: 37, name: 'Excel Advanced', category: 'Finance'),

    // Healthcare
    SkillSuggestion(id: 41, name: 'Patient Care', category: 'Healthcare'),
    SkillSuggestion(id: 42, name: 'Clinical Nursing', category: 'Healthcare'),
    SkillSuggestion(id: 43, name: 'Emergency Response', category: 'Healthcare'),
    SkillSuggestion(id: 44, name: 'BLS Certification', category: 'Healthcare'),

    // Sales & Marketing
    SkillSuggestion(id: 51, name: 'Digital Marketing', category: 'Sales & Marketing'),
    SkillSuggestion(id: 52, name: 'SEO & SEM', category: 'Sales & Marketing'),
    SkillSuggestion(id: 53, name: 'B2B Sales', category: 'Sales & Marketing'),
    SkillSuggestion(id: 54, name: 'Lead Generation', category: 'Sales & Marketing'),
    SkillSuggestion(id: 55, name: 'CRM (Salesforce)', category: 'Sales & Marketing'),
  ];
}
