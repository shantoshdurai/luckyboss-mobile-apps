import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// The home search bar, with a hint that cycles through real examples.
///
/// The rotation is doing a job, not decoration: a static "Search jobs" tells a
/// candidate nothing about what the box accepts. Cycling through a company, a
/// role and a city teaches the whole search surface in a few seconds without
/// spending a line of instructions on it.
///
/// This is a button, not a field. Tapping opens the full search screen where
/// keyword and location are separate inputs — trying to hold both in one bar is
/// what makes job search boxes ambiguous.
class RollingSearchBar extends StatefulWidget {
  final VoidCallback onTap;
  final List<String> hints;

  const RollingSearchBar({
    super.key,
    required this.onTap,
    this.hints = const [
      "Search for 'Flutter Developer'",
      "Search for 'Warehouse Supervisor'",
      "Search for 'jobs in Singapore'",
      "Search for 'Staff Nurse'",
      "Search for 'Luckyboss Global Tech'",
      "Search for 'Accounts Executive'",
    ],
  });

  @override
  State<RollingSearchBar> createState() => _RollingSearchBarState();
}

class _RollingSearchBarState extends State<RollingSearchBar> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % widget.hints.length);
    });
  }

  @override
  void dispose() {
    // Without this the timer keeps firing setState after the tab is disposed.
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Search jobs',
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: 20, color: AppTheme.inkMutedOf(context)),
              const SizedBox(width: 11),
              Expanded(
                child: ClipRect(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    // Rolls upward: the outgoing line exits through the top as
                    // the incoming one arrives from below.
                    transitionBuilder: (child, animation) {
                      final offset = Tween<Offset>(
                        begin: const Offset(0, 0.9),
                        end: Offset.zero,
                      ).animate(animation);
                      return ClipRect(
                        child: SlideTransition(
                          position: offset,
                          child: FadeTransition(opacity: animation, child: child),
                        ),
                      );
                    },
                    child: Text(
                      widget.hints[_index],
                      key: ValueKey(_index),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.sansRegular(
                          fontSize: 14, color: AppTheme.inkFaintOf(context)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
