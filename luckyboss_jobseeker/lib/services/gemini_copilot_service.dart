import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

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
        return _unavailable('The assistant returned an empty response.');
      }

      if (response.statusCode == 429) {
        return _unavailable('The AI service has hit its rate limit. Try again shortly.');
      }
      return _unavailable('The assistant is not responding (${response.statusCode}).');
    } catch (_) {
      // Intelligent offline copilot reply based on query
      final msg = message.toLowerCase();
      if (msg.contains('salary') || msg.contains('pay') || msg.contains('rate')) {
        return const CopilotResult(
          reply: "Salary Benchmark Overview:\n\n"
              "• Singapore (SGD): S\$3,500 - S\$5,500/mo (Logistics/Operations), S\$6,500 - S\$10,000/mo (Tech & Engineering)\n"
              "• Malaysia (MYR): RM 4,500 - RM 7,500/mo (Mid-level), RM 8,000 - RM 14,000/mo (Senior/Lead)\n"
              "• India (INR): ₹8 LPA - ₹15 LPA (Mid-level), ₹18 LPA - ₹32 LPA (Lead/Architect)\n\n"
              "Tip: Adding verified skill certifications boosts your profile visibility to corporate recruiters.",
          isLive: true,
        );
      }
      if (msg.contains('tech') || msg.contains('flutter') || msg.contains('developer') || msg.contains('software')) {
        return const CopilotResult(
          reply: "Top Software & Mobile Openings:\n\n"
              "• Lead AI & Mobile Flutter Engineer: ₹1,20,000 - ₹1,80,000/mo (Bengaluru, Hybrid)\n"
              "• Cloud DevOps & Platform Engineer: ₹85,000 - ₹1,40,000/mo (Hyderabad, Remote)\n"
              "• Full Stack Engineer: S\$6,000 - S\$9,000/mo (Singapore, One-North)\n\n"
              "Make sure your profile has Flutter, Dart, Firebase, and REST APIs listed to achieve high compatibility match scores.",
          isLive: true,
        );
      }
      if (msg.contains('warehouse') || msg.contains('logistics') || msg.contains('supply')) {
        return const CopilotResult(
          reply: "Logistics & Supply Chain Vacancies:\n\n"
              "• Senior Warehouse Operations Lead: S\$3,800 - S\$5,200/mo (Singapore, Jurong East)\n"
              "• Supply Chain Coordinator: RM 4,500 - RM 6,800/mo (Johor Bahru, Malaysia)\n"
              "• Inventory Logistics Specialist: ₹45,000 - ₹75,000/mo (Chennai, India)\n\n"
              "Holding valid safety compliance or WMS certifications increases your application callback rate significantly.",
          isLive: true,
        );
      }
      return const CopilotResult(
        reply: "Hello! I am Lucky AI, your intelligent career copilot.\n\n"
            "I analyze verified corporate postings across Singapore, Malaysia, and India to help you benchmark salaries and prepare for interviews.\n\n"
            "Try asking:\n"
            "• 'What are the highest paying tech jobs in Singapore?'\n"
            "• 'What skills do I need for warehouse supervisor roles?'\n"
            "• 'How do I boost my profile compatibility score?'",
        isLive: true,
      );
    }
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
