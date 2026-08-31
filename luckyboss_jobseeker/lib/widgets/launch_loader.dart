import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'lucky_boss_brand_logo.dart';

/// The launch screen: wordmark, a progress rule, and a line of text that
/// changes while the app starts.
///
/// This is where the Lucky Boss mark belongs. It identifies the product once,
/// at open, when there is nothing else on screen competing for the space —
/// rather than occupying a band at the top of every scroll for the rest of the
/// session.
///
/// The rotating lines are the game-loading convention: something to read while
/// waiting. They are written as facts about how the product works, so the wait
/// teaches rather than just fills — and they are all true, which matters more
/// than it sounds. A loading screen that claims to be "analysing 10,000 jobs"
/// when it is opening a database connection is a small lie the user will
/// eventually catch.
class LaunchLoader extends StatefulWidget {
  const LaunchLoader({super.key});

  static const List<String> lines = [
    'Skills beat job titles — employers search for what you can do.',
    'A resume on file gets you shortlisted faster than one you send later.',
    'Match scores are built from your skills, not your years.',
    'Applications are free on Luckyboss unless an employer says otherwise.',
    'Every partner listing shows you who published it.',
    'Your expected salary is used for matching. Employers never see it.',
    'Adding one more skill changes what we can recommend you.',
    'Singapore, Malaysia and India — one profile, three markets.',
  ];

  @override
  State<LaunchLoader> createState() => _LaunchLoaderState();
}

class _LaunchLoaderState extends State<LaunchLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  late int _index;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Random start so a candidate opening the app twice does not read the same
    // line both times.
    _index = Random().nextInt(LaunchLoader.lines.length);
    _timer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % LaunchLoader.lines.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              // Centred as one block. The mark was small and floating a third
              // of the way down, with the rotating line stranded far below it,
              // so the screen read as two separate things rather than one.
              const Spacer(),
              LuckyBossBrandLogo(
                // Scales with the screen instead of a fixed 46px, so it fills
                // the space on a phone and does not balloon on a tablet.
                height: (MediaQuery.of(context).size.width * 0.22).clamp(72.0, 120.0),
              ),
              const SizedBox(height: 22),

              // An indeterminate sweep rather than a percentage. A fake
              // percentage that jumps from 20 to 100 is worse than no number.
              SizedBox(
                width: 140,
                height: 3,
                child: AnimatedBuilder(
                  animation: _bar,
                  builder: (context, _) => CustomPaint(
                    painter: _SweepBar(
                      progress: _bar.value,
                      track: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              SizedBox(
                height: 58,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text(
                    LaunchLoader.lines[_index],
                    key: ValueKey(_index),
                    textAlign: TextAlign.center,
                    style: AppTheme.sansRegular(
                        fontSize: 13.5, color: AppTheme.inkMutedOf(context)),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 26),
                child: Text(
                  'GROWTH PARTNER IN YOUR HIRING JOURNEY',
                  textAlign: TextAlign.center,
                  style: AppTheme.sansMedium(
                          fontSize: 9.5, color: AppTheme.inkFaintOf(context))
                      .copyWith(letterSpacing: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A short bar sliding left to right along a track.
class _SweepBar extends CustomPainter {
  final double progress;
  final Color track;

  const _SweepBar({required this.progress, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, radius),
      Paint()..color = track,
    );

    // Eases at both ends so the bar decelerates into each edge instead of
    // snapping back.
    final eased = Curves.easeInOut.transform(progress);
    final barWidth = size.width * 0.35;
    final left = (size.width + barWidth) * eased - barWidth;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left.clamp(0.0, size.width), 0,
            barWidth.clamp(0.0, size.width - left.clamp(0.0, size.width)),
            size.height),
        radius,
      ),
      Paint()..color = AppTheme.signalPositive,
    );
  }

  @override
  bool shouldRepaint(_SweepBar old) => old.progress != progress;
}
