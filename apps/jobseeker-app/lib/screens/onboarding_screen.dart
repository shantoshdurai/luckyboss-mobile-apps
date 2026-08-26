import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';
import 'auth/phone_auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_SlideData> _slides = [
    _SlideData(
      headline: 'Your career,\nacross borders',
      subtitle: 'Direct access to verified corporate employers in India, Singapore & Malaysia with 100% salary transparency.',
      accentColor: AppTheme.emerald,
      secondaryColor: AppTheme.royalBlue,
      illustrationBuilder: _buildGlobeIllustration,
    ),
    _SlideData(
      headline: 'AI-powered\njob matching',
      subtitle: 'Our intelligent matching engine pairs your verified skills with high-paying vacancies for 3x faster callbacks.',
      accentColor: AppTheme.royalBlue,
      secondaryColor: AppTheme.emerald,
      illustrationBuilder: _buildAiMatchIllustration,
    ),
    _SlideData(
      headline: 'Track every\nstep, live',
      subtitle: 'Follow your entire hiring pipeline in real-time from application to shortlist, interview, and offer letter.',
      accentColor: AppTheme.amber,
      secondaryColor: AppTheme.emerald,
      illustrationBuilder: _buildPipelineIllustration,
    ),
  ];

  void _navigateToAuth() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const PhoneAuthScreen(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Full-bleed dark gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF040E22), // deep midnight
                  AppTheme.primaryNavy,
                  Color(0xFF0D224E), // mid navy
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Floating animated glow orb — top right
          Positioned(
            top: size.height * 0.05,
            right: -30,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _slides[_currentPage].accentColor.withValues(alpha: 0.28),
                    _slides[_currentPage].accentColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.9, end: 1.15, duration: 3000.ms, curve: Curves.easeInOut),
          ),

          // Floating animated glow orb — bottom left
          Positioned(
            bottom: size.height * 0.15,
            left: -40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _slides[_currentPage].secondaryColor.withValues(alpha: 0.22),
                    _slides[_currentPage].secondaryColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.2, duration: 4000.ms, curve: Curves.easeInOut),
          ),

          // Subtle diagonal grid pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _MeshPatternPainter(),
            ),
          ),

          // Main Layout
          SafeArea(
            child: Column(
              children: [
                // Top Bar with Brand Pill & Skip
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppTheme.emerald,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Lucky Boss Career Hub',
                              style: AppTheme.sansBold(fontSize: 11.5, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _navigateToAuth,
                        child: Text(
                          'Skip',
                          style: AppTheme.sansSemiBold(fontSize: 14, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),

                // Carousel Slides
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Custom Responsive Visual
                            SizedBox(
                              height: 250,
                              child: Center(
                                child: slide.illustrationBuilder(slide.accentColor, slide.secondaryColor),
                              ),
                            ),

                            const SizedBox(height: 36),

                            // Headline
                            Text(
                              slide.headline,
                              textAlign: TextAlign.center,
                              style: AppTheme.serifTitle(
                                fontSize: 32,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Subtitle
                            Text(
                              slide.subtitle,
                              textAlign: TextAlign.center,
                              style: AppTheme.sansRegular(
                                fontSize: 14,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Navigation & CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: Column(
                    children: [
                      // Expanding Stepper Indicator Pills
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (i) {
                          final isActive = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 32 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? _slides[_currentPage].accentColor
                                  : Colors.white24,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: _slides[_currentPage].accentColor.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Full-width CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage < _slides.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _navigateToAuth();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _slides[_currentPage].accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            shadowColor: _slides[_currentPage].accentColor.withValues(alpha: 0.4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == _slides.length - 1 ? 'Get Started →' : 'Continue',
                                style: AppTheme.sansBold(fontSize: 16, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SLIDE DATA MODEL ─────────────────────────────────────────────
class _SlideData {
  final String headline;
  final String subtitle;
  final Color accentColor;
  final Color secondaryColor;
  final Widget Function(Color accent, Color secondary) illustrationBuilder;

  _SlideData({
    required this.headline,
    required this.subtitle,
    required this.accentColor,
    required this.secondaryColor,
    required this.illustrationBuilder,
  });
}

// ─── SLIDE 1: CROSS-BORDER HUB WITH CLEAN COUNTRY BADGES ───────────
Widget _buildGlobeIllustration(Color accent, Color secondary) {
  return SizedBox(
    width: 320,
    height: 240,
    child: Stack(
      alignment: Alignment.center,
      children: [
        // Concentric radar rings
        Container(
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.5),
          ),
        ),
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: secondary.withValues(alpha: 0.25), width: 1.5),
          ),
        ),

        // Glowing center globe pod
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [accent.withValues(alpha: 0.4), secondary.withValues(alpha: 0.25)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white38, width: 2),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.language_rounded, color: Colors.white, size: 38),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 0.98, end: 1.04, duration: 2500.ms),

        // Country Pill 1: India (Top Left)
        Positioned(
          top: 12,
          left: 10,
          child: _countryBadge('🇮🇳', 'India', '₹ INR', accent),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: -4, duration: 2400.ms),

        // Country Pill 2: Singapore (Top Right)
        Positioned(
          top: 12,
          right: 10,
          child: _countryBadge('🇸🇬', 'Singapore', 'S\$ SGD', secondary),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: 4, duration: 2800.ms),

        // Country Pill 3: Malaysia (Bottom Center)
        Positioned(
          bottom: 14,
          child: _countryBadge('🇲🇾', 'Malaysia', 'RM MYR', AppTheme.amber),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: -4, duration: 2600.ms),
      ],
    ),
  );
}

Widget _countryBadge(String flag, String name, String currency, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFF0C1D42).withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(flag, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name, style: AppTheme.sansBold(fontSize: 11.5, color: Colors.white)),
            Text(currency, style: AppTheme.sansMedium(fontSize: 9.5, color: color)),
          ],
        ),
      ],
    ),
  );
}

// ─── SLIDE 2: HERO AI MATCH SCOREBOARD CARD (NO CLIPPING/OVERLAP) ───
Widget _buildAiMatchIllustration(Color accent, Color secondary) {
  return Container(
    width: 320,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF0B1F47).withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.2),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.auto_awesome, color: accent, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LUCKY CAREER AI ENGINE',
                    style: AppTheme.sansBold(fontSize: 11, color: Colors.white70, letterSpacing: 0.5),
                  ),
                  Text(
                    'High Profile Compatibility',
                    style: AppTheme.sansMedium(fontSize: 10, color: AppTheme.emerald),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.emerald.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.3)),
              ),
              child: Text('LIVE', style: AppTheme.sansBold(fontSize: 9, color: AppTheme.emerald)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(color: Colors.white12, height: 1),
        const SizedBox(height: 12),

        // Row 1
        _jobScoreRow('Lead Flutter Engineer', '94% Fit', AppTheme.emerald),
        const SizedBox(height: 8),

        // Row 2
        _jobScoreRow('Cloud DevOps Architect', '88% Fit', AppTheme.royalBlue),
        const SizedBox(height: 8),

        // Row 3
        _jobScoreRow('Supply Chain Specialist', '82% Fit', AppTheme.amber),
      ],
    ),
  );
}

Widget _jobScoreRow(String title, String score, Color badgeColor) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTheme.sansSemiBold(fontSize: 12.5, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            score,
            style: AppTheme.sansBold(fontSize: 11, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

// ─── SLIDE 3: ATS PIPELINE CARD ────────────────────────────────────
Widget _buildPipelineIllustration(Color accent, Color secondary) {
  return Container(
    width: 320,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF0B1F47).withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.18),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LIVE RECRUITER PIPELINE',
              style: AppTheme.sansBold(fontSize: 11, color: Colors.white70, letterSpacing: 0.5),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.amber.withValues(alpha: 0.3)),
              ),
              child: Text('STAGE 3 ACTIVE', style: AppTheme.sansBold(fontSize: 9, color: AppTheme.amber)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 4 Stepper nodes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _pipelineNode(Icons.check, 'Applied', AppTheme.emerald, true),
            _pipelineConnector(AppTheme.emerald),
            _pipelineNode(Icons.check, 'Shortlist', AppTheme.emerald, true),
            _pipelineConnector(AppTheme.amber),
            _pipelineNode(Icons.videocam, 'Interview', AppTheme.amber, true),
            _pipelineConnector(Colors.white24),
            _pipelineNode(Icons.emoji_events_outlined, 'Offer', Colors.white24, false),
          ],
        ),
        const SizedBox(height: 14),

        // Sub card: Schedule
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.emerald.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.emerald),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Interview Confirmed • 28 Aug, 2:30 PM',
                  style: AppTheme.sansMedium(fontSize: 11, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _pipelineNode(IconData icon, String label, Color color, bool completed) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: completed ? color : Colors.white10,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Icon(icon, size: 16, color: completed ? Colors.white : Colors.white38),
      ),
      const SizedBox(height: 6),
      Text(
        label,
        style: AppTheme.sansMedium(fontSize: 9.5, color: completed ? Colors.white : Colors.white38),
      ),
    ],
  );
}

Widget _pipelineConnector(Color color) {
  return Container(
    width: 16,
    height: 2,
    margin: const EdgeInsets.only(bottom: 16),
    color: color,
  );
}

// ─── MESH PATTERN PAINTER ─────────────────────────────────────────
class _MeshPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 48.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}