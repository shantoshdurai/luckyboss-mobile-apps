import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/employer_models.dart';
import '../../providers/employer_provider.dart';
import '../../widgets/ledger_components.dart';

/// THE CANDIDATES SCREEN
///
/// The functional specification asks for three candidate tables — direct
/// applicants, Lucky Boss recommendations, and external feeds — and the obvious
/// phone translation is three tabs. That is the wrong call, and this screen
/// does not make it.
///
/// Tabs bury Recommended. It is the highest-value list on the screen precisely
/// because the recruiter did not ask for it: these are people who never applied
/// and who the recruiter will never see unless something puts them in front of
/// them. Behind a deliberate tap, that list may as well not exist.
///
/// So the default view is ALL, in one ledger, with each row carrying its source
/// openly. The segmented control narrows it when a recruiter wants to work one
/// source at a time. Nothing is hidden by default; nothing loses its provenance.
class AtsCandidatesTab extends StatefulWidget {
  const AtsCandidatesTab({super.key});

  @override
  State<AtsCandidatesTab> createState() => _AtsCandidatesTabState();
}

class _AtsCandidatesTabState extends State<AtsCandidatesTab> {
  String? _jobId;
  CandidateSource? _filter; // null == All
  bool _archivedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployerProvider>();
    final jobs = provider.jobs;

    if (jobs.isEmpty) {
      return const SafeArea(
        child: LedgerEmptyState(
          headline: 'No vacancies yet',
          explanation:
              'Candidates appear here once you publish a job. Post a vacancy to start '
              'receiving applicants and recommendations.',
        ),
      );
    }

    final jobId = _jobId ?? jobs.first.id;
    final job = jobs.firstWhere((j) => j.id == jobId, orElse: () => jobs.first);
    final candidates = provider.candidatesFor(job.id, source: _filter);
    final archived = provider.archivedFor(job.id);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _Header(job: job, jobs: jobs, onJobChanged: (id) => setState(() => _jobId = id)),
          const BrandRule(),
          _SourceFilter(
            active: _filter,
            counts: {
              null: provider.countFor(job.id),
              CandidateSource.applied: provider.countFor(job.id, source: CandidateSource.applied),
              CandidateSource.recommended:
                  provider.countFor(job.id, source: CandidateSource.recommended),
              CandidateSource.external: provider.countFor(job.id, source: CandidateSource.external),
            },
            onChanged: (s) => setState(() => _filter = s),
          ),
          const Divider(height: 1),
          Expanded(
            child: candidates.isEmpty
                ? _emptyFor(_filter)
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: candidates.length + 1,
                    separatorBuilder: (_, i) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      if (i == candidates.length) {
                        return _ArchivedSection(
                          archived: archived,
                          expanded: _archivedExpanded,
                          onToggle: () => setState(() => _archivedExpanded = !_archivedExpanded),
                          onRestore: (id) => provider.restoreCandidate(id),
                        );
                      }
                      return _CandidateRow(candidate: candidates[i]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Three sources means three different kinds of nothing. "No candidates" is
  /// useless in all three cases — a recruiter needs to know whether to wait,
  /// to fix their job description, or to turn a feature on.
  Widget _emptyFor(CandidateSource? source) {
    switch (source) {
      case CandidateSource.applied:
        return const LedgerEmptyState(
          headline: 'Nobody has applied yet',
          explanation:
              'This vacancy is live but has no direct applications. Promoting it or widening '
              'the required skills usually helps.',
        );
      case CandidateSource.recommended:
        return const LedgerEmptyState(
          headline: 'No recommendations yet',
          explanation:
              'Lucky Boss matches candidates from its database against your requirements. '
              'Adding required skills and an experience band to this vacancy improves matching.',
        );
      case CandidateSource.external:
        return const LedgerEmptyState(
          headline: 'No external candidates',
          explanation:
              'External sourcing is either turned off for your plan, or no partner feed matched '
              'this vacancy. Every external record always shows where it came from.',
        );
      case null:
        return const LedgerEmptyState(
          headline: 'No candidates on this vacancy',
          explanation:
              'Applications, recommendations and external records will all appear here as '
              'they arrive.',
        );
    }
  }
}

// =============================================================================
// HEADER — the job, and what this screen is costing.
// =============================================================================

class _Header extends StatelessWidget {
  final EmployerJobModel job;
  final List<EmployerJobModel> jobs;
  final ValueChanged<String> onJobChanged;

  const _Header({required this.job, required this.jobs, required this.onJobChanged});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployerProvider>();
    final days = DateTime.now().difference(job.postedDate).inDays;

    return Container(
      color: AppTheme.paper,
      padding: const EdgeInsets.fromLTRB(18, 10, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MetaText(job.status == 'published' ? 'Live' : job.status,
                  color: job.status == 'published' ? AppTheme.signalPositive : AppTheme.inkFaint),
              const SizedBox(width: 8),
              MetaText('Posted ${days}d ago'),
              const Spacer(),
              AiEntryPoint(
                availability: provider.aiAvailability,
                compact: true,
                onTap: () => _openAi(context),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // The job selector is a text affordance, not a boxed dropdown — the
          // title stays the biggest thing on the screen.
          InkWell(
            onTap: jobs.length < 2 ? null : () => _pickJob(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Flexible(child: Text(job.title, style: AppTheme.screenTitle())),
                  if (jobs.length > 1) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more, size: 19, color: AppTheme.inkFaint),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CreditMeter(
                label: 'Contact',
                used: provider.contactCreditsUsed,
                total: provider.contactCreditsTotal,
              ),
              Container(
                width: AppTheme.hairline,
                height: 12,
                color: AppTheme.rule,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              CreditMeter(
                label: 'AI',
                used: provider.aiCreditsUsed,
                total: provider.aiCreditsTotal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _pickJob(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const MetaText('Choose a vacancy'),
            const SizedBox(height: 10),
            ...jobs.map((j) => Material(
                  color: Colors.transparent,
                  child: ListTile(
                    title: Text(j.title, style: AppTheme.body(color: AppTheme.ink, weight: FontWeight.w600)),
                    subtitle: Text('${j.location} · ${j.applicantsCount} candidates',
                        style: AppTheme.small()),
                    selected: j.id == job.id,
                    onTap: () {
                      onJobChanged(j.id);
                      Navigator.pop(context);
                    },
                  ),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openAi(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lucky AI is not wired to the backend yet.')),
    );
  }
}

// =============================================================================
// SOURCE FILTER — All first, deliberately.
// =============================================================================

class _SourceFilter extends StatelessWidget {
  final CandidateSource? active;
  final Map<CandidateSource?, int> counts;
  final ValueChanged<CandidateSource?> onChanged;

  const _SourceFilter({required this.active, required this.counts, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = <CandidateSource?>[
      null,
      CandidateSource.applied,
      CandidateSource.recommended,
      CandidateSource.external,
    ];

    return Container(
      color: AppTheme.paper,
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        itemCount: options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final option = options[i];
          final selected = option == active;
          final label = option?.label ?? 'All';
          final count = counts[option] ?? 0;

          return InkWell(
            onTap: () => onChanged(option),
            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppTheme.ink : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                border: Border.all(
                  color: selected ? AppTheme.ink : AppTheme.rule,
                  width: AppTheme.hairline,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MetaText(label, color: selected ? AppTheme.surface : AppTheme.inkMuted, size: 10),
                  const SizedBox(width: 5),
                  Text('$count',
                      style: AppTheme.meta(
                        color: selected ? AppTheme.surface : AppTheme.inkFaint,
                        size: 10,
                        weight: FontWeight.w700,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// CANDIDATE ROW — a ruled row, not a card.
//
// The name is the only serif on the screen. That single decision is what makes
// a list of records read as a list of people, which is what a recruiter is
// actually scanning for.
// =============================================================================

class _CandidateRow extends StatelessWidget {
  final ApplicantModel candidate;

  const _CandidateRow({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<EmployerProvider>();

    return InkWell(
      onTap: () => _openActions(context, provider),
      child: Container(
        color: AppTheme.surface,
        padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(candidate.candidateName, style: AppTheme.personName()),
                      const SizedBox(height: 2),
                      if (candidate.headline.isNotEmpty)
                        Text(candidate.headline,
                            style: AppTheme.small(), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          SourceBadge(source: candidate.source, providerName: candidate.sourceName),
                          const SizedBox(width: 10),
                          Flexible(
                            child: MetaText(
                              '${candidate.experience} · ${candidate.location}',
                              size: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                MatchCell(
                  score: candidate.aiMatchScore,
                  onExplain: () => _explainMatch(context),
                ),
                IconButton(
                  onPressed: () => _openActions(context, provider),
                  icon: const Icon(Icons.more_horiz, size: 19, color: AppTheme.inkFaint),
                  tooltip: 'Actions',
                ),
              ],
            ),
            if (candidate.skills.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  ...candidate.skills.take(3).map((s) => _SkillChip(s)),
                  if (candidate.skills.length > 3)
                    _SkillChip('+${candidate.skills.length - 3}', faint: true),
                ],
              ),
            ],
            const SizedBox(height: 11),
            Row(
              children: [
                StagePill(candidate.status),
                const Spacer(),
                ContactActions(
                  revealed: candidate.contactRevealed,
                  creditCost: 1,
                  onCall: () => _notImplemented(context, 'Dialer'),
                  onEmail: () => _notImplemented(context, 'Email composer'),
                  onWhatsApp: () => _notImplemented(context, 'WhatsApp'),
                  onReveal: () => _reveal(context, provider),
                ),
              ],
            ),
            if (candidate.contactRevealed && candidate.candidateEmail != null) ...[
              const SizedBox(height: 4),
              MetaText('${candidate.candidatePhone}  ·  ${candidate.candidateEmail}', size: 9),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _reveal(BuildContext context, EmployerProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RevealContactDialog(
        candidateName: candidate.candidateName,
        remaining: provider.contactCreditsRemaining - 1,
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok = provider.revealContact(candidate.id);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No contact credits remaining. Upgrade your plan to reveal more.'),
        ),
      );
    }
  }

  void _explainMatch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MatchBreakdownSheet(
        candidateName: candidate.candidateName,
        score: candidate.aiMatchScore,
        // TODO: these come from the server once candidate_matches is populated.
        // The weights are the spec's rule-based fallback: skills 35, experience
        // 20, category 10, education 10, location 10, salary 5, availability 5.
        factors: const {
          'Skills': 92,
          'Experience': 88,
          'Education': 74,
          'Location': 100,
          'Salary': 70,
          'Availability': 85,
        },
        reasoning: candidate.aiMatchScore == null
            ? null
            : 'Matches 4 of 5 required skills and the experience band. '
                'Salary expectation sits above the posted range.',
      ),
    );
  }

  void _openActions(BuildContext context, EmployerProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
      ),
      builder: (sheetContext) => _ActionsSheet(candidate: candidate, provider: provider),
    );
  }

  void _notImplemented(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what is not wired up yet.')),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final bool faint;

  const _SkillChip(this.label, {this.faint = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          border: Border.all(color: AppTheme.rule, width: AppTheme.hairline),
        ),
        child: Text(label,
            style: AppTheme.small(color: faint ? AppTheme.inkFaint : AppTheme.inkMuted)
                .copyWith(fontSize: 11)),
      );
}

// =============================================================================
// ACTIONS SHEET
// =============================================================================

class _ActionsSheet extends StatelessWidget {
  final ApplicantModel candidate;
  final EmployerProvider provider;

  const _ActionsSheet({required this.candidate, required this.provider});

  @override
  Widget build(BuildContext context) {
    final aiLive = provider.aiAvailability == AiAvailability.live;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 32,
                height: 3,
                decoration:
                    BoxDecoration(color: AppTheme.rule, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(candidate.candidateName, style: AppTheme.personName(size: 19)),
                  const SizedBox(height: 3),
                  SourceBadge(source: candidate.source, providerName: candidate.sourceName),
                ],
              ),
            ),
            const Divider(height: 1),
            _action(context, Icons.person_outline, 'View profile'),
            _action(context, Icons.description_outlined, 'View resume'),
            _action(context, Icons.note_add_outlined, 'Add private note'),
            const Divider(height: 1),
            _action(context, Icons.bookmark_border, 'Shortlist',
                onTap: () => provider.updateApplicantStatus(candidate.id, 'Shortlisted')),
            _action(context, Icons.event_outlined, 'Schedule interview'),
            _action(context, Icons.swap_horiz, 'Change status',
                onTap: () => _changeStatus(context)),
            const Divider(height: 1),
            // AI-backed actions are locked visibly, with the reason, rather than
            // hidden — hiding them loses both the explanation and the upgrade.
            if (aiLive) ...[
              _action(context, Icons.mail_outline, 'Draft email with AI'),
              _action(context, Icons.article_outlined, 'Generate offer letter'),
            ] else ...[
              LockedActionTile(
                icon: Icons.mail_outline,
                label: 'Draft email with AI',
                onUpgrade: () => Navigator.pop(context),
              ),
              LockedActionTile(
                icon: Icons.article_outlined,
                label: 'Generate offer letter',
                onUpgrade: () => Navigator.pop(context),
              ),
            ],
            const Divider(height: 1),
            _action(context, Icons.inventory_2_outlined, 'Archive candidate',
                destructive: true, onTap: () => _archive(context)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, String label,
          {VoidCallback? onTap, bool destructive = false}) =>
      Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(icon,
              size: 19, color: destructive ? AppTheme.signalClosed : AppTheme.inkMuted),
          title: Text(label,
              style: AppTheme.body(
                color: destructive ? AppTheme.signalClosed : AppTheme.ink,
                weight: FontWeight.w500,
              )),
          onTap: () {
            Navigator.pop(context);
            if (onTap != null) {
              onTap();
            } else {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('$label is not wired up yet.')));
            }
          },
        ),
      );

  void _changeStatus(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 18),
              const MetaText('Change status'),
              const SizedBox(height: 10),
              // All 17 statuses the spec defines. Six colours across them; the
              // word carries the precision.
              ...CandidateStageStyle.allStatuses.map((s) => Material(
                    color: Colors.transparent,
                    child: ListTile(
                      dense: true,
                      title: Row(children: [StagePill(s)]),
                      selected: s == candidate.status,
                      onTap: () {
                        provider.updateApplicantStatus(candidate.id, s);
                        Navigator.pop(context);
                      },
                    ),
                  )),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _archive(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: MetaText('Why are you archiving?'),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'This removes ${candidate.candidateName} from the active pipeline for this '
                  'vacancy only. They stay in the Lucky Boss database and can be restored.',
                  style: AppTheme.body(),
                ),
              ),
              const Divider(height: 1),
              ...ArchiveReasons.all.map((r) => Material(
                    color: Colors.transparent,
                    child: ListTile(
                      dense: true,
                      title: Text(r, style: AppTheme.body(color: AppTheme.ink)),
                      onTap: () {
                        provider.archiveCandidate(candidate.id, r);
                        Navigator.pop(context);
                      },
                    ),
                  )),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ARCHIVED — collapsed, never deleted.
//
// Archiving is scoped to this company and this job. The candidate remains in
// the Lucky Boss database, and the record of who archived them and why stays
// attached, because a pipeline nobody can audit is a pipeline nobody can trust.
// =============================================================================

class _ArchivedSection extends StatelessWidget {
  final List<ApplicantModel> archived;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<String> onRestore;

  const _ArchivedSection({
    required this.archived,
    required this.expanded,
    required this.onToggle,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    if (archived.isEmpty) return const SizedBox(height: 32);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          child: Container(
            color: AppTheme.paper,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                MetaText('Archived — ${archived.length}'),
                const Spacer(),
                MetaText(expanded ? 'Hide' : 'Show', color: AppTheme.inkMuted),
                Icon(expanded ? Icons.expand_less : Icons.expand_more,
                    size: 17, color: AppTheme.inkFaint),
              ],
            ),
          ),
        ),
        if (expanded)
          ...archived.map((c) => Container(
                color: AppTheme.paper,
                padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.candidateName,
                              style: AppTheme.personName(color: AppTheme.inkMuted, size: 15)),
                          const SizedBox(height: 3),
                          MetaText(
                            '${c.archiveReason} · by ${c.archivedBy ?? "—"}',
                            size: 9,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => onRestore(c.id),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.inkMuted,
                        textStyle: AppTheme.meta(color: AppTheme.inkMuted, size: 10),
                      ),
                      child: const Text('RESTORE'),
                    ),
                  ],
                ),
              )),
        const SizedBox(height: 24),
      ],
    );
  }
}
