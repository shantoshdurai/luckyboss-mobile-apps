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
  final String selected;
  final ValueChanged<String> onChanged;

  const WorkCategoryStep({
    super.key,
    required this.selected,
    required this.onChanged,
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
          'Pick the one closest to your work. The next questions are about it, '
          'and you can add other kinds of work later from your profile.',
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

            return _CategoryTile(
              category: category,
              selected: category.name == selected,
              onTap: () => onChanged(category.name),
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
                'Not sure? Choose the closest one — jobs from every category '
                'still show in search.',
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
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
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
            opacity: 1,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
