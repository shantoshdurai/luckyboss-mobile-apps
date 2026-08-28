import 'package:flutter/material.dart';

import '../../../core/constants/app_data.dart';
import '../../../core/theme/app_theme.dart';

/// The first question in onboarding: what kind of work?
///
/// It is a grid of pictures with short labels, not a dropdown, and that is the
/// point. A large share of the people Lucky Boss places — site workers, factory
/// labour, drivers, domestic helpers — are not reading a phone screen in their
/// first language, and several are not reading it comfortably at all. A
/// construction hat they can recognise in half a second does more work than any
/// sentence on this screen.
///
/// The order is the spec's (§58): Construction, Manufacturing, Warehouse first.
/// It used to be IT & Software first with five categories in total, which told
/// every other kind of worker, before they had answered a single question, that
/// this app was not built for them.
class WorkCategoryStep extends StatelessWidget {
  /// Every kind of work the candidate will take, first one primary.
  final List<String> selected;
  final ValueChanged<String> onChanged;

  /// How many they may pick.
  final int maxSelections;

  const WorkCategoryStep({
    super.key,
    required this.selected,
    required this.onChanged,
    this.maxSelections = 3,
  });

  @override
  Widget build(BuildContext context) {
    final categories = AppData.workCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What work are you looking for?',
            style: AppTheme.serifTitle(fontSize: 26, color: AppTheme.inkOf(context))),
        const SizedBox(height: 6),
        Text(
          selected.isEmpty
              ? 'Pick the one closest to your work. You can add up to '
                  '$maxSelections if you would take more than one.'
              : 'Add another if you would take that work too — '
                  '${selected.length} of $maxSelections chosen.',
          style: AppTheme.sansRegular(
              fontSize: 14, color: AppTheme.inkMutedOf(context)),
        ),
        const SizedBox(height: 22),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            // Tall enough for a two-line label at large system font sizes. A
            // clipped category name is worse than a shorter grid.
            childAspectRatio: 1.28,
          ),
          itemBuilder: (context, i) {
            final category = categories[i];
            final isSelected = selected.contains(category.name);
            // Full, and this one is not already in — greyed rather than hidden,
            // so it is obvious the limit is the reason and not a bug.
            final blocked = !isSelected && selected.length >= maxSelections;

            return _CategoryTile(
              category: category,
              selected: isSelected,
              // The first choice decides which questions come next, so it is
              // worth showing which one that is.
              primary: selected.isNotEmpty && selected.first == category.name,
              blocked: blocked,
              onTap: blocked ? null : () => onChanged(category.name),
            );
          },
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 15, color: AppTheme.inkFaintOf(context)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selected.length >= maxSelections
                    ? 'That is the most you can pick. Tap one again to swap it.'
                    : 'Not sure? Choose the closest one — jobs from every '
                        'category still show in search.',
                style: AppTheme.sansRegular(
                    fontSize: 12.5, color: AppTheme.inkFaintOf(context)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final WorkCategory category;
  final bool selected;

  /// The first choice, which decides the rest of the wizard's questions.
  final bool primary;

  /// Unselectable because the limit is reached.
  final bool blocked;

  final VoidCallback? onTap;

  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
    this.primary = false,
    this.blocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.signalSource;

    return Semantics(
      button: true,
      selected: selected,
      label: category.name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.08)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : Theme.of(context).dividerColor,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Opacity(
            opacity: blocked ? 0.4 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      category.icon,
                      size: 26,
                      color: selected ? accent : AppTheme.inkOf(context),
                    ),
                    const Spacer(),
                    if (selected)
                      Icon(Icons.check_circle, size: 19, color: accent),
                  ],
                ),
                const Spacer(),
                Text(
                  category.name,
                  style: AppTheme.sansBold(
                    fontSize: 13.5,
                    color: selected ? accent : AppTheme.inkOf(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (primary)
                  Text('Main work',
                      style: AppTheme.sansMedium(fontSize: 10, color: accent)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
