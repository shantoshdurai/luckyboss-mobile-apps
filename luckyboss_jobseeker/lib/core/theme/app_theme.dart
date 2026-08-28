import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// LUCKY BOSS — "LEDGER" DESIGN SYSTEM
///
/// The rule that makes this system work, and the rule that breaks it if broken:
///
///   THE FURNITURE IS ACHROMATIC. COLOUR IS RESERVED ENTIRELY FOR DATA.
///
/// Ink, paper and rules carry the layout. Every hue on screen means something —
/// a score, a stage, a source, a warning. No decorative colour. No coloured
/// button that isn't a signal. One stray green button and the whole thing leaks.
///
/// The logo's gradient appears in exactly two places: the logo itself, and the
/// 2px rule under the app bar (AppTheme.brandRule). Nowhere else.
///
/// Derived from the Lucky Boss wordmark: the mark gives a ramp
/// (#2BCA00 → #0096B2 → #006BD8), not a palette — five hues, no neutral, and
/// only the blue end is dark enough to hold text on white. So the signal colours
/// below are those hues taken down to ink strength so they can sit on paper.
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------------
  // FURNITURE — achromatic. Never carries meaning.
  // ---------------------------------------------------------------------------

  /// Near-black ink. Primary text, headings, the app bar.
  static const Color ink = Color(0xFF141A1B);

  /// Secondary ink. Supporting text, inactive states.
  static const Color inkMuted = Color(0xFF5A6663);

  /// Faint ink. Labels, meta, placeholders, the "Incoming" stage.
  static const Color inkFaint = Color(0xFF8E9A98);

  /// Warm paper. The page ground. Deliberately not white — it reads as printed
  /// matter, and it makes the white of a sheet or modal feel laid on a desk.
  static const Color paper = Color(0xFFF2F1EC);

  /// The sheet. Rows, cards, modals sit on this.
  static const Color surface = Color(0xFFF8FAF8);

  /// Hairline rule. This is the separator — not a shadow.
  static const Color rule = Color(0xFFE4E2DA);

  // Dark mode: ink on unlit paper. Not an inversion — the ground stays warm.
  static const Color inkDark = Color(0xFFF2F1EC);
  static const Color inkMutedDark = Color(0xFF9AA5A2);
  static const Color inkFaintDark = Color(0xFF6B7674);
  static const Color paperDark = Color(0xFF14100C);
  static const Color surfaceDark = Color(0xFF1C1915);
  static const Color ruleDark = Color(0xFF32302A);

  // ---------------------------------------------------------------------------
  // SIGNAL — the only colour in the system. Every one carries data meaning.
  // ---------------------------------------------------------------------------

  /// Won, hired, excellent, available. From the logo's green.
  static const Color signalPositive = Color(0xFF0F7A47);

  /// In progress, interviewing, strong. From the logo's teal.
  static const Color signalProgress = Color(0xFF0E6274);

  /// Source, external, informational. From the logo's blue.
  static const Color signalSource = Color(0xFF16437E);

  /// Attention: expiring, low credits, deciding, awaiting action.
  static const Color signalAttention = Color(0xFF8A5A00);

  /// Closed–lost, rejected, failed, over quota.
  static const Color signalClosed = Color(0xFF8C2A22);

  /// Backgrounds for signal chips. Kept close to paper so a chip never shouts.
  static const Color signalPositiveWash = Color(0xFFE6F0EA);
  static const Color signalProgressWash = Color(0xFFE4EDF0);
  static const Color signalSourceWash = Color(0xFFE5EAF2);
  static const Color signalAttentionWash = Color(0xFFF3ECDE);
  static const Color signalClosedWash = Color(0xFFF2E5E3);

  /// The logo's actual ramp. ONLY for the logo and the 2px rule under the app bar.
  static const List<Color> brandRamp = [
    Color(0xFF2BCA00),
    Color(0xFF0096B2),
    Color(0xFF006BD8),
  ];

  /// The one piece of brand colour in the chrome: a 2px gradient rule.
  static const LinearGradient brandRule = LinearGradient(colors: brandRamp);

  // ---------------------------------------------------------------------------
  // SHAPE — hairlines, not shadows. Modest radii. This is a ledger, not a card deck.
  // ---------------------------------------------------------------------------

  static const double radiusChip = 4;
  static const double radiusRow = 6;
  static const double radiusControl = 6;
  static const double radiusCard = 8;
  static const double radiusSheet = 10;
  static const double hairline = 1;

  // ---------------------------------------------------------------------------
  // TYPE — one superfamily for everything factual, one serif for people's names.
  //
  // Archivo carries the interface: titles, numbers, labels, buttons.
  // Newsreader carries people — candidate names only. That single graft is what
  // makes a row of data read as a person rather than a record.
  //
  // Every font call in the app goes through these helpers. If you ever want to
  // swap the families, this is the only place to edit.
  // ---------------------------------------------------------------------------

  static TextStyle _archivo({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = ink,
    double letterSpacing = 0,
    double? height,
  }) =>
      GoogleFonts.archivo(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  /// Screen title. Archivo 22, tight.
  static TextStyle screenTitle({Color color = ink, double size = 22}) =>
      _archivo(size: size, weight: FontWeight.w700, color: color, letterSpacing: -0.44, height: 1.15);

  /// Section title within a screen.
  static TextStyle sectionTitle({Color color = ink, double size = 15}) =>
      _archivo(size: size, weight: FontWeight.w700, color: color, letterSpacing: -0.15);

  static TextStyle sectionHeader({Color color = ink, double size = 15}) =>
      sectionTitle(color: color, size: size);

  static TextStyle rowTitle({Color color = ink, double size = 14}) =>
      _archivo(size: size, weight: FontWeight.w600, color: color, letterSpacing: -0.1);

  /// A person's name. The one serif in the system.
  static TextStyle personName({Color color = ink, double size = 16}) => GoogleFonts.newsreader(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.2,
      );

  /// Body text. 13px — this is a tool for working through long lists.
  static TextStyle body({Color color = inkMuted, FontWeight weight = FontWeight.w400, double size = 13}) =>
      _archivo(size: size, weight: weight, color: color, height: 1.35);

  /// Small supporting text.
  static TextStyle small({Color color = inkMuted, double size = 12}) => _archivo(size: size, color: color, height: 1.3);

  /// Tracked caps for facts and labels. The tracking is the logo's tagline
  /// tracking, reused — it is how the mark's structure enters the interface.
  static TextStyle meta({Color color = inkFaint, double size = 10, FontWeight weight = FontWeight.w600}) =>
      _archivo(size: size, weight: weight, color: color, letterSpacing: size * 0.09);

  /// A score. Tabular figures, set large enough to read at a glance.
  static TextStyle score({Color color = ink, double size = 22}) =>
      _archivo(size: size, weight: FontWeight.w700, color: color, letterSpacing: -0.4);

  /// Button label.
  static TextStyle button({Color color = ink}) =>
      _archivo(size: 13, weight: FontWeight.w600, color: color, letterSpacing: 0.1);


  // ---------------------------------------------------------------------------
  // COMPATIBILITY SHIM — temporary, job seeker app only.
  //
  // The seeker screens predate Ledger and call the old navy/emerald tokens and
  // the old sans*/serifTitle helpers at ~141 sites. Rather than leave the app
  // broken, those names are remapped onto Ledger here so every screen compiles
  // and picks up the new ink, paper and type immediately.
  //
  // Note what `serifTitle` maps to: Archivo, NOT the serif. In Ledger the serif
  // is reserved for people's names, and screen titles are set in Archivo. So
  // this mapping enforces that rule across all six old call sites for free.
  //
  // These are not part of the design system. Delete each one as its screens are
  // reworked onto AppTheme.screenTitle / sectionTitle / body / small / meta.
  // ---------------------------------------------------------------------------

  @Deprecated('Ledger has no navy. Use AppTheme.ink.')
  static const Color primaryNavy = ink;
  @Deprecated('Green is a data signal, not furniture. Use AppTheme.signalPositive.')
  static const Color emerald = signalPositive;
  @Deprecated('Green is a data signal, not furniture. Use AppTheme.signalPositive.')
  static const Color emeraldDark = signalPositive;
  @Deprecated('Blue is a data signal. Use AppTheme.signalSource.')
  static const Color royalBlue = signalSource;
  @Deprecated('Use AppTheme.signalAttention.')
  static const Color amber = signalAttention;
  @Deprecated('Use AppTheme.paper.')
  static const Color bgPaper = paper;
  @Deprecated('Use AppTheme.rule.')
  static const Color borderLight = rule;
  @Deprecated('Use AppTheme.rule.')
  static const Color borderMedium = rule;
  @Deprecated('Use AppTheme.ink.')
  static const Color textPrimary = ink;
  @Deprecated('Use AppTheme.inkMuted.')
  static const Color textSecondary = inkMuted;
  @Deprecated('Use AppTheme.inkFaint.')
  static const Color textMuted = inkFaint;

  @Deprecated('Use AppTheme.screenTitle() — Ledger sets titles in Archivo, not a serif.')
  static TextStyle serifTitle({
    double fontSize = 24,
    Color color = ink,
    FontWeight fontWeight = FontWeight.w700,
    double? letterSpacing,
    double? height,
  }) =>
      _archivo(
        size: fontSize,
        weight: fontWeight,
        color: color,
        letterSpacing: letterSpacing ?? -0.3,
        height: height ?? 1.15,
      );

  @Deprecated('Use AppTheme.sectionTitle() or AppTheme.body(weight: FontWeight.w700).')
  static TextStyle sansBold({
    double fontSize = 14,
    Color color = ink,
    double? letterSpacing,
    double? height,
  }) =>
      _archivo(
        size: fontSize,
        weight: FontWeight.w700,
        color: color,
        letterSpacing: letterSpacing ?? 0,
        height: height,
      );

  @Deprecated('Use AppTheme.body(weight: FontWeight.w600).')
  static TextStyle sansSemiBold({
    double fontSize = 14,
    Color color = ink,
    double? letterSpacing,
    double? height,
  }) =>
      _archivo(
        size: fontSize,
        weight: FontWeight.w600,
        color: color,
        letterSpacing: letterSpacing ?? 0,
        height: height,
      );

  @Deprecated('Use AppTheme.body(weight: FontWeight.w500).')
  static TextStyle sansMedium({
    double fontSize = 13,
    Color color = inkMuted,
    double? letterSpacing,
    double? height,
  }) =>
      _archivo(
        size: fontSize,
        weight: FontWeight.w500,
        color: color,
        letterSpacing: letterSpacing ?? 0,
        height: height,
      );

  @Deprecated('Use AppTheme.body().')
  static TextStyle sansRegular({
    double fontSize = 13,
    Color color = inkMuted,
    double? letterSpacing,
    double? height,
  }) =>
      _archivo(
        size: fontSize,
        weight: FontWeight.w400,
        color: color,
        letterSpacing: letterSpacing ?? 0,
        height: height,
      );

  // ---------------------------------------------------------------------------
  // BRIGHTNESS-AWARE ACCESSORS
  //
  // The constants above are the light palette. Referring to them directly in a
  // widget pins that widget to light mode — AppTheme.ink is near-black, which
  // is invisible on a dark ground. These resolve against the active theme, so
  // one call site works in both.
  //
  // Use these anywhere a colour is chosen at build time. The raw constants stay
  // for the ThemeData definitions below and for the signal colours, which are
  // deliberately identical in both modes because they encode data, not chrome.
  // ---------------------------------------------------------------------------

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Primary text and iconography.
  static Color inkOf(BuildContext context) => isDark(context) ? inkDark : ink;

  /// Supporting text.
  static Color inkMutedOf(BuildContext context) =>
      isDark(context) ? inkMutedDark : inkMuted;

  /// Labels, meta, placeholders.
  static Color inkFaintOf(BuildContext context) =>
      isDark(context) ? inkFaintDark : inkFaint;

  /// The page ground.
  static Color paperOf(BuildContext context) =>
      isDark(context) ? paperDark : paper;

  /// Cards, rows, sheets.
  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? surfaceDark : surface;

  /// Hairline separators.
  static Color ruleOf(BuildContext context) =>
      isDark(context) ? ruleDark : rule;

  /// Fill for a filled primary button.
  ///
  /// In light mode this is ink — the system's rule that primary actions are
  /// black on paper. Inverting that literally for dark mode produces a
  /// full-width slab at #F2F1EC, which on a #14100C ground is a glare source
  /// rather than a button. This steps it back to a warm off-white: still
  /// unmistakably the primary action, without lighting up the screen.
  static const Color _inkFillDark = Color(0xFFD9D6CC);

  static Color primaryFillOf(BuildContext context) =>
      isDark(context) ? _inkFillDark : ink;

  /// Label colour for [primaryFillOf].
  static Color onPrimaryFillOf(BuildContext context) =>
      isDark(context) ? paperDark : surface;

  /// What sits ON an ink-coloured surface — a filled primary button, a
  /// snackbar, a selected chip.
  ///
  /// This is the counterpart [inkOf] needs and the one that is easy to forget.
  /// In dark mode `inkOf` returns near-white, so a button painted with it and
  /// labelled `Colors.white` is white text on a white button. Pairing every
  /// ink background with this keeps the contrast inverted correctly in both
  /// modes.
  static Color onInkOf(BuildContext context) =>
      isDark(context) ? paperDark : surface;

  /// Signal washes are near-paper by design, so the light versions read as
  /// muddy blocks on a dark ground. These lift the hue instead.
  static Color washOf(BuildContext context, Color signal) => isDark(context)
      ? Color.alphaBlend(signal.withValues(alpha: 0.18), paperDark)
      : Color.alphaBlend(signal.withValues(alpha: 0.10), paper);

  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        inkC: ink,
        inkMutedC: inkMuted,
        inkFaintC: inkFaint,
        paperC: paper,
        surfaceC: surface,
        ruleC: rule,
      );

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        inkC: inkDark,
        inkMutedC: inkMutedDark,
        inkFaintC: inkFaintDark,
        paperC: paperDark,
        surfaceC: surfaceDark,
        ruleC: ruleDark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color inkC,
    required Color inkMutedC,
    required Color inkFaintC,
    required Color paperC,
    required Color surfaceC,
    required Color ruleC,
  }) {
    final onInk = brightness == Brightness.light ? surface : paperDark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: paperC,
      canvasColor: paperC,
      dividerColor: ruleC,
      colorScheme: ColorScheme(
        brightness: brightness,
        // Primary is INK, not a brand colour. Primary actions are black-on-paper.
        primary: inkC,
        onPrimary: onInk,
        secondary: inkMutedC,
        onSecondary: onInk,
        error: signalClosed,
        onError: Colors.white,
        surface: surfaceC,
        onSurface: inkC,
        outline: ruleC,
      ),
      textTheme: TextTheme(
        headlineSmall: screenTitle(color: inkC),
        titleMedium: sectionTitle(color: inkC),
        bodyMedium: body(color: inkMutedC),
        bodySmall: small(color: inkMutedC),
        labelSmall: meta(color: inkFaintC),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: paperC,
        foregroundColor: inkC,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: sectionTitle(color: inkC),
      ),
      dividerTheme: DividerThemeData(color: ruleC, thickness: hairline, space: hairline),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: inkC,
          foregroundColor: onInk,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
          textStyle: button(color: onInk),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: inkC,
          minimumSize: const Size.fromHeight(44),
          side: BorderSide(color: ruleC, width: hairline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
          textStyle: button(color: inkC),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: inkC, textStyle: button(color: inkC)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceC,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: body(color: inkFaintC),
        labelStyle: meta(color: inkFaintC, size: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide(color: ruleC, width: hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide(color: ruleC, width: hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide(color: inkC, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: signalClosed, width: hairline),
        ),
      ),
    );
  }
}

// =============================================================================
// STAGES — six, not seventeen.
//
// Seventeen status colours is a paint box, not a system: nobody learns 17 hues,
// and at chip size half of them are indistinguishable. So six stages carry the
// colour and the exact status word carries the precision. "Offer Sent" and
// "Offer Accepted" share an ink; they differ in text, which is the thing a
// recruiter actually reads.
// =============================================================================

enum CandidateStage { incoming, engaged, interviewing, deciding, closedWon, closedLost }

extension CandidateStageStyle on CandidateStage {
  Color get color {
    switch (this) {
      // Incoming is not a signal yet — nothing has happened. So it takes no hue.
      case CandidateStage.incoming:
        return AppTheme.inkFaint;
      case CandidateStage.engaged:
        return AppTheme.signalSource;
      case CandidateStage.interviewing:
        return AppTheme.signalProgress;
      case CandidateStage.deciding:
        return AppTheme.signalAttention;
      case CandidateStage.closedWon:
        return AppTheme.signalPositive;
      case CandidateStage.closedLost:
        return AppTheme.signalClosed;
    }
  }

  Color get wash {
    switch (this) {
      case CandidateStage.incoming:
        return AppTheme.rule;
      case CandidateStage.engaged:
        return AppTheme.signalSourceWash;
      case CandidateStage.interviewing:
        return AppTheme.signalProgressWash;
      case CandidateStage.deciding:
        return AppTheme.signalAttentionWash;
      case CandidateStage.closedWon:
        return AppTheme.signalPositiveWash;
      case CandidateStage.closedLost:
        return AppTheme.signalClosedWash;
    }
  }

  String get label {
    switch (this) {
      case CandidateStage.incoming:
        return 'Incoming';
      case CandidateStage.engaged:
        return 'Engaged';
      case CandidateStage.interviewing:
        return 'Interviewing';
      case CandidateStage.deciding:
        return 'Deciding';
      case CandidateStage.closedWon:
        return 'Closed won';
      case CandidateStage.closedLost:
        return 'Closed lost';
    }
  }

  /// The 17 statuses the functional spec requires, each mapped to the stage that
  /// gives it its colour. The status string itself is what gets displayed.
  static CandidateStage of(String status) {
    switch (status.toLowerCase().trim()) {
      case 'new':
      case 'viewed':
        return CandidateStage.incoming;
      case 'contacted':
      case 'shortlisted':
        return CandidateStage.engaged;
      case 'interview scheduled':
      case 'interview':
      case 'interviewed':
      case 'second interview':
      case 'assessment':
        return CandidateStage.interviewing;
      case 'hold':
      case 'selected':
      case 'offer prepared':
      case 'offer sent':
      case 'offer':
        return CandidateStage.deciding;
      case 'offer accepted':
      case 'joined':
        return CandidateStage.closedWon;
      case 'offer rejected':
      case 'rejected':
      case 'archived':
        return CandidateStage.closedLost;
      default:
        return CandidateStage.incoming;
    }
  }

  /// Every status the spec defines, in pipeline order — for status pickers.
  static const List<String> allStatuses = [
    'New',
    'Viewed',
    'Contacted',
    'Shortlisted',
    'Interview Scheduled',
    'Interviewed',
    'Second Interview',
    'Assessment',
    'Hold',
    'Selected',
    'Offer Prepared',
    'Offer Sent',
    'Offer Accepted',
    'Offer Rejected',
    'Joined',
    'Rejected',
    'Archived',
  ];
}

// =============================================================================
// MATCH TIER — a score is never shown as a bare percentage.
//
// "74" tells a recruiter nothing until they know what good looks like. The tier
// word does that work. A null score is its own state: the platform fell back to
// rule-based matching, and pretending otherwise would be a lie in the UI.
// =============================================================================

enum MatchTier { excellent, strong, moderate, low, unscored }

extension MatchTierStyle on MatchTier {
  static MatchTier of(double? score) {
    if (score == null) return MatchTier.unscored;
    if (score >= 90) return MatchTier.excellent;
    if (score >= 80) return MatchTier.strong;
    if (score >= 65) return MatchTier.moderate;
    return MatchTier.low;
  }

  String get label {
    switch (this) {
      case MatchTier.excellent:
        return 'Excellent';
      case MatchTier.strong:
        return 'Strong';
      case MatchTier.moderate:
        return 'Moderate';
      case MatchTier.low:
        return 'Low';
      case MatchTier.unscored:
        return 'Rule match';
    }
  }

  /// Colour drains out as the score falls. An excellent match is the only one
  /// that gets full positive ink; a low match is furniture.
  Color get color {
    switch (this) {
      case MatchTier.excellent:
        return AppTheme.signalPositive;
      case MatchTier.strong:
        return AppTheme.signalProgress;
      case MatchTier.moderate:
        return AppTheme.inkMuted;
      case MatchTier.low:
        return AppTheme.inkFaint;
      case MatchTier.unscored:
        return AppTheme.inkFaint;
    }
  }
}

// =============================================================================
// CANDIDATE SOURCE — where a candidate came from is never hidden.
// =============================================================================

enum CandidateSource { applied, recommended, external }

extension CandidateSourceStyle on CandidateSource {
  String get label {
    switch (this) {
      case CandidateSource.applied:
        return 'Applied';
      case CandidateSource.recommended:
        return 'Recommended';
      case CandidateSource.external:
        return 'External';
    }
  }

  Color get color {
    switch (this) {
      case CandidateSource.applied:
        return AppTheme.signalPositive;
      case CandidateSource.recommended:
        return AppTheme.signalProgress;
      case CandidateSource.external:
        return AppTheme.signalSource;
    }
  }

  /// Someone who applied to this job chose to make contact. Their phone and
  /// email are never gated behind a credit — charging for a contact the
  /// candidate volunteered is indefensible.
  bool get contactAlwaysVisible => this == CandidateSource.applied;
}


// =============================================================================
// JOB SOURCE — the job seeker's equivalent of CandidateSource.
//
// The specification is explicit that a third-party listing must always show
// where it came from, and that the whole External section disappears when the
// admin turns third-party jobs off. Provenance is not a detail here: a seeker
// deciding whether to trust a listing needs to know who published it.
// =============================================================================

enum JobSource { luckyBoss, external }

extension JobSourceStyle on JobSource {
  String get label {
    switch (this) {
      case JobSource.luckyBoss:
        return 'Lucky Boss';
      case JobSource.external:
        return 'External';
    }
  }

  Color get color {
    switch (this) {
      case JobSource.luckyBoss:
        return AppTheme.signalPositive;
      case JobSource.external:
        return AppTheme.signalSource;
    }
  }
}
