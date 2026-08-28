import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_data.dart';
import '../../core/theme/app_theme.dart';
import '../../models/job_model.dart';
import '../../providers/job_seeker_provider.dart';
import '../../widgets/city_field.dart';
import '../../widgets/home_components.dart';
import '../../widgets/job_card.dart';
import '../../widgets/ledger_components.dart';
import '../../widgets/lucky_boss_brand_logo.dart';
import 'job_detail_screen.dart';

/// Active filters applied to a result set.
///
/// A value object rather than loose fields on the widget so the filter sheet
/// can hand back a whole new set at once — half-applied filters are how a
/// result count ends up disagreeing with the list under it.
class JobFilters {
  final Set<String> workModes;
  final Set<String> categories;
  final Set<String> countries;
  final String? experience;

  const JobFilters({
    this.workModes = const {},
    this.categories = const {},
    this.countries = const {},
    this.experience,
  });

  int get activeCount =>
      workModes.length +
      categories.length +
      countries.length +
      (experience == null ? 0 : 1);

  bool get isEmpty => activeCount == 0;

  JobFilters copyWith({
    Set<String>? workModes,
    Set<String>? categories,
    Set<String>? countries,
    String? experience,
    bool clearExperience = false,
  }) =>
      JobFilters(
        workModes: workModes ?? this.workModes,
        categories: categories ?? this.categories,
        countries: countries ?? this.countries,
        experience: clearExperience ? null : (experience ?? this.experience),
      );

  bool matches(JobModel job) {
    if (workModes.isNotEmpty && !workModes.contains(job.workMode)) return false;
    if (categories.isNotEmpty && !categories.contains(job.category)) return false;
    if (countries.isNotEmpty && !countries.contains(job.countryCode)) return false;
    return true;
  }
}

/// Job search — keyword and location, then results with filters.
///
/// Split into two states on one screen rather than two screens: the entry state
/// shows recent searches and quick routes in, and the same screen becomes the
/// result list once a search runs. Keeping it together means the search bar
/// stays put and refining a query never involves a back navigation.
class JobSearchScreen extends StatefulWidget {
  /// Pre-fills and immediately runs a search — used when arriving from a
  /// suggestion chip elsewhere in the app.
  final String? initialQuery;

  const JobSearchScreen({super.key, this.initialQuery});

  @override
  State<JobSearchScreen> createState() => _JobSearchScreenState();
}

class _JobSearchScreenState extends State<JobSearchScreen> {
  final _keywordController = TextEditingController();
  final _locationController = TextEditingController();
  final _keywordFocus = FocusNode();

  bool _searched = false;
  JobFilters _filters = const JobFilters();

  /// Session-scoped. Persisting these belongs with the rest of the profile
  /// sync, not in local storage where they would outlive a sign-out.
  static final List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _keywordController.text = widget.initialQuery!.trim();
      _searched = true;
    }
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _locationController.dispose();
    _keywordFocus.dispose();
    super.dispose();
  }

  void _runSearch() {
    final keyword = _keywordController.text.trim();
    final location = _locationController.text.trim();

    if (keyword.isEmpty && location.isEmpty && _filters.isEmpty) {
      // Nothing to search on. Rather than showing the entire job list as though
      // it were a result, say what is missing.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter a skill, role, company or location to search.',
              style: AppTheme.sansMedium(fontSize: 13, color: AppTheme.onInkOf(context))),
          backgroundColor: AppTheme.signalAttention,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final label = [keyword, location].where((s) => s.isNotEmpty).join(' · ');
    if (label.isNotEmpty) {
      _recentSearches.remove(label);
      _recentSearches.insert(0, label);
      if (_recentSearches.length > 6) _recentSearches.removeLast();
    }

    _keywordFocus.unfocus();
    setState(() => _searched = true);
  }

  List<JobModel> _results(JobSeekerProvider provider) {
    final keyword = _keywordController.text.trim().toLowerCase();
    final location = _locationController.text.trim().toLowerCase();

    return provider.searchableJobs.where((job) {
      if (!_filters.matches(job)) return false;

      if (keyword.isNotEmpty) {
        final haystack = '${job.title} ${job.companyName} ${job.category} '
                '${job.requiredSkills.join(" ")}'
            .toLowerCase();
        if (!haystack.contains(keyword)) return false;
      }

      if (location.isNotEmpty) {
        final where = '${job.location} ${job.countryCode}'.toLowerCase();
        if (!where.contains(location)) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobSeekerProvider>();

    return Scaffold(
      backgroundColor: AppTheme.paperOf(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _searchHeader(),
            // Filters sit with the query that produced the results, not at the
            // bottom of the screen away from it — and only appear once there is
            // a result set to narrow. Before a search they would be filtering
            // nothing.
            if (_searched) _filterBar(),
            Expanded(
              child: _searched ? _resultsView(provider) : _entryView(),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------

  Widget _searchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          Row(
            children: [
              if (_searched)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.arrow_back, size: 22, color: AppTheme.inkOf(context)),
                  // Returns to the entry state rather than leaving the tab, so
                  // refining a search never drops the candidate out of search.
                  onPressed: () => setState(() => _searched = false),
                ),
              if (_searched) const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _searched ? 'Results' : 'Search jobs',
                  style: AppTheme.serifTitle(
                      fontSize: _searched ? 20 : 26, color: AppTheme.inkOf(context)),
                ),
              ),
              // The space beside the title was empty. The wordmark belongs
              // somewhere on every top-level tab, and this is the one spot on
              // search that is not carrying information.
              if (!_searched)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: LuckyBossBrandLogo(height: 22),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _field(
            controller: _keywordController,
            focusNode: _keywordFocus,
            hint: 'Skills, designations, companies',
            icon: Icons.search,
          ),
          const SizedBox(height: 10),
          // Instant, bundled suggestions — no request per keystroke.
          CityField(
            controller: _locationController,
            hint: 'City or location',
            onSubmitted: (_) => _runSearch(),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _runSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryFillOf(context),
                foregroundColor: AppTheme.onPrimaryFillOf(context),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Search jobs',
                  style: AppTheme.sansBold(fontSize: 14.5, color: AppTheme.onInkOf(context))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    VoidCallback? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => (onSubmitted ?? _runSearch)(),
      style: AppTheme.sansMedium(fontSize: 14.5, color: AppTheme.inkOf(context)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.sansRegular(fontSize: 14.5, color: AppTheme.inkFaintOf(context)),
        prefixIcon: Icon(icon, size: 19, color: AppTheme.inkFaintOf(context)),
        filled: true,
        fillColor: AppTheme.paperOf(context),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------

  /// Wraps everything that is not a JobCard in the 16px gutter.
  ///
  /// The list itself carries no horizontal padding, because JobCard already has
  /// a 16px margin — nesting the two made the cards here render narrower than
  /// the identical cards on home.
  Widget _gutter(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: child,
      );

  Widget _entryView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 30),
      children: [
        if (_recentSearches.isNotEmpty) ...[
          _gutter(Text('Recent searches',
              style: AppTheme.sansBold(fontSize: 13.5, color: AppTheme.inkOf(context)))),
          const SizedBox(height: 10),
          ..._recentSearches.map((s) => InkWell(
                onTap: () {
                  final parts = s.split(' · ');
                  _keywordController.text = parts.first;
                  _locationController.text = parts.length > 1 ? parts[1] : '';
                  _runSearch();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 18, color: AppTheme.inkFaintOf(context)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(s,
                            style: AppTheme.sansMedium(
                                fontSize: 14, color: AppTheme.inkOf(context))),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 26),
        ],
        _gutter(Text('Browse by category',
            style: AppTheme.sansBold(fontSize: 13.5, color: AppTheme.inkOf(context)))),
        const SizedBox(height: 12),
        _gutter(Wrap(
          spacing: 9,
          runSpacing: 10,
          children: AppData.categories
              .where((c) => c != 'All Roles')
              .map((c) => InkWell(
                    onTap: () {
                      setState(() => _filters =
                          _filters.copyWith(categories: {c}));
                      _runSearch();
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Text(c,
                          style: AppTheme.sansMedium(
                              fontSize: 13.5, color: AppTheme.inkOf(context))),
                    ),
                  ))
              .toList(),
        )),
        const SizedBox(height: 26),
        _gutter(Text('Browse by location',
            style: AppTheme.sansBold(fontSize: 13.5, color: AppTheme.inkOf(context)))),
        const SizedBox(height: 12),
        _gutter(Wrap(
          spacing: 9,
          runSpacing: 10,
          children: AppData.countries
              .map((c) => InkWell(
                    onTap: () {
                      setState(() => _filters =
                          _filters.copyWith(countries: {c['code']!}));
                      _runSearch();
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(c['flag']!,
                              style: const TextStyle(fontSize: 15)),
                          const SizedBox(width: 7),
                          Text(c['name']!,
                              style: AppTheme.sansMedium(
                                  fontSize: 13.5, color: AppTheme.inkOf(context))),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        )),

        // Search opened cold used to be two empty fields and nothing else.
        // Showing what we would recommend anyway makes the tab useful before
        // the candidate has typed a character.
        Builder(builder: (context) {
          final recommended =
              context.watch<JobSeekerProvider>().recommendedJobs.take(3).toList();
          if (recommended.isEmpty) return const SizedBox(height: 20);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              HomeSectionHeader(
                title: 'Recommended for you',
                note: 'Based on your profile',
              ),
              // No wrapper: JobCard's own margin gives the correct gutter.
              ...recommended.map((j) => JobCard(job: j)),
              const SizedBox(height: 10),
            ],
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------

  Widget _resultsView(JobSeekerProvider provider) {
    final results = _results(provider);

    if (results.isEmpty) {
      return LedgerEmptyState(
        headline: 'No jobs match that search',
        explanation: _filters.isEmpty
            ? 'Try a broader keyword, or search by category instead.'
            : 'Try removing a filter — ${_filters.activeCount} '
                '${_filters.activeCount == 1 ? "is" : "are"} currently applied.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      itemCount: results.length + 1,
      separatorBuilder: (_, i) => i == 0
          ? const SizedBox.shrink()
          : Divider(height: 24, color: Theme.of(context).dividerColor),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '${results.length} ${results.length == 1 ? "result" : "results"}',
              style: AppTheme.sansBold(fontSize: 13, color: AppTheme.inkMutedOf(context)),
            ),
          );
        }
        final job = results[i - 1];
        return _resultCard(job, provider);
      },
    );
  }

  Widget _resultCard(JobModel job, JobSeekerProvider provider) {
    final match = provider.matchScoreFor(job);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title,
                    style: AppTheme.sansBold(
                        fontSize: 15, color: AppTheme.inkOf(context))),
                const SizedBox(height: 3),
                Text('${job.companyName} · ${job.location}',
                    style: AppTheme.sansRegular(
                        fontSize: 12.5, color: AppTheme.inkMutedOf(context))),
                const SizedBox(height: 8),
                Text(
                  '${job.currency} ${job.minSalary} – ${job.maxSalary} / mo',
                  style: AppTheme.sansMedium(
                      fontSize: 12.5, color: AppTheme.inkOf(context)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // MatchCell renders its own unscored state, so a null score is
              // passed straight through rather than branched on here.
              MatchCell(score: match),
              const SizedBox(height: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  provider.isSaved(job.id)
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  size: 20,
                  color: provider.isSaved(job.id)
                      ? AppTheme.signalPositive
                      : AppTheme.inkFaintOf(context),
                ),
                onPressed: () => provider.toggleSaved(job.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------

  /// The filter bar, pinned to the bottom of the results.
  ///
  /// Bottom rather than top because it is reached with a thumb while scrolling
  /// results, which is exactly when a candidate decides to narrow them.
  Widget _filterBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: SizedBox(
          height: 54,
          child: Row(
            children: [
              const SizedBox(width: 12),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune, size: 22),
                    color: _filters.isEmpty
                        ? AppTheme.inkOf(context)
                        : AppTheme.signalPositive,
                    onPressed: _openFilterSheet,
                  ),
                  if (!_filters.isEmpty)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.signalPositive,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${_filters.activeCount}',
                          style: AppTheme.sansBold(
                              fontSize: 9, color: AppTheme.onInkOf(context)),
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  children: [
                    _filterChip('Work mode', _filters.workModes.isNotEmpty),
                    _filterChip('Category', _filters.categories.isNotEmpty),
                    _filterChip('Location', _filters.countries.isNotEmpty),
                    if (!_filters.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 11),
                        child: TextButton(
                          onPressed: () =>
                              setState(() => _filters = const JobFilters()),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: Size.zero,
                          ),
                          child: Text('Clear all',
                              style: AppTheme.sansBold(
                                  fontSize: 13, color: AppTheme.signalClosed)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool active) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: InkWell(
          onTap: _openFilterSheet,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppTheme.signalPositiveWash : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active
                    ? AppTheme.signalPositive
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: AppTheme.sansMedium(
                        fontSize: 13,
                        color: active
                            ? AppTheme.signalPositive
                            : AppTheme.inkOf(context))),
                const SizedBox(width: 4),
                Icon(Icons.expand_more,
                    size: 15,
                    color: active ? AppTheme.signalPositive : AppTheme.inkFaintOf(context)),
              ],
            ),
          ),
        ),
      );

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        // A local copy so Cancel genuinely cancels — editing _filters directly
        // would apply changes live and leave nothing to back out of.
        var draft = _filters;

        return StatefulBuilder(
          builder: (ctx, setSheet) => Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(ctx).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Filters',
                            style: AppTheme.sansBold(
                                fontSize: 17, color: AppTheme.inkOf(context))),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: AppTheme.inkMutedOf(context),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                    shrinkWrap: true,
                    children: [
                      _sheetGroup(
                        ctx,
                        'Work mode',
                        const ['On-site', 'Hybrid', 'Remote'],
                        draft.workModes,
                        (v) => setSheet(() {
                          final next = Set<String>.from(draft.workModes);
                          next.contains(v) ? next.remove(v) : next.add(v);
                          draft = draft.copyWith(workModes: next);
                        }),
                      ),
                      _sheetGroup(
                        ctx,
                        'Category',
                        AppData.categories.where((c) => c != 'All Roles').toList(),
                        draft.categories,
                        (v) => setSheet(() {
                          final next = Set<String>.from(draft.categories);
                          next.contains(v) ? next.remove(v) : next.add(v);
                          draft = draft.copyWith(categories: next);
                        }),
                      ),
                      _sheetGroup(
                        ctx,
                        'Location',
                        AppData.countries.map((c) => c['code']!).toList(),
                        draft.countries,
                        (v) => setSheet(() {
                          final next = Set<String>.from(draft.countries);
                          next.contains(v) ? next.remove(v) : next.add(v);
                          draft = draft.copyWith(countries: next);
                        }),
                        labelFor: (code) => AppData.countries
                            .firstWhere((c) => c['code'] == code)['name']!,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () =>
                            setSheet(() => draft = const JobFilters()),
                        child: Text('Reset',
                            style: AppTheme.sansMedium(
                                fontSize: 14, color: AppTheme.inkMutedOf(context))),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _filters = draft);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryFillOf(context),
                            foregroundColor: AppTheme.onPrimaryFillOf(context),
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 28),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Show results',
                              style: AppTheme.sansBold(
                                  fontSize: 14.5, color: AppTheme.onInkOf(context))),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetGroup(
    BuildContext ctx,
    String title,
    List<String> options,
    Set<String> selected,
    ValueChanged<String> onToggle, {
    String Function(String)? labelFor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTheme.sansBold(fontSize: 13.5, color: AppTheme.inkOf(context))),
        const SizedBox(height: 10),
        _gutter(Wrap(
          spacing: 9,
          runSpacing: 10,
          children: options.map((o) {
            final on = selected.contains(o);
            return InkWell(
              onTap: () => onToggle(o),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                decoration: BoxDecoration(
                  color: on ? AppTheme.signalPositiveWash : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: on
                        ? AppTheme.signalPositive
                        : Theme.of(ctx).dividerColor,
                  ),
                ),
                child: Text(
                  labelFor?.call(o) ?? o,
                  style: on
                      ? AppTheme.sansSemiBold(
                          fontSize: 13.5, color: AppTheme.signalPositive)
                      : AppTheme.sansMedium(
                          fontSize: 13.5, color: AppTheme.inkOf(context)),
                ),
              ),
            );
          }).toList(),
        )),
        const SizedBox(height: 22),
      ],
    );
  }
}
