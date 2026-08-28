import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../core/constants/app_data.dart';
import '../models/candidate.dart';
import '../models/employer_job.dart';

/// What the assistant answered, and where the answer came from.
///
/// Three sources, and the UI shows which — because "the model said so", "your
/// own data says so" and "I could not reach the model" are three different
/// levels of trust and flattening them is how an assistant starts lying.
enum ReplySource {
  /// A real model reply from the Laravel endpoint.
  model,

  /// Computed from this company's own jobs and the candidate pool on the
  /// device. Not AI, and labelled as such.
  localData,

  /// Nothing to answer with.
  unavailable,
}

class CopilotReply {
  final String text;
  final ReplySource source;

  const CopilotReply(this.text, this.source);

  bool get isLive => source != ReplySource.unavailable;
}

/// The hiring assistant.
///
/// Deliberately different from the candidate copilot's offline behaviour, which
/// is worth explaining because it was a bug there. That one, when it could not
/// reach the server, returned hardcoded salary bands — "Singapore SGD 3,500 –
/// 5,500" — with `isLive: true`, so invented figures arrived looking exactly
/// like a model's answer. Its own docstring says "no fabricated fallback"
/// directly above the fabrication.
///
/// This never invents a number. When the endpoint is unreachable it answers
/// from data actually on the handset: how many candidates match a trade in a
/// market, what the posted vacancies in that trade pay, which licences the pool
/// holds. That is genuinely useful to a recruiter and every figure is real —
/// and [ReplySource.localData] tells the UI to say where it came from.
class EmployerCopilotService {
  EmployerCopilotService._();

  static Future<CopilotReply> ask(
    String message, {
    required List<Candidate> pool,
    required List<EmployerJobModel> jobs,
  }) async {
    final query = message.trim();
    if (query.isEmpty) {
      return const CopilotReply(
        'Ask me about pay rates, who we have available, or what a job should '
        'require.',
        ReplySource.model,
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.aiChat),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'message': query, 'role': 'employer'}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final reply = (data['reply'] as String?)?.trim();
        if (reply != null && reply.isNotEmpty) {
          return CopilotReply(reply, ReplySource.model);
        }
      }
    } catch (_) {
      // Fall through to the local answer. A recruiter does not care why the
      // server is unreachable, only whether the app can still help.
    }

    return _fromLocalData(query, pool: pool, jobs: jobs);
  }

  /// Answers from the data on this device. Every number here is counted, not
  /// guessed.
  static CopilotReply _fromLocalData(
    String query, {
    required List<Candidate> pool,
    required List<EmployerJobModel> jobs,
  }) {
    final q = query.toLowerCase();

    // Which trade and market are being asked about, if any. Matching against
    // the real taxonomy rather than keywords means "how many masons in chennai"
    // and "mason chennai" both land.
    final role = _mentionedRole(q, pool);
    final country = _mentionedCountry(q);

    if (role != null) {
      final matches = pool.where((c) =>
          c.role.toLowerCase() == role.toLowerCase() &&
          (country == null || c.countryCode == country));

      if (matches.isEmpty) {
        return CopilotReply(
          'No $role in the Lucky Boss database'
          '${country == null ? '' : ' in ${_countryName(country)}'} right now.\n\n'
          'Post the vacancy anyway — candidates register every day and we will '
          'match new ones to it automatically.',
          ReplySource.localData,
        );
      }

      final withLicence =
          matches.where((c) => c.certificates.isNotEmpty).length;
      final available = matches
          .where((c) => c.availability == 'Immediately')
          .length;
      final experienced =
          matches.where((c) => c.yearsExperience >= 3).length;
      final languages = <String>{for (final c in matches) ...c.languages};

      return CopilotReply(
        'From your Lucky Boss data:\n\n'
        '• ${matches.length} ${role.toLowerCase()}'
        '${matches.length == 1 ? '' : 's'}'
        '${country == null ? ' across all three markets' : ' in ${_countryName(country)}'}\n'
        '• $experienced with 3+ years\n'
        '• $withLicence holding a licence or card\n'
        '• $available available immediately\n'
        '${languages.isEmpty ? '' : '• Languages spoken: ${languages.take(6).join(', ')}\n'}'
        '\n${_payLine(role, country, jobs)}',
        ReplySource.localData,
      );
    }

    if (q.contains('pay') ||
        q.contains('salary') ||
        q.contains('rate') ||
        q.contains('wage')) {
      if (jobs.isEmpty) {
        return const CopilotReply(
          'I can compare pay once you have posted a vacancy — I work from your '
          'own postings and the candidates matched to them, so the figures are '
          'real rather than a guess.',
          ReplySource.localData,
        );
      }
      return CopilotReply(
        'What your open vacancies pay:\n\n'
        '${jobs.take(6).map((j) => '• ${j.title} — ${j.salaryDisplay} (${j.location})').join('\n')}',
        ReplySource.localData,
      );
    }

    if (q.contains('licence') ||
        q.contains('license') ||
        q.contains('certificate')) {
      final held = <String, int>{};
      for (final c in pool) {
        for (final cert in c.certificates) {
          held[cert] = (held[cert] ?? 0) + 1;
        }
      }
      final top = held.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (top.isEmpty) {
        return const CopilotReply(
          'No licences recorded in the database yet.',
          ReplySource.localData,
        );
      }
      return CopilotReply(
        'Licences held across the Lucky Boss database:\n\n'
        '${top.take(8).map((e) => '• ${e.key} — ${e.value} candidates').join('\n')}\n\n'
        'Requiring one on a vacancy narrows who we can send you, so only tick '
        'what the job genuinely needs.',
        ReplySource.localData,
      );
    }

    // Nothing specific asked. Say what this can do rather than padding.
    return CopilotReply(
      'Lucky AI cannot reach the server, so I am answering from your own data '
      'instead — I will not guess at figures.\n\n'
      'I can tell you:\n'
      '• How many of a trade we have, and where\n'
      '• What your open vacancies pay\n'
      '• Which licences candidates actually hold\n\n'
      'Try "how many forklift drivers in Malaysia" or "what do my jobs pay".',
      ReplySource.localData,
    );
  }

  /// The pay range across the pool's own market for this trade, from real
  /// postings. Returns a prompt to post rather than an invented band when
  /// there is nothing to compare against.
  static String _payLine(
      String role, String? country, List<EmployerJobModel> jobs) {
    final comparable = jobs.where((j) =>
        j.role.toLowerCase() == role.toLowerCase() &&
        (country == null || j.countryCode == country));
    if (comparable.isEmpty) {
      return 'You have no $role vacancy posted yet, so I have nothing of yours '
          'to compare pay against.';
    }
    return 'Your ${role.toLowerCase()} postings: '
        '${comparable.map((j) => j.salaryDisplay).join(', ')}.';
  }

  /// The trade being asked about, matched against the whole taxonomy.
  ///
  /// Deliberately not against the pool. Matching only roles that already have
  /// somebody in the database meant asking about a trade with nobody in it fell
  /// through to a generic "here is what I can do" — so the one question with a
  /// genuinely useful answer ("we have none, post it anyway and we will match
  /// new registrations") was the one question it could not answer.
  static String? _mentionedRole(String q, List<Candidate> pool) {
    String? best;

    void consider(String role) {
      if (role.isEmpty) return;
      final lower = role.toLowerCase();
      // Plurals too — nobody types "how many mason".
      if (!q.contains(lower) && !q.contains('${lower}s')) return;
      // Longest match wins, so "site supervisor" does not resolve to
      // "supervisor" from another trade.
      if (best == null || role.length > best!.length) best = role;
    }

    for (final role in AppData.allRoleTitles) {
      consider(role);
    }
    // Anything in the pool that is not in the taxonomy — a typed-in trade.
    for (final candidate in pool) {
      consider(candidate.role);
    }
    return best;
  }

  static String? _mentionedCountry(String q) {
    if (q.contains('singapore') || q.contains(' sg')) return 'SG';
    if (q.contains('malaysia') || q.contains(' my ')) return 'MY';
    if (q.contains('india') || q.contains(' in ') && q.contains('chennai')) {
      return 'IN';
    }
    for (final city in ['chennai', 'bengaluru', 'mumbai', 'delhi', 'pune']) {
      if (q.contains(city)) return 'IN';
    }
    for (final city in ['jurong', 'woodlands', 'tampines', 'changi']) {
      if (q.contains(city)) return 'SG';
    }
    for (final city in ['kuala lumpur', 'johor', 'penang', 'klang', 'ipoh']) {
      if (q.contains(city)) return 'MY';
    }
    return null;
  }

  static String _countryName(String code) => switch (code) {
        'SG' => 'Singapore',
        'MY' => 'Malaysia',
        'IN' => 'India',
        _ => code,
      };
}
