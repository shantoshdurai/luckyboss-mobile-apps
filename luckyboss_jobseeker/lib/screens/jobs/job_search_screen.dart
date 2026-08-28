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

  /// Drops the experience filter.
  ///
  /// A separate method because `copyWith` cannot express "set this to null" —
  /// a null argument there means "leave unchanged", which is exactly what a
  /// clear button must not do.
  JobFilters clearExperience() => JobFilters(
        workModes: workModes,
        categories: categories,
        countries: countries,
      );

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
            // Filters sit with the query that produced the results, not at
            // the bottom of the screen away from it.
            //
            // Shown on the entry view too, not only after a search. Setting a
            // country or a work mode before searching is a normal thing to
            // want, and hiding the controls until results exist made the
            // filters feel like an afterthought rather than part of the
            // search.
            _filterBar(),
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
            // Suggestions only once there is something to match on. Tapping
            // this field used to drop eight cities over the whole screen
            // before a single character had been typed.
            minChars: 2,
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
      // Rebuilds so the clear button appears and disappears with the text.
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => (onSubmitted ?? _runSearch)(),
      style: AppTheme.sansMedium(fontSize: 14.5, color: AppTheme.inkOf(context)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.sansRegular(fontSize: 14.5, color: AppTheme.inkFaintOf(context)),
        prefixIcon: Icon(icon, size: 19, color: AppTheme.inkFaintOf(context)),
        // There was no way to empty a field once typed in. Clearing it by
        // hand on a phone means selecting text in a box the keyboard is
        // covering.
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close,
                    size: 17, color: AppTheme.inkFaintOf(context)),
                tooltip: 'Clear',
                onPressed: () {
                  controller.clear();
                  setState(() {
                    // Emptying the box means the result set no longer matches
                    // what is on screen, so drop back to the entry view rather
                    // than leaving stale results above an empty query.
                    if (_keywordController.text.trim().isEmpty &&
                        _locationController.text.trim().isEmpty) {
                      _searched = false;
                    }
                  });
                },
              ),
        suffixIconConstraints:
            const BoxConstraints(minWidth: 36, minHeight: 36),
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
  /// Whether the full category list is expanded under the suggestions.
  bool _showAllCategories = false;

  Widget _gutter(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: child,
      );

  /// Openers for a candidate whose trade we know: their own job first, then
  /// the work next to it, then where those jobs are.
  List<Widget> _suggestionSection() {
    final profile = context.read<JobSeekerProvider>().profile;
    final role =
        profile.roleTitle.isNotEmpty ? profile.roleTitle : profile.currentTitle;
    final category = AppData.categoryByName(profile.preferredCategory) ??
        AppData.categoryForRole(role);

    if (category == null) return _categoryBrowse();

    // Their own job at the head of the list — it is the single search they are
    // most likely to want and it should not need typing.
    final roles = <String>[
      if (role.isNotEmpty && category.roleNames.contains(role)) role,
      ...category.roleNames.where((r) => r != role),
    ];

    return [
      _gutter(Row(
        children: [
          Icon(category.icon, size: 17, color: AppTheme.signalSource),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Jobs in ${category.name}',
                style: AppTheme.sansBold(
                    fontSize: 13.5, color: AppTheme.inkOf(context))),
          ),
        ],
      )),
      const SizedBox(height: 4),
      _gutter(Text(
        role.isEmpty
            ? 'Tap a job to see what is open.'
            : 'Your trade first, then the work closest to it.',
        style: AppTheme.sansRegular(
            fontSize: 12.5, color: AppTheme.inkFaintOf(context)),
      )),
      const SizedBox(height: 12),
      _gutter(Wrap(
        spacing: 9,
        runSpacing: 10,
        children: [
          for (final r in roles.take(14))
            _pill(
              label: r,
              highlighted: r == role,
              onTap: () {
                // Searches the job title rather than filtering by category —
                // a Plumber wants plumbing vacancies, not every construction
                // job in the market.
                _keywordController.text = r;
                setState(() => _filters =
                    _filters.copyWith(categories: {category.name}));
                _runSearch();
              },
            ),
        ],
      )),
      const SizedBox(height: 26),
      _gutter(InkWell(
        onTap: () => setState(() => _showAllCategories = !_showAllCategories),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text(
                _showAllCategories
                    ? 'Hide other kinds of work'
                    : 'Looking for a different kind of work?',
                style: AppTheme.sansBold(
                    fontSize: 13, color: AppTheme.royalBlue),
              ),
              const SizedBox(width: 4),
              Icon(
                _showAllCategories
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 18,
                color: AppTheme.royalBlue,
              ),
            ],
          ),
        ),
      )),
      if (_showAllCategories) ...[
        const SizedBox(height: 12),
        ..._categoryBrowse(withHeading: false),
      ],
    ];
  }

  /// The full category list. Still the opener for a candidate whose trade we do
  /// not know yet, and the expanded state of the link above otherwise.
  List<Widget> _categoryBrowse({bool withHeading = true}) => [
        if (withHeading) ...[
          _gutter(Text('Browse by category',
              style: AppTheme.sansBold(
                  fontSize: 13.5, color: AppTheme.inkOf(context)))),
          const SizedBox(height: 12),
        ],
        _gutter(Wrap(
          spacing: 9,
          runSpacing: 10,
          children: [
            for (final category in AppData.workCategories)
              _pill(
                label: category.name,
                icon: category.icon,
                onTap: () {
                  _keywordController.clear();
                  setState(() => _filters =
                      _filters.copyWith(categories: {category.name}));
                  _runSearch();
                },
              ),
          ],
        )),
      ];

  Widget _pill({
    required String label,
    required VoidCallback onTap,
    IconData? icon,
    bool highlighted = false,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: highlighted
                ? AppTheme.signalSource.withValues(alpha: 0.09)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: highlighted
                  ? AppTheme.signalSource
                  : Theme.of(context).dividerColor,
              width: highlighted ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: AppTheme.inkMutedOf(context)),
                const SizedBox(width: 7),
              ],
              Text(label,
                  style: highlighted
                      ? AppTheme.sansBold(
                          fontSize: 13.5, color: AppTheme.signalSource)
                      : AppTheme.sansMedium(
                          fontSize: 13.5, color: AppTheme.inkOf(context))),
            ],
          ),
        ),
      );

  Widget _entryView() {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 30),
      children: [
        if (_recentSearches.isNotEmpty) ...[
          _gutter(Row(
            children: [
              Expanded(
                child: Text('Recent searches',
                    style: AppTheme.sansBold(
                        fontSize: 13.5, color: AppTheme.inkOf(context))),
              ),
              InkWell(
                onTap: () => setState(_recentSearches.clear),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  child: Text('Clear all',
                      style: AppTheme.sansBold(
                          fontSize: 12.5, color: AppTheme.royalBlue)),
                ),
              ),
            ],
          )),
          const SizedBox(height: 10),
          ..._recentSearches.map((s) => InkWell(
                onTap: () {
                  final parts = s.split(' · ');
                  _keywordController.text = parts.first;
                  _locationController.text = parts.length > 1 ? parts[1] : '';
                  _runSearch();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.history,
                          size: 18, color: AppTheme.inkFaintOf(context)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(s,
                            style: AppTheme.sansMedium(
                                fontSize: 14, color: AppTheme.inkOf(context))),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            size: 15, color: AppTheme.inkFaintOf(context)),
                        tooltip: 'Remove',
                        visualDensity: VisualDensity.compact,
                        onPressed: () =>
                            setState(() => _recentSearches.remove(s)),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 26),
        ],
        // What to offer here depends on whether we already know the candidate's
        // trade.
        //
        // The screen used to open with "Browse by category" — Construction,
        // Manufacturing, IT & Software — put to somebody who had chosen
        // Construction two screens earlier during onboarding. Asking again is
        // not neutral: it tells the candidate the app did not keep what they
        // said. When we know the trade, the useful thing is the jobs next to
        // theirs; the full category list moves behind a link for the minority
        // who genuinely want to look elsewhere.
        ..._suggestionSection(),
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
                    // Each chip carries its own icon and, once set, its own
                    // value and its own clear button.
                    //
                    // They were three identical pills reading "Work mode",
                    // "Category", "Location" with the same chevron, all opening
                    // the same sheet, and once one was set there was no way to
                    // undo just that one. Shantosh: *"everything looks the same
                    // … just pressing a button it sorted, I can't clear it."*
                    _filterChip(
                      icon: Icons.business_center_outlined,
                      label: 'Work mode',
                      values: _filters.workModes,
                      onClear: () => setState(() =>
                          _filters = _filters.copyWith(workModes: const {})),
                    ),
                    _filterChip(
                      icon: Icons.category_outlined,
                      label: 'Category',
                      values: _filters.categories,
                      onClear: () => setState(() =>
                          _filters = _filters.copyWith(categories: const {})),
                    ),
                    _filterChip(
                      icon: Icons.place_outlined,
                      label: 'Location',
                      values: _filters.countries,
                      onClear: () => setState(() =>
                          _filters = _filters.copyWith(countries: const {})),
                    ),
                    _filterChip(
                      icon: Icons.timeline_outlined,
                      label: 'Experience',
                      values: {
                        if (_filters.experience != null) _filters.experience!
                      },
                      onClear: () => setState(
                          () => _filters = _filters.clearExperience()),
                    ),
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

  /// One filter, showing what it is set to and how to unset it.
  ///
  /// An unset chip reads as its category with a chevron; a set one reads as the
  /// chosen value with an ×. That is the difference between a row of buttons
  /// and a row of answers, and it is what makes the bar scannable at a glance
  /// rather than something to be decoded.
  Widget _filterChip({
    required IconData icon,
    required String label,
    required Set<String> values,
    required VoidCallback onClear,
  }) {
    final active = values.isNotEmpty;
    // The value itself when there is one, a count when there are several —
    // "On-site" is more use than "Work mode", and "2 categories" is more use
    // than either when two are picked.
    final text = !active
        ? label
        : (values.length == 1
            ? values.first
            : '${values.length} ${label.toLowerCase()}s');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Container(
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
            InkWell(
              onTap: _openFilterSheet,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 8, active ? 6 : 10, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        size: 14,
                        color: active
                            ? AppTheme.signalPositive
                            : AppTheme.inkMutedOf(context)),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 130),
                      child: Text(text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: active
                              ? AppTheme.sansBold(
                                  fontSize: 13,
                                  color: AppTheme.signalPositive)
                              : AppTheme.sansMedium(
                                  fontSize: 13,
                                  color: AppTheme.inkOf(context))),
                    ),
                    if (!active) ...[
                      const SizedBox(width: 3),
                      Icon(Icons.expand_more,
                          size: 15, color: AppTheme.inkFaintOf(context)),
                    ],
                  ],
                ),
              ),
            ),
            // Clears this one filter. "Clear all" was the only way out before,
            // so narrowing to the wrong category meant starting the search over.
            if (active)
              InkWell(
                onTap: () {
                  onClear();
                  if (_searched) _runSearch();
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(2, 8, 10, 8),
                  child: Icon(Icons.close,
                      size: 14, color: AppTheme.signalPositive),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
