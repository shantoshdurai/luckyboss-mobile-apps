import 'dart:async';

class GeminiCopilotService {
  static Future<String> generateReply(String userMessage) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final msg = userMessage.toLowerCase();

    if (msg.contains('warehouse') || msg.contains('logistics')) {
      return "Logistics & Supply Chain Vacancies:\n\n"
          "Warehouse Operations Lead: S\$3,500 - S\$5,000/mo (Singapore, Jurong)\n"
          "Inventory Controller: RM 4,200 - RM 6,500/mo (Malaysia, Johor)\n"
          "Supply Chain Specialist: INR 6.5L - 11L/yr (India, Mumbai)\n\n"
          "Tip: Having a valid WMS or Forklift certification increases your recruiter interview rate significantly.";
    }

    if (msg.contains('tech') || msg.contains('flutter') || msg.contains('developer') || msg.contains('software')) {
      return "Top Software & Tech Openings:\n\n"
          "Lead Mobile & AI Engineer: S\$7,000 - S\$9,500/mo (Singapore, One-North)\n"
          "Full-Stack Cloud Developer: INR 16L - 28L/yr (India, Bengaluru)\n"
          "DevOps & Platform Specialist: RM 8,000 - RM 12,500/mo (Malaysia, KL)\n\n"
          "Your match score is calculated based on your actual skills and experience.";
    }

    return "Hello! I am Lucky AI, your personalized career copilot.\n\n"
        "I analyze verified corporate postings across Singapore, Malaysia, and India to help you benchmark salaries and prepare for interviews.\n\n"
        "Try asking: What are top tech jobs in Singapore? or How do I boost my profile match score?";
  }

  static Future<Map<String, dynamic>> extractResumeData(String resumeFileName) async {
    await Future.delayed(const Duration(milliseconds: 2200));
    // In production, this calls an API with OCR + LLM extraction.
    // For demo, return empty - user fills in manually or API extracts from real file.
    return {
      'bio': '',
      'skills': <String>[],
      'resumeFileName': resumeFileName,
    };
  }
}