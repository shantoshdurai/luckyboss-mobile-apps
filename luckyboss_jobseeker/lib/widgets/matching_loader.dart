import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// The loading state shown while recommendations are being assembled.
///
/// A bare spinner says "waiting". This says what is being done, and steps
/// through the actual stages of matching — reading the profile, scanning
/// vacancies, scoring, ranking. The perceived wait is shorter when the wait is
/// legible, and the sequence doubles as an explanation of how matching works.
///
/// The lines are honest about the real pipeline. Inventing steps to pad the
/// animation would make it theatre.
class MatchingLoader extends StatefulWidget {
  final String? skillHint;

  const MatchingLoader({super.key, this.skillHint});

  @override
  State<MatchingLoader> createState() => _MatchingLoaderState();
}

class _MatchingLoaderState extends State<MatchingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  int _stage = 0;
  Timer? _timer;

  List<String> get _stages => [
        widget.skillHint == null || widget.skillHint!.isEmpty
            ? 'Reading your profile'
            : 'Reading your profile — ${widget.skillHint}',
        'Scanning live vacancies',
        'Scoring each against your skills',
        'Ranking your best matches',
      ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (!mounted) return;
      // Holds on the last stage rather than looping — a cycle that restarts
      // implies the work restarted too.
      if (_stage < _stages.length - 1) setState(() => _stage++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: AnimatedBuilder(
              animation: _sweep,
              builder: (context, _) => CustomPaint(
                painter: _SweepPainter(
                  progress: _sweep.value,
                  track: Theme.of(context).dividerColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              _stages[_stage],
              key: ValueKey(_stage),
              textAlign: TextAlign.center,
              style: AppTheme.sansMedium(
                  fontSize: 14, color: AppTheme.inkOf(context)),
            ),
          ),
          const SizedBox(height: 18),
          // Progress dots double as a count of how much is left, so the wait
          // has a visible end.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_stages.length, (i) {
              final done = i <= _stage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: done ? 18 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: done
                      ? AppTheme.signalPositive
                      : Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// A rotating arc in the brand's positive signal colour.
class _SweepPainter extends CustomPainter {
  final double progress;
  final Color track;

  const _SweepPainter({required this.progress, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final centre = rect.center;
    final radius = size.width / 2 - 3;

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = track,
    );

    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      progress * 6.28319,
      // Sweep length breathes so the arc does not read as a rigid spinner.
      1.4 + (0.6 * (1 - (progress - 0.5).abs() * 2)),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = AppTheme.signalPositive,
    );
  }

  @override
  bool shouldRepaint(_SweepPainter old) => old.progress != progress;
}
