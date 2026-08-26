import 'dart:async';

class GeminiCopilotService {
  /// Chat reply for the Lucky AI copilot modal
  static Future<String> generateReply(String userMessage) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final msg = userMessage.toLowerCase();

    if (msg.contains('warehouse') || msg.contains('logistics')) {
      return "📦 **Logistics & Supply Chain Vacancies:**\n\n"
          "• **Warehouse Operations Lead**: S\$3,500 – S\$5,000/mo (Singapore, Jurong)\n"
          "• **Inventory Controller**: RM 4,200 – RM 6,500/mo (Malaysia, Johor)\n"
          "• **Supply Chain Specialist**: ₹6.5L – ₹11L/yr (India, Mumbai)\n\n"
          "💡 *Smart Tip:* Having a valid **WMS or Forklift certification** increases your recruiter interview rate by 2.4x!";
    }

    if (msg.contains('tech') || msg.contains('flutter') || msg.contains('developer') || msg.contains('software')) {
      return "💻 **Top Software & Tech Openings:**\n\n"
          "• **Lead Mobile & AI Engineer**: S\$7,000 – S\$9,500/mo (Singapore, One-North)\n"
          "• **Full-Stack Cloud Developer**: ₹16L – ₹28L/yr (India, Bengaluru)\n"
          "• **DevOps & Platform Specialist**: RM 8,000 – RM 12,500/mo (Malaysia, KL)\n\n"
          "⚡ *Your AI Profile Compatibility Score for Mobile roles is currently 94%!*";
    }

    return "Hello! I am **Lucky AI**, your personalized career copilot.\n\n"
        "I analyze verified corporate postings across Singapore, Malaysia, and India to help you benchmark salaries and prepare for interviews.\n\n"
        "Feel free to ask: *\"What are top tech jobs in Singapore?\"* or *\"How do I boost my profile match score?\"*";
  }

  /// Extract structured profile data from resume text (simulated AI extraction)
  static Future<Map<String, dynamic>> extractResumeData(String resumeFileName) async {
    // Simulate AI processing time with a realistic delay
    await Future.delayed(const Duration(milliseconds: 2200));

    // In production, this would call an API that runs OCR + LLM extraction.
    // For demo mode, we return realistic extracted data.
    return {
      'name': 'Arjun Mehta',
      'email': 'arjun.mehta@gmail.com',
      'countryCode': 'IN',
      'experienceYears': 4,
      'preferredCategory': 'IT & Software',
      'bio': 'Full-stack mobile engineer with 4+ years of experience building cross-platform applications using Flutter, Dart, and cloud-native backend services. Proven track record of shipping production apps with 50K+ downloads.',
      'skills': [
        'Flutter',
        'Dart',
        'Firebase',
        'Python',
        'REST APIs',
        'Docker',
        'Node.js',
        'PostgreSQL',
        'Git',
        'Figma',
      ],
      'resumeFileName': resumeFileName,
    };
  }
}