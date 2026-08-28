import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../core/constants/app_data.dart';
import '../models/job_model.dart';
import 'job_catalog_service.dart';

/// LUCKY AI COPILOT
///
/// This used to be a keyword `if/else` behind a fake `Future.delayed`, returning
/// hardcoded salary figures as though a model had produced them. It now calls
/// the real Laravel endpoint, which is `POST /api/ai-chat` — that route exists
/// and is wired to `AiChatController`, which runs Gemini when a key is
/// configured and a pure-PHP heuristic engine when it is not.
///
/// The important change is not that it calls an API. It is that when the call
/// fails, this says so instead of inventing an answer. A career assistant that
/// fabricates salary bands when the backend is down is worse than one that is
/// honestly unavailable.
class CopilotResult {
  final String reply;
  final bool isLive;

  /// Why the assistant is unavailable, when it is. Null when `isLive`.
  final String? unavailableReason;

  const CopilotResult({
    required this.reply,
    required this.isLive,
    this.unavailableReason,
  });
}

class GeminiCopilotService {
  /// The chat route is registered at the API root, not under /v1 — see
  /// routes/api.php: Route::post('/ai-chat', AiChatController::class).
  static String get _chatUrl => ApiConfig.aiChat;

  static Future<CopilotResult> ask(String userMessage) async {
    final message = userMessage.trim();
    if (message.isEmpty) {
      return const CopilotResult(
        reply: 'Ask me about roles, salary ranges, or how to strengthen your profile.',
        isLive: true,
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse(_chatUrl),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'message': message}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final reply = (data['reply'] as String?)?.trim();
        if (reply != null && reply.isNotEmpty) {
          return CopilotResult(reply: reply, isLive: true);
        }
      }

      // Every non-200, and an empty 200, falls through to the catalogue the
      // same way a dropped connection does.
      //
      // They used to be treated differently, and the difference was invisible
      // and wrong: a server answering 500 left the candidate with a bare
      // "unavailable" while a server that was simply unreachable got a useful
      // answer from the bundled vacancies. From where the candidate sits those
      // are the same event.
      return _fromCatalogue(message);
    } catch (_) {
      return _fromCatalogue(message);
    }
  }

  /// Answers from the bundled job catalogue when the server cannot be reached.
  ///
  /// This replaces three blocks of hardcoded salary bands — "Singapore SGD
  /// 3,500 – 5,500", "India INR 8 LPA – 15 LPA" — that were returned with
  /// `isLive: true`, so invented figures reached the candidate looking exactly
  /// like a model's answer. They sat directly below a comment promising "no
  /// fabricated fallback".
  ///
  /// That is not a cosmetic problem. A candidate deciding whether to leave a
  /// job, or what to ask an employer for, was being given numbers nobody had
  /// checked, dressed as advice. Everything below is either counted from the
  /// 168 real vacancies in `assets/data/seed_jobs.json` or is not said at all,
  /// and the result is marked `isLive: false` so the UI renders it as what it
  /// is rather than as an answer.
  static Future<CopilotResult> _fromCatalogue(String message) async {
    final query = message.toLowerCase();
    final jobs = await JobCatalogService.loadSeed();
    if (jobs.isEmpty) {
      return _unavailable('No connection, and no local catalogue to read.');
    }

    // The category being asked about, matched against the real taxonomy.
    WorkCategory? category;
    for (final c in AppData.workCategories) {
      if (query.contains(c.name.toLowerCase().split(' ').first)) {
        category = c;
        break;
      }
    }
    // Or the trade, which is how a field candidate would ask.
    String? role;
    for (final title in AppData.allRoleTitles) {
      final lower = title.toLowerCase();
      if (query.contains(lower) || query.contains('${lower}s')) {
        role = title;
        break;
      }
    }

    final matching = jobs.where((j) =>
        (role != null && j.role.toLowerCase() == role.toLowerCase()) ||
        (role == null && category != null && j.category == category.name));

    if (matching.isNotEmpty) {
      final sample = matching.take(4);
      final subject = role ?? category!.name;
      return CopilotResult(
        reply: 'I cannot reach Lucky AI, so this is from the vacancies already '
            'on your phone rather than a live answer.\n\n'
            '$subject openings (${matching.length} in total):\n'
            '${sample.map((j) => '• ${j.title} — ${j.currency} ${j.minSalary}'
                '${j.maxSalary.isEmpty ? '' : ' – ${j.maxSalary}'} '
                '${j.payPeriod.toLowerCase().replaceAll('per ', 'a ')} '
                '(${j.location})').join('\n')}'
            '${_licenceNote(matching)}',
        isLive: false,
        unavailableReason: 'Answered from the bundled catalogue, not the model.',
      );
    }

    return _unavailable(
        'No connection, and nothing in your saved jobs matches that.');
  }

  /// What the matching vacancies actually require, when they agree on it.
  /// Genuinely useful and entirely counted — a candidate learns that four of
  /// four postings want the same ticket.
  static String _licenceNote(Iterable<JobModel> matching) {
    final counts = <String, int>{};
    for (final job in matching) {
      for (final cert in job.requiredCertificates) {
        counts[cert] = (counts[cert] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return '';
    final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return '\n\n${top.value} of these ask for ${top.key}.';
  }

  /// No fabricated fallback. The seeker is told the assistant is unavailable and
  /// pointed at something that still works, rather than handed invented figures.
  static CopilotResult _unavailable(String reason) => CopilotResult(
        reply:
            'Lucky AI is unavailable right now, so I would rather not guess.\n\n'
            'You can still search and filter jobs, and every vacancy shows which of its '
            'required skills you already meet.',
        isLive: false,
        unavailableReason: reason,
      );

  /// Resume parsing runs server-side against the uploaded file. There is no
  /// endpoint for it yet — `POST /api/v1/resume/parse` is documented in
  /// CLAUDE.md but is not registered in routes/api.php — so this reports that
  /// honestly rather than returning empty data after a staged delay.
  static Future<Map<String, dynamic>> extractResumeData(String resumeFileName) async {
    return {
      'available': false,
      'reason': 'Resume parsing needs POST /api/v1/resume/parse, which does not exist yet.',
      'resumeFileName': resumeFileName,
      'bio': '',
      'skills': <String>[],
    };
  }

  /// Kept so existing callers compile. Prefer `ask()`, which reports whether the
  /// answer actually came from the assistant.
  @Deprecated('Use ask() — it reports whether the reply is live or a fallback.')
  static Future<String> generateReply(String userMessage) async =>
      (await ask(userMessage)).reply;
}
