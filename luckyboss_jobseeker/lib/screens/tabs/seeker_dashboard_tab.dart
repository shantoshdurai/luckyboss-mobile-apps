import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../edit_profile_screen.dart';
import '../../providers/job_seeker_provider.dart';
import '../../widgets/ledger_components.dart';
import '../../widgets/rolling_search_bar.dart';
import '../../widgets/home_components.dart';
import '../../widgets/job_card.dart';
import '../../widgets/feed_prompt_card.dart';
import '../../widgets/matching_loader.dart';
import '../../widgets/category_flash_cards.dart';
import '../../widgets/lucky_ai_copilot_modal.dart';
import '../jobs/all_jobs_screen.dart';
import '../notifications_screen.dart';

/// THE JOB SEEKER DASHBOARD — specification sections 28, 30 and 80.
///
/// Three sections, in this order, because it is the order that matches what a
/// job seeker actually worries about:
///
///   1. My Applications      — what I already did, and what happened to it
///   2. Recommended for you  — what Lucky Boss thinks I should do next
///   3. External jobs        — listings from partner feeds, always attributed
///
/// The External section does not render at all when the admin has third-party
/// jobs switched off. That is deliberate and it is what the spec asks for: an
/// empty "External jobs" heading would tell a seeker the feature exists and
/// simply found nothing for them, which is a different and untrue message.
///
/// Same Ledger system as the employer app — same ink, same paper, same stage
/// colours, same serif reserved for people. An employer and a candidate looking
/// at their phones should recognise the same product.
class SeekerDashboardTab extends StatelessWidget {
  /// Opens the left drawer. Owned by the shell, which holds the Scaffold key.
  final VoidCallback onMenu;

  /// Jumps to the search tab.
  final VoidCallback onSearch;

  /// Jumps to the profile tab — the completion ring routes here, because a
  /// score with no way to act on it is only a scold.
  final VoidCallback onProfile;

  const SeekerDashboardTab({
    super.key,
    required this.onMenu,
    required this.onSearch,
    required this.onProfile,
  });

  /// The feed is not a flat list of jobs.
  ///
  /// Every fourth slot is something other than a job card — a preference
  /// question, or a category strip that scrolls sideways. Both exist to break
  /// the texture: an unbroken column of identical cards stops registering as
  /// separate items no matter how well each one is designed.
  static const int _jobsPerBreak = 3;

  /// What sits in a break slot.
  ///
  /// Slot 1 is the category strip; every other slot is the next unanswered
  /// question. Deriving the prompt index from the slot directly (rather than
  /// from parity) is what stops two adjacent slots resolving to the same
  /// question — a feed that asks the same thing twice looks broken.
  Widget? _breakItem(JobSeekerProvider provider, int breakIndex) {
    const categorySlot = 1;

    if (breakIndex == categorySlot) {
      return CategoryFlashCards(onPick: (_) => onSearch());
    }

    final pending = provider.pendingPrompts;
    final promptIndex = breakIndex > categorySlot ? breakIndex - 1 : breakIndex;

    // Keyed by the question. The feed rebuilds on every provider notification,
    // and without a key Flutter matches this State by position — so answering
    // or dismissing one question could hand its half-typed answer to the next.
    return promptIndex < pending.length
        ? FeedPromptCard(
            key: ValueKey(pending[promptIndex].id),
            prompt: pending[promptIndex],
          )
        : null;
  }

  /// Flat feed length: jobs plus however many break slots actually have content.
  int _feedLength(JobSeekerProvider provider) {
    final jobs = provider.recommendedJobs.length;
    var count = jobs;
    for (var b = 0; b < (jobs ~/ _jobsPerBreak); b++) {
      if (_breakItem(provider, b) != null) count++;
    }
    return count;
  }

  /// Maps a flat index onto either a job or a break item.
  ///
  /// Walks the sequence rather than computing it, because break slots can be
  /// empty (no questions left) and an arithmetic mapping would leave gaps.
  Widget _feedItemAt(JobSeekerProvider provider, int index) {
    final jobs = provider.recommendedJobs;
    var cursor = 0;
    var jobIndex = 0;
    var breakIndex = 0;

    // Marks the jobIndex whose break slot has already been consumed. Without
    // it the loop re-enters the same slot forever, because emitting a break
    // does not advance jobIndex and the modulo test stays true.
    var breakDoneFor = -1;

    while (cursor <= index) {
      final atBreak = jobIndex > 0 &&
          jobIndex % _jobsPerBreak == 0 &&
          breakDoneFor != jobIndex;

      if (atBreak) {
        breakDoneFor = jobIndex;
        final item = _breakItem(provider, breakIndex);
        breakIndex++;
        if (item != null) {
          if (cursor == index) return item;
          cursor++;
          continue;
        }
        // Empty break slot: fall through and emit the next job instead.
      }

      if (jobIndex >= jobs.length) return const SizedBox.shrink();
      if (cursor == index) return JobCard(job: jobs[jobIndex]);
      jobIndex++;
      cursor++;
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobSeekerProvider>();

    return Scaffold(
      backgroundColor: AppTheme.paperOf(context),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Search leads the screen, and stays.
            //
            // Pinned rather than scrolled away. Shantosh: *"it looks great when
            // I scroll down, the screen bar goes with it — it feels pretty
            // empty up [there] without them."* He is right on both counts: the
            // top of a scrolled feed looked bare, and search is the one control
            // a candidate reaches for at any point in a long list. The wordmark
            // stays off it — that identified the app once, at open, and then
            // took a band of every scroll for the rest of the session.
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedSearchHeader(
                child: _SearchEntry(onSearch: onSearch, onMenu: onMenu),
              ),
            ),
            const SliverToBoxAdapter(child: BrandRule()),
            // The only profile surface on home: a single nudge that routes to
            // the profile, where the actual work is done. It disappears once
            // there is nothing left to complete.
            if (provider.nextProfileStep != null)
              SliverToBoxAdapter(
                child: FadeInUp(
                  child: ProfileCompletionRing(
                    percent: provider.profileCompletion,
                    nextAction: provider.nextProfileStep!,
                    // Straight to the editor. This used to open the profile
                    // tab, which told the candidate to add their name and gave
                    // them nowhere to type it.
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen()),
                    ),
                  ),
                ),
              ),


            // ---- Recommended ----
            SliverToBoxAdapter(
              child: FadeInUp(
                index: 2,
                child: HomeSectionHeader(
                  title: 'Recommended for you',
                  count: provider.recommendedJobs.isEmpty
                      ? null
                      : provider.recommendedJobs.length,
                  note: provider.profile.skills.isEmpty
                      ? 'Add skills to unlock matching'
                      : 'Matched against your skills',
                  // Opens the full recommended list, not the search screen —
                  // "View all" that lands somewhere else is a broken promise.
                  onViewAll: provider.recommendedJobs.isEmpty
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AllJobsScreen(
                                title: 'Recommended for you',
                                source: JobListSource.recommended,
                              ),
                            ),
                          ),
                ),
              ),
            ),
            if (provider.isLoading)
              SliverToBoxAdapter(
                child: MatchingLoader(
                  skillHint: provider.profile.skills.isEmpty
                      ? null
                      : provider.profile.skills.take(2).join(', '),
                ),
              )
            else if (provider.profile.skills.isEmpty)
              SliverToBoxAdapter(
                child: FadeInUp(
                  index: 3,
                  child: const LedgerEmptyState(
                    headline: 'Nothing to recommend yet',
                    explanation:
                        'Lucky Boss matches you against live vacancies using your skills. '
                        'Add a few and recommendations start appearing immediately.',
                  ),
                ),
              )
            else if (provider.recommendedJobs.isEmpty)
              SliverToBoxAdapter(
                child: FadeInUp(
                  index: 3,
                  child: const LedgerEmptyState(
                    headline: 'No new matches right now',
                    explanation:
                        'You have applied to everything that currently matches your profile. '
                        'New vacancies are matched as employers post them.',
                  ),
                ),
              )
            else
              // Jobs with a preference question folded in every third card, so
              // the feed asks as it goes instead of gating the app behind a form.
              SliverList.builder(
                itemCount: _feedLength(provider),
                itemBuilder: (_, i) => FadeInUp(
                  index: i + 3,
                  child: _feedItemAt(provider, i),
                ),
              ),

            // ---- External — absent entirely when the admin switch is off ----
            if (provider.externalJobsEnabled) ...[
              SliverToBoxAdapter(
                child: HomeSectionHeader(
                  title: 'From partner feeds',
                  count: provider.externalJobs.isEmpty
                      ? null
                      : provider.externalJobs.length,
                  note: 'Published by authorised recruitment partners',
                  onViewAll: provider.externalJobs.isEmpty
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AllJobsScreen(
                                title: 'Partner feeds',
                                source: JobListSource.external,
                              ),
                            ),
                          ),
                ),
              ),
              if (provider.externalJobs.isEmpty)
                const SliverToBoxAdapter(
                  child: LedgerEmptyState(
                    headline: 'No partner listings today',
                    explanation:
                        'External vacancies come from authorised recruitment partners. '
                        'Every one always shows which partner published it.',
                  ),
                )
              else
                SliverList.builder(
                  itemCount: provider.externalJobs.length,
                  itemBuilder: (_, i) =>
                      JobCard(job: provider.externalJobs[i]),
                ),
            ],

            const SliverToBoxAdapter(child: FeedFeedbackCard()),
            SliverToBoxAdapter(
              child: ListEndCap(
                message: "That's everything for now. "
                    'New vacancies are matched as employers post them.',
                actionLabel: 'Search all jobs',
                onAction: onSearch,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// =============================================================================
// SEARCH ENTRY
//
// Search was previously reachable only by finding the right tab. Putting it at
// the top of home makes it the first thing available, which is what a candidate
// opening a job app most often wants.
// =============================================================================

class _SearchEntry extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onMenu;
  const _SearchEntry({required this.onSearch, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.paperOf(context),
      padding: const EdgeInsets.fromLTRB(4, 6, 6, 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.menu, size: 23, color: AppTheme.inkOf(context)),
            tooltip: 'Menu',
            onPressed: onMenu,
          ),
          Expanded(child: RollingSearchBar(onTap: onSearch)),
          _action(
            context,
            icon: Icons.auto_awesome,
            tooltip: 'Ask Lucky AI',
            onTap: () => LuckyAiCopilotModal.show(context),
          ),
          _action(
            context,
            icon: Icons.notifications_none,
            tooltip: 'Notifications',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) =>
      IconButton(
        icon: Icon(icon, size: 21, color: AppTheme.inkOf(context)),
        tooltip: tooltip,
        onPressed: onTap,
      );
}

// =============================================================================
// GREETING
// =============================================================================


// =============================================================================
// PROFILE PROGRESS — spec 30.
//
// The number is only useful if it comes with the single next thing to do.
// "Your profile is 45% complete" on its own is a scold; naming the highest-value
// missing field is an instruction.
// =============================================================================


// =============================================================================
// STAT ROW — spec 80.
// =============================================================================


// =============================================================================
// SECTION HEADER
// =============================================================================



// =============================================================================
// JOB ROW — used by both Recommended and External.
//
// One row widget for both, because they are the same object to a job seeker.
// The only difference is provenance, and that is carried by the badge rather
// than by a different layout.
// =============================================================================

/// Keeps the search bar at the top of the feed while it scrolls.
///
/// A fixed-height delegate rather than a `SliverAppBar` because the bar is not
/// an app bar — it has no title, no back button and no elevation of its own,
/// and wrapping it in one would have introduced all three.
class _PinnedSearchHeader extends SliverPersistentHeaderDelegate {
  final Widget child;

  const _PinnedSearchHeader({required this.child});

  /// Matches `_SearchEntry`'s own height. Measured rather than guessed: a
  /// delegate whose extent disagrees with its child clips it.
  static const double _height = 74;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      Container(
        height: _height,
        // Opaque, or the feed scrolls visibly underneath the search field.
        color: AppTheme.paperOf(context),
        child: child,
      );

  @override
  bool shouldRebuild(_PinnedSearchHeader old) => old.child != child;
}
