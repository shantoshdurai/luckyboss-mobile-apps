import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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
      if (res.statusCode != 200) return const [];
      return _parse(res.body);
    } catch (e) {
      debugPrint('[SkillService] search failed: $e');
      return const [];
    }
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
      if (res.statusCode != 200) return const [];
      return _parse(res.body);
    } catch (e) {
      debugPrint('[SkillService] suggested failed: $e');
      return const [];
    }
  }

  /// Skills that co-occur with everything in [selected].
  ///
  /// The server excludes the selections, so what comes back is always safe to
  /// render as addable chips.
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

      if (res.statusCode != 200) return const [];

      final parsed = _parse(res.body);
      _relatedCache[key] = parsed;
      return parsed;
    } catch (e) {
      debugPrint('[SkillService] related failed: $e');
      return const [];
    }
  }

  static List<SkillSuggestion> _parse(String body) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final list = (decoded['data'] as List<dynamic>?) ?? const [];
    return list
        .map((e) => SkillSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
