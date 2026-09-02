import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/employer_insights_service.dart';

/// How one vacancy is doing, and what its boost bought.
///
/// The portal sold a boost (spec §61) and then reported nothing at all, so an
/// employer could not answer the only question a paying customer asks: was that
/// worth it? Filling the gap with plausible-looking numbers was the one option
/// not available — on a paid feature an invented figure is a lie, and the first
/// employer to check it against their applicant count stops believing anything
/// else on the screen.
///
/// So every number here is measured, and where nothing has been measured the
/// screen says so in words instead of showing a confident zero.
class JobInsightsScreen extends StatefulWidget {
  final int jobId;
  final String jobTitle;

  const JobInsightsScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<JobInsightsScreen> createState() => _JobInsightsScreenState();
}

class _JobInsightsScreenState extends State<JobInsightsScreen> {
  JobInsights? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await EmployerInsightsService.forJob(widget.jobId);
    if (mounted) {
      setState(() {
        _data = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paperOf(context),
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        title: Text('Performance',
            style:
                AppTheme.sansBold(fontSize: 17, color: AppTheme.inkOf(context))),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _data == null
              ? _offline(context)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      Text(widget.jobTitle,
                          style: AppTheme.serifTitle(
                              fontSize: 24, color: AppTheme.inkOf(context))),
                      const SizedBox(height: 18),
                      _headlineNumbers(context, _data!),
                      const SizedBox(height: 20),
                      _viewsChart(context, _data!),
                      const SizedBox(height: 20),
                      _boostSection(context, _data!),
                    ],
                  ),
                ),
    );
  }

  Widget _offline(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'These numbers live on the Luckyboss server. Reconnect to see how '
            'this vacancy is doing.',
            textAlign: TextAlign.center,
            style: AppTheme.sansRegular(
                fontSize: 14, color: AppTheme.inkMutedOf(context)),
          ),
        ),
      );

  Widget _headlineNumbers(BuildContext context, JobInsights d) => Row(
        children: [
          Expanded(child: _stat(context, 'Views', '${d.views}')),
          const SizedBox(width: 10),
          Expanded(child: _stat(context, 'Applications', '${d.applications}')),
          const SizedBox(width: 10),
          Expanded(
            child: _stat(
              context,
              'Apply rate',
              // Null, not 0%. "Nobody has looked" and "nobody applied" are
              // different facts, and a 0% rate on a vacancy nobody has seen
              // reads as a failing listing when it is simply new.
              d.applyRate == null ? '—' : '${d.applyRate!.toStringAsFixed(0)}%',
              hint: d.applyRate == null ? 'No views yet' : null,
            ),
          ),
        ],
      );

  Widget _stat(BuildContext context, String label, String value,
          {String? hint}) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: AppTheme.sansBold(
                    fontSize: 22, color: AppTheme.inkOf(context))),
            const SizedBox(height: 3),
            Text(label,
                style: AppTheme.sansMedium(
                    fontSize: 12, color: AppTheme.inkMutedOf(context))),
            if (hint != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(hint,
                    style: AppTheme.sansRegular(
                        fontSize: 10.5, color: AppTheme.inkMutedOf(context))),
              ),
          ],
        ),
      );

  /// Fourteen days of views as bars. Drawn from real daily counts, so a flat
  /// row of empty columns is the honest picture of a vacancy nobody has opened.
  Widget _viewsChart(BuildContext context, JobInsights d) {
    final series = d.dailyViews;
    final peak = series.isEmpty
        ? 0
        : series.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Views · last 14 days',
              style: AppTheme.sansBold(
                  fontSize: 13, color: AppTheme.inkOf(context))),
          const SizedBox(height: 14),
          SizedBox(
            height: 74,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final v in series)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Container(
                        height: peak == 0 ? 2 : (v / peak * 70).clamp(2, 70),
                        decoration: BoxDecoration(
                          color: v == 0
                              ? Theme.of(context).dividerColor
                              : AppTheme.signalPositive,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            peak == 0
                ? 'No views recorded in this period.'
                : 'Busiest day: $peak view${peak == 1 ? '' : 's'}',
            style: AppTheme.sansRegular(
                fontSize: 11.5, color: AppTheme.inkMutedOf(context)),
          ),
        ],
      ),
    );
  }

  Widget _boostSection(BuildContext context, JobInsights d) {
    final b = d.boost;

    if (b == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Not boosted',
                style: AppTheme.sansBold(
                    fontSize: 14, color: AppTheme.inkOf(context))),
            const SizedBox(height: 5),
            Text(
              'Boosting moves this vacancy to the top of the feed for a set '
              'number of days. You will see exactly what it changed here.',
              style: AppTheme.sansRegular(
                  fontSize: 13, color: AppTheme.inkMutedOf(context)),
            ),
          ],
        ),
      );
    }

    final lift = b.liftPercent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: b.active
                ? AppTheme.signalPositive
                : Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${b.type[0].toUpperCase()}${b.type.substring(1)} boost',
                  style: AppTheme.sansBold(
                      fontSize: 15, color: AppTheme.inkOf(context))),
              const Spacer(),
              Text(
                b.active ? '${b.daysRemaining} days left' : 'Finished',
                style: AppTheme.sansMedium(
                    fontSize: 12,
                    color: b.active
                        ? AppTheme.signalPositive
                        : AppTheme.inkMutedOf(context)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _boostRow(context, 'Views while boosted', '${b.viewsDuring}'),
          const Divider(height: 20),
          _boostRow(context, 'Applications while boosted',
              '${b.applicationsDuring}'),
          const Divider(height: 20),
          _boostRow(context, 'You paid',
              '${b.currency} ${(b.amount / 100).toStringAsFixed(2)}'),
          const SizedBox(height: 14),

          // The comparison, stated for what it is. Without a control group the
          // only honest baseline is the same number of days immediately before
          // the boost — and when the vacancy was not live that long, there is
          // no baseline and the screen says so rather than inventing a rise
          // against a period the job did not exist in.
          if (!b.comparable)
            Text(
              'This vacancy was posted too recently to compare against a '
              'period before the boost.',
              style: AppTheme.sansRegular(
                  fontSize: 12, color: AppTheme.inkMutedOf(context)),
            )
          else if (lift == null)
            Text(
              'It had no views in the days before the boost, so there is '
              'nothing to measure the change against.',
              style: AppTheme.sansRegular(
                  fontSize: 12, color: AppTheme.inkMutedOf(context)),
            )
          else
            Text(
              lift >= 0
                  ? 'That is $lift% more views than the ${b.viewsBefore} in the '
                      'same number of days before the boost.'
                  : 'That is ${lift.abs()}% fewer views than the '
                      '${b.viewsBefore} in the same number of days before it.',
              style: AppTheme.sansMedium(
                  fontSize: 12.5,
                  color: lift >= 0
                      ? AppTheme.signalPositive
                      : AppTheme.inkMutedOf(context)),
            ),
        ],
      ),
    );
  }

  Widget _boostRow(BuildContext context, String label, String value) => Row(
        children: [
          Expanded(
            child: Text(label,
                style: AppTheme.sansRegular(
                    fontSize: 13.5, color: AppTheme.inkMutedOf(context))),
          ),
          Text(value,
              style: AppTheme.sansBold(
                  fontSize: 14, color: AppTheme.inkOf(context))),
        ],
      );
}
