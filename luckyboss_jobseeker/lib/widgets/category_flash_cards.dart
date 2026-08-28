import 'package:flutter/material.dart';

import '../core/constants/app_data.dart';
import '../core/theme/app_theme.dart';

/// A horizontally scrolling strip of job categories, dropped into the feed.
///
/// Its job is to break the texture. A feed of identical vertical cards reads as
/// one undifferentiated block no matter how good each card is — the eye stops
/// registering boundaries. A strip that scrolls sideways interrupts that, and
/// gives a candidate whose recommendations are thin a way out of the feed
/// without going to search first.
class CategoryFlashCards extends StatelessWidget {
  final ValueChanged<String> onPick;

  const CategoryFlashCards({super.key, required this.onPick});

  /// Icon and tint per category. Colour here is carrying meaning — it is how
  /// the eye tells warehouse work from nursing at a glance while scrolling.
  static const Map<String, (IconData, Color)> _style = {
    'IT & Software': (Icons.code, AppTheme.signalSource),
    'Logistics & Warehouse': (Icons.local_shipping_outlined, AppTheme.signalAttention),
    'Engineering & Tech': (Icons.precision_manufacturing_outlined, AppTheme.signalProgress),
    'Healthcare & Nursing': (Icons.medical_services_outlined, AppTheme.signalClosed),
    'Finance & Banking': (Icons.account_balance_outlined, AppTheme.signalPositive),
  };

  @override
  Widget build(BuildContext context) {
    final categories =
        AppData.categories.where((c) => c != 'All Roles').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 2),
          child: Text('Explore by category',
              style: AppTheme.serifTitle(fontSize: 19, color: AppTheme.inkOf(context))),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          child: Text('Jump straight to the work you do.',
              style: AppTheme.sansRegular(fontSize: 12.5, color: AppTheme.inkFaintOf(context))),
        ),
        SizedBox(
          height: 108,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final category = categories[i];
              final (icon, tint) =
                  _style[category] ?? (Icons.work_outline, AppTheme.signalSource);

              return InkWell(
                onTap: () => onPick(category),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 132,
                  margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                  padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tint.withValues(alpha: 0.22)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 21, color: tint),
                      const Spacer(),
                      Text(
                        category,
                        style: AppTheme.sansBold(fontSize: 12.5, color: tint),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
