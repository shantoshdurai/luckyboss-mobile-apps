import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Fades and lifts a child into place the first time it is built.
///
/// The same entrance the Lucky Boss website uses on its home sections. It runs
/// once, on first build — not on every scroll pass. Re-animating rows as they
/// cross the viewport looks lively in a demo and becomes motion sickness on a
/// list someone is actually reading.
///
/// [index] staggers siblings so a section arrives as a sequence rather than a
/// single block. Capped, because a stagger that keeps growing means the twelfth
/// card is still waiting when the user has already scrolled past it.
class FadeInUp extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;

  const FadeInUp({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 420),
  });

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);

  late final Animation<double> _opacity =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);

  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: (widget.index.clamp(0, 6)) * 70);
    Future<void>.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _offset, child: widget.child),
      );
}

/// Profile completion as a ring.
///
/// Replaces a full-width progress bar that ate a whole band of the home screen
/// to say one number. A ring says the same thing in a corner, and the space it
/// gives back goes to job recommendations — which is what the screen is for.
///
/// The whole tile is tappable through to the profile, because a completion
/// score with no route to fixing it is only a scold.
class ProfileCompletionRing extends StatelessWidget {
  final int percent;
  final String nextAction;
  final VoidCallback onTap;

  const ProfileCompletionRing({
    super.key,
    required this.percent,
    required this.nextAction,
    required this.onTap,
  });

  Color get _tone => percent >= 80
      ? AppTheme.signalPositive
      : percent >= 50
          ? AppTheme.signalProgress
          : AppTheme.signalAttention;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        color: Theme.of(context).cardColor,
        child: Row(
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: CircularProgressIndicator(
                      value: percent / 100,
                      strokeWidth: 4.5,
                      backgroundColor: Theme.of(context).dividerColor,
                      valueColor: AlwaysStoppedAnimation(_tone),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text('$percent%',
                      style: AppTheme.sansBold(fontSize: 13.5, color: _tone)),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your profile',
                      style: AppTheme.sansBold(
                          fontSize: 14.5, color: AppTheme.inkOf(context))),
                  const SizedBox(height: 3),
                  Text(
                    nextAction,
                    style: AppTheme.sansRegular(
                        fontSize: 12.5, color: AppTheme.inkMutedOf(context)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: AppTheme.inkFaintOf(context)),
          ],
        ),
      ),
    );
  }
}

/// Section heading with an optional count and a "View all" route out.
class HomeSectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final String? note;
  final VoidCallback? onViewAll;

  const HomeSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.note,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 26, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: AppTheme.serifTitle(
                            fontSize: 20, color: AppTheme.inkOf(context)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: 7),
                      Text('($count)',
                          style: AppTheme.sansMedium(
                              fontSize: 15, color: AppTheme.inkFaintOf(context))),
                    ],
                  ],
                ),
                if (note != null) ...[
                  const SizedBox(height: 2),
                  Text(note!,
                      style: AppTheme.sansRegular(
                          fontSize: 12, color: AppTheme.inkFaintOf(context))),
                ],
              ],
            ),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('View all',
                  style: AppTheme.sansBold(
                      fontSize: 13.5, color: AppTheme.signalSource)),
            ),
        ],
      ),
    );
  }
}

/// Employer mark.
///
/// Employers upload a real logo from the portal; until one exists this renders a
/// monogram derived from the company name. Deterministic tinting means the same
/// employer always gets the same colour, so the mark still works as a visual
/// anchor when scanning a list — a grey placeholder square would not.
class CompanyMark extends StatelessWidget {
  final String companyName;
  final String? logoUrl;
  final double size;

  const CompanyMark({
    super.key,
    required this.companyName,
    this.logoUrl,
    this.size = 44,
  });

  static const List<Color> _tints = [
    AppTheme.signalSource,
    AppTheme.signalProgress,
    AppTheme.signalPositive,
    AppTheme.signalAttention,
  ];

  String get _initials {
    final words = companyName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'LB';
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  Color get _tint =>
      _tints[companyName.codeUnits.fold(0, (a, b) => a + b) % _tints.length];

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.26);

    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          logoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, e, s) => _monogram(context, radius),
        ),
      );
    }
    return _monogram(context, radius);
  }

  Widget _monogram(BuildContext context, BorderRadius radius) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _tint.withValues(alpha: 0.12),
          borderRadius: radius,
          border: Border.all(color: _tint.withValues(alpha: 0.25)),
        ),
        alignment: Alignment.center,
        child: Text(
          _initials,
          style: AppTheme.sansBold(fontSize: size * 0.34, color: _tint),
        ),
      );
}

/// The end of a scrolling screen.
///
/// A list that simply stops leaves the reader unsure whether it ended or failed
/// to load. This states plainly that there is nothing more, and offers the one
/// action worth taking from the bottom of the page.
class ListEndCap extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ListEndCap({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 42),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 2,
            color: Theme.of(context).dividerColor,
          ),
          const SizedBox(height: 18),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.sansRegular(fontSize: 13, color: AppTheme.inkFaintOf(context)),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).dividerColor),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              ),
              child: Text(actionLabel!,
                  style: AppTheme.sansBold(
                      fontSize: 13.5, color: AppTheme.inkOf(context))),
            ),
          ],
        ],
      ),
    );
  }
}
