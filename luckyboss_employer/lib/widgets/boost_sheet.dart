import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/employer_job.dart';
import '../models/job_boost.dart';
import '../providers/employer_provider.dart';

/// Buying a boost for one vacancy — spec §61.
///
/// Sir's ask, via Shantosh: *"if they need to hire for a certain job urgently
/// we can use like a booster... even if they posted many jobs, if they want a
/// specific one they can boost it to make it top."*
///
/// Three decisions worth keeping:
///
/// **The price is shown before the button, not after.** A boost is the first
/// thing in either app that takes money, and a company that finds out what it
/// cost from an invoice will not buy a second one.
///
/// **A boost has an end date, and it is stated.** Open-ended charges are how
/// job boards lose trust. [JobBoost.isActive] is computed from the dates, so it
/// stops on its own rather than needing something to switch it off.
///
/// **What the candidate sees is named here too.** The employer should know
/// exactly what appears on their vacancy — "Urgent hiring", not "Ad" — before
/// they pay for it.
class BoostSheet extends StatefulWidget {
  final EmployerJobModel job;

  const BoostSheet({super.key, required this.job});

  static Future<void> open(BuildContext context, EmployerJobModel job) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BoostSheet(job: job),
      );

  @override
  State<BoostSheet> createState() => _BoostSheetState();
}

class _BoostSheetState extends State<BoostSheet> {
  BoostType _type = BoostType.featured;
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployerProvider>();
    final job = provider.jobById(widget.job.id) ?? widget.job;
    final country = job.countryCode;

    if (job.isBoosted) return _ActiveBoost(job: job);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                children: [
                  Text('Boost this job',
                      style: AppTheme.serifTitle(
                          fontSize: 23, color: AppTheme.inkOf(context))),
                  const SizedBox(height: 5),
                  Text(
                    '${job.title} · ${job.location}',
                    style: AppTheme.sansRegular(
                        fontSize: 13.5, color: AppTheme.inkMutedOf(context)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Boosted jobs sit above everything else candidates see. '
                    'Useful when one vacancy matters more than the rest.',
                    style: AppTheme.sansRegular(
                        fontSize: 13, color: AppTheme.inkFaintOf(context)),
                  ),
                  const SizedBox(height: 20),

                  for (final type in BoostType.values)
                    _TypeOption(
                      type: type,
                      selected: _type == type,
                      price: BoostPricing.displayPrice(type, _days, country),
                      days: _days,
                      onTap: () => setState(() => _type = type),
                    ),

                  const SizedBox(height: 16),
                  Text('HOW LONG',
                      style: AppTheme.sansBold(
                              fontSize: 10,
                              color: AppTheme.inkFaintOf(context))
                          .copyWith(letterSpacing: 0.6)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final days in BoostPricing.durations)
                        InkWell(
                          onTap: () => setState(() => _days = days),
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: _days == days
                                  ? AppTheme.signalSource.withValues(alpha: 0.09)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: _days == days
                                    ? AppTheme.signalSource
                                    : Theme.of(context).dividerColor,
                                width: _days == days ? 1.4 : 1,
                              ),
                            ),
                            child: Text('$days days',
                                style: _days == days
                                    ? AppTheme.sansBold(
                                        fontSize: 13.5,
                                        color: AppTheme.signalSource)
                                    : AppTheme.sansMedium(
                                        fontSize: 13.5,
                                        color: AppTheme.inkOf(context))),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  // What the candidate will actually see. The employer is
                  // paying for prominence, and they should know the wording
                  // that comes with it before they buy.
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceOf(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WHAT CANDIDATES SEE',
                            style: AppTheme.sansBold(
                                    fontSize: 9,
                                    color: AppTheme.inkFaintOf(context))
                                .copyWith(letterSpacing: 0.5)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _BoostBadge(type: _type),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(job.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.sansBold(
                                      fontSize: 14,
                                      color: AppTheme.inkOf(context))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your job appears at the top with this mark for '
                          '$_days days.',
                          style: AppTheme.sansRegular(
                              fontSize: 12,
                              color: AppTheme.inkMutedOf(context)),
                        ),
                      ],
                    ),
                  ),

                  if (!provider.canPost) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: AppTheme.signalAttentionWash,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Your company needs to be verified before you can '
                        'boost a job.',
                        style: AppTheme.sansMedium(
                            fontSize: 13, color: AppTheme.signalAttention),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Price and action, pinned so the cost is on screen whatever has
            // been scrolled past.
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              BoostPricing.displayPrice(_type, _days, country),
                              style: AppTheme.serifTitle(
                                  fontSize: 22,
                                  color: AppTheme.inkOf(context))),
                          Text('${_type.label} · $_days days',
                              style: AppTheme.sansRegular(
                                  fontSize: 12,
                                  color: AppTheme.inkMutedOf(context))),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: provider.canPost ? _confirm : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13)),
                      ),
                      child: Text('Boost job',
                          style: AppTheme.sansBold(
                              fontSize: 14.5,
                              color: AppTheme.onInkOf(context))),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    final provider = context.read<EmployerProvider>();
    final price =
        BoostPricing.displayPrice(_type, _days, widget.job.countryCode);

    // Confirmed explicitly because it takes money. Everything else in these
    // apps saves on tap; this one should not.
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Boost for $price?',
            style: AppTheme.sansBold(
                fontSize: 16, color: AppTheme.inkOf(context))),
        content: Text(
          '${widget.job.title} will show as "${_type.label}" at the top of '
          'candidate results for $_days days. This is charged to your account.',
          style: AppTheme.sansRegular(
              fontSize: 14, color: AppTheme.inkMutedOf(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: AppTheme.sansMedium(
                    fontSize: 14, color: AppTheme.inkMutedOf(context))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Boost it',
                style: AppTheme.sansBold(
                    fontSize: 14, color: AppTheme.signalSource)),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final done = provider.boostJob(widget.job.id, _type, _days);
    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          done
              ? '${widget.job.title} is now ${_type.label.toLowerCase()} for '
                  '$_days days.'
              : 'Could not boost that job.',
          style: AppTheme.sansMedium(
              fontSize: 13, color: AppTheme.onInkOf(context)),
        ),
        backgroundColor:
            done ? AppTheme.signalPositive : AppTheme.signalClosed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final BoostType type;
  final bool selected;
  final String price;
  final int days;
  final VoidCallback onTap;

  const _TypeOption({
    required this.type,
    required this.selected,
    required this.price,
    required this.days,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.signalSource.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected
                  ? AppTheme.signalSource
                  : Theme.of(context).dividerColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 19,
                color: selected
                    ? AppTheme.signalSource
                    : AppTheme.inkFaintOf(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(type.label,
                              style: AppTheme.sansBold(
                                  fontSize: 14.5,
                                  color: AppTheme.inkOf(context))),
                        ),
                        Text(price,
                            style: AppTheme.sansBold(
                                fontSize: 13.5,
                                color: selected
                                    ? AppTheme.signalSource
                                    : AppTheme.inkMutedOf(context))),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(type.pitch,
                        style: AppTheme.sansRegular(
                            fontSize: 12.5,
                            color: AppTheme.inkMutedOf(context))),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

/// A boost already running: what it is, when it ends, and how to stop it.
class _ActiveBoost extends StatelessWidget {
  final EmployerJobModel job;

  const _ActiveBoost({required this.job});

  @override
  Widget build(BuildContext context) {
    final boost = job.boost!;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _BoostBadge(type: boost.type),
              const SizedBox(width: 10),
              Expanded(
                child: Text(job.title,
                    style: AppTheme.sansBold(
                        fontSize: 16, color: AppTheme.inkOf(context))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            boost.daysRemaining == 0
                ? 'Ends today.'
                : '${boost.daysRemaining} days left of '
                    '${boost.endsAt.difference(boost.startsAt).inDays}.',
            style: AppTheme.sansMedium(
                fontSize: 14, color: AppTheme.inkOf(context)),
          ),
          const SizedBox(height: 4),
          Text('Paid ${boost.currency} ${boost.amount}',
              style: AppTheme.sansRegular(
                  fontSize: 12.5, color: AppTheme.inkMutedOf(context))),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                context.read<EmployerProvider>().cancelBoost(job.id);
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
              ),
              // Says plainly that stopping early does not refund. Discovering
              // that afterwards is how a paid feature earns a complaint.
              child: Text('Stop boosting (no refund)',
                  style: AppTheme.sansBold(
                      fontSize: 14, color: AppTheme.signalClosed)),
            ),
          ),
        ],
      ),
    );
  }
}

/// The mark a boosted job carries, in both apps.
class _BoostBadge extends StatelessWidget {
  final BoostType type;

  const _BoostBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (tint, wash, icon) = switch (type) {
      BoostType.urgent => (
          AppTheme.signalClosed,
          AppTheme.signalClosedWash,
          Icons.bolt
        ),
      BoostType.sponsored => (
          AppTheme.signalSource,
          AppTheme.signalSourceWash,
          Icons.campaign_outlined
        ),
      BoostType.featured => (
          AppTheme.signalAttention,
          AppTheme.signalAttentionWash,
          Icons.star_rounded
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration:
          BoxDecoration(color: wash, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tint),
          const SizedBox(width: 4),
          Text(type.label,
              style: AppTheme.sansBold(fontSize: 10.5, color: tint)),
        ],
      ),
    );
  }
}

/// The badge, for use outside this sheet.
class BoostBadge extends StatelessWidget {
  final BoostType type;

  const BoostBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) => _BoostBadge(type: type);
}
