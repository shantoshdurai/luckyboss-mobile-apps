/// How a vacancy is promoted, per spec §61.
///
/// The spec names five states an admin can set — Featured, Urgent, Sponsored,
/// Apply Soon, Paid Apply — with a start date, end date, priority and home page
/// position. This is the employer-facing half: the boost a company buys for a
/// job it needs filled now.
///
/// **On labelling.** Shantosh's ask was that a boosted job goes to the top and
/// stands out. What is shown to the candidate is a badge that describes the
/// *hiring situation* — "Urgent hiring", "Featured" — rather than one that says
/// "this employer paid". Both are true, and the first is the one a candidate
/// can use: a genuinely urgent vacancy is worth knowing about. It also keeps
/// the feed honest without costing the employer anything, and it is what §61
/// already calls these states.
enum BoostType {
  /// Top of the feed and highlighted. The general-purpose boost.
  featured,

  /// For a vacancy that must be filled now. Ranks highest of all and says so.
  urgent,

  /// Widest reach: the feed, search results and the home page strip.
  sponsored;

  String get label => switch (this) {
        BoostType.featured => 'Featured',
        BoostType.urgent => 'Urgent hiring',
        BoostType.sponsored => 'Sponsored',
      };

  /// What the employer is buying, in their terms.
  String get pitch => switch (this) {
        BoostType.featured =>
          'Sits above unboosted jobs in the feed and in search.',
        BoostType.urgent =>
          'Top of everything, marked urgent. For a vacancy you need filled '
              'this week.',
        BoostType.sponsored =>
          'Everywhere: feed, search, and the app home page.',
      };

  /// How far up this lifts a job. Higher wins; unboosted jobs are 0.
  ///
  /// Deliberately coarse. A fine-grained auction would let a large employer
  /// bury every small contractor permanently, which for an agency whose
  /// candidates are placed by relationship is a bad trade.
  int get priority => switch (this) {
        BoostType.urgent => 30,
        BoostType.sponsored => 20,
        BoostType.featured => 10,
      };
}

/// Price per day, per market.
///
/// Shantosh did not have prices from sir yet — *"idk he did say the price so do
/// something"* — so these are placeholders chosen to be plausible against local
/// job-board rates and, more importantly, to live in **one table** that can be
/// replaced in a minute when the real numbers arrive. Nothing else in the app
/// hardcodes a price.
class BoostPricing {
  BoostPricing._();

  /// Currency per market, matching the rest of the app.
  static const Map<String, String> currency = {
    'IN': 'INR',
    'SG': 'SGD',
    'MY': 'MYR',
  };

  /// Daily rate, keyed by market then boost type.
  static const Map<String, Map<BoostType, int>> perDay = {
    'IN': {
      BoostType.featured: 300,
      BoostType.sponsored: 600,
      BoostType.urgent: 900,
    },
    'SG': {
      BoostType.featured: 12,
      BoostType.sponsored: 25,
      BoostType.urgent: 40,
    },
    'MY': {
      BoostType.featured: 40,
      BoostType.sponsored: 80,
      BoostType.urgent: 130,
    },
  };

  /// The durations offered. Seven days is the default because that is roughly
  /// how long a live vacancy takes to gather a usable shortlist.
  static const List<int> durations = [3, 7, 14, 30];

  /// A discount for longer runs — the same reason every ad platform does it,
  /// and it stops a company re-buying three-day boosts forever.
  static double _multiplier(int days) => switch (days) {
        30 => 0.70,
        14 => 0.80,
        7 => 0.90,
        _ => 1.0,
      };

  static int priceFor(BoostType type, int days, String countryCode) {
    final rate = perDay[countryCode]?[type] ?? perDay['SG']![type]!;
    return (rate * days * _multiplier(days)).round();
  }

  static String currencyFor(String countryCode) =>
      currency[countryCode] ?? 'SGD';

  static String displayPrice(BoostType type, int days, String countryCode) =>
      '${currencyFor(countryCode)} '
      '${priceFor(type, days, countryCode).toString().replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+$)'),
            (m) => '${m[1]},',
          )}';
}

/// A boost bought for a job.
class JobBoost {
  final BoostType type;
  final DateTime startsAt;
  final DateTime endsAt;

  /// What was charged, kept with the boost so the payment history (spec §66)
  /// shows the price at the time rather than today's rate.
  final int amount;
  final String currency;

  const JobBoost({
    required this.type,
    required this.startsAt,
    required this.endsAt,
    required this.amount,
    required this.currency,
  });

  /// Whether the boost is running now.
  ///
  /// Checked rather than stored, so a boost expires on its own. A flag would
  /// need something to turn it off, and nothing runs on a handset that is shut.
  bool get isActive {
    final now = DateTime.now();
    // `!isBefore` rather than `isAfter`: a boost that starts now is active now.
    // With the strict comparison a boost bought this instant scored zero until
    // a microsecond had passed, so the job the employer had just paid to lift
    // stayed where it was — briefly on a handset, and reliably in a test.
    return !now.isBefore(startsAt) && now.isBefore(endsAt);
  }

  int get daysRemaining {
    final left = endsAt.difference(DateTime.now()).inDays;
    return left < 0 ? 0 : left;
  }

  /// Ranking weight — zero once expired, so an old boost stops lifting a job
  /// without anything having to clean it up.
  int get priority => isActive ? type.priority : 0;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'starts_at': startsAt.toIso8601String(),
        'ends_at': endsAt.toIso8601String(),
        'amount': amount,
        'currency': currency,
      };

  factory JobBoost.fromJson(Map<String, dynamic> j) => JobBoost(
        type: BoostType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => BoostType.featured,
        ),
        startsAt:
            DateTime.tryParse((j['starts_at'] as String?) ?? '') ?? DateTime.now(),
        endsAt: DateTime.tryParse((j['ends_at'] as String?) ?? '') ??
            DateTime.now(),
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        currency: (j['currency'] as String?) ?? 'SGD',
      );
}

/// A charge against the company, spec §66 (Employer Payment History).
class EmployerCharge {
  final String id;
  final String description;
  final int amount;
  final String currency;
  final DateTime chargedAt;

  /// The job this was bought for, when it was a boost.
  final String? jobId;

  const EmployerCharge({
    required this.id,
    required this.description,
    required this.amount,
    required this.currency,
    required this.chargedAt,
    this.jobId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'currency': currency,
        'charged_at': chargedAt.toIso8601String(),
        'job_id': jobId,
      };

  factory EmployerCharge.fromJson(Map<String, dynamic> j) => EmployerCharge(
        id: j['id'] as String,
        description: (j['description'] ?? '') as String,
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        currency: (j['currency'] ?? 'SGD') as String,
        chargedAt:
            DateTime.tryParse((j['charged_at'] as String?) ?? '') ?? DateTime.now(),
        jobId: j['job_id'] as String?,
      );
}
