import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/candidate.dart';
import '../../models/employer_job.dart';
import '../../providers/employer_provider.dart';

/// The ATS: candidates for one job, in the three groups the spec requires.
///
/// Spec §14–16 defines them as three tables, and they are three tabs here for
/// the obvious reason — this is a phone, and a table with ten columns is not
/// something anyone reads on one. What the spec is really asking for is that
/// the three groups stay distinct, and they do:
///
/// * **Applied** — came to you. Contact details are visible from the start;
///   charging a credit for a contact the candidate volunteered is indefensible.
/// * **Recommended** — in the Lucky Boss database and a good fit, but they have
///   not applied. A contact credit reveals their details.
/// * **External** — from a partner feed or an import, and the source is always
///   named. Spec §16: do not hide where a candidate came from.
class AtsCandidatesTab extends StatefulWidget {
  /// Opens straight onto a job when the recruiter arrived from the jobs list.
  final String? initialJobId;
  final VoidCallback? onMenu;

  const AtsCandidatesTab({super.key, this.initialJobId, this.onMenu});

  @override
  State<AtsCandidatesTab> createState() => _AtsCandidatesTabState();
}

class _AtsCandidatesTabState extends State<AtsCandidatesTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  String? _jobId;

  @override
  void initState() {
    super.initState();
    _jobId = widget.initialJobId;
  }

  @override
  void didUpdateWidget(covariant AtsCandidatesTab old) {
    super.didUpdateWidget(old);
    if (widget.initialJobId != null &&
        widget.initialJobId != old.initialJobId) {
      setState(() => _jobId = widget.initialJobId);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployerProvider>();
    final jobs = provider.jobs;

    if (jobs.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.paperOf(context),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Post a job and the candidates who match it appear here.',
              textAlign: TextAlign.center,
              style: AppTheme.sansRegular(
                fontSize: 14,
                color: AppTheme.inkMutedOf(context),
              ),
            ),
          ),
        ),
      );
    }

    final job = provider.jobById(_jobId ?? '') ?? jobs.first;

    return Scaffold(
      backgroundColor: AppTheme.paperOf(context),
      body: SafeArea(
        child: Column(
          children: [
            _header(provider, job, jobs),
            TabBar(
              controller: _tabs,
              labelColor: AppTheme.inkOf(context),
              unselectedLabelColor: AppTheme.inkFaintOf(context),
              indicatorColor: AppTheme.signalSource,
              labelStyle: AppTheme.sansBold(
                fontSize: 12.5,
                color: AppTheme.inkOf(context),
              ),
              tabs: [
                for (final source in CandidateSource.values)
                  Tab(
                    text:
                        '${_tabLabel(source)} '
                        '(${provider.countFor(job.id, source: source)})',
                  ),
              ],
            ),
            Expanded(
              // Grouped for the same reason as the bottom navigation: the
              // notes box inside a candidate card is a text field, and Enter
              // there must not walk focus up into these tabs.
              child: FocusTraversalGroup(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    for (final source in CandidateSource.values)
                      _CandidateList(job: job, source: source),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _tabLabel(CandidateSource source) => switch (source) {
    CandidateSource.applied => 'Applied',
    CandidateSource.recommended => 'Recommended',
    CandidateSource.external => 'External',
  };

  Widget _header(
    EmployerProvider provider,
    EmployerJobModel job,
    List<EmployerJobModel> jobs,
  ) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
    color: Theme.of(context).cardColor,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.onMenu != null)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40),
                onPressed: widget.onMenu,
                tooltip: 'Menu',
                icon: Icon(Icons.menu, color: AppTheme.inkOf(context)),
              ),
            Text(
              'Candidates',
              style: AppTheme.serifTitle(
                fontSize: 23,
                color: AppTheme.inkOf(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Which vacancy is being staffed, switchable in place. A recruiter
        // hiring for four sites moves between them constantly.
        InkWell(
          onTap: () => _pickJob(jobs),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: AppTheme.surfaceOf(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.sansBold(
                          fontSize: 14,
                          color: AppTheme.inkOf(context),
                        ),
                      ),
                      Text(
                        job.location,
                        style: AppTheme.sansRegular(
                          fontSize: 12,
                          color: AppTheme.inkMutedOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (jobs.length > 1)
                  Icon(
                    Icons.unfold_more,
                    size: 18,
                    color: AppTheme.inkMutedOf(context),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              Icons.contact_phone_outlined,
              size: 14,
              color: AppTheme.inkFaintOf(context),
            ),
            const SizedBox(width: 6),
            Text(
              '${provider.contactCreditsRemaining} contact credits left',
              style: AppTheme.sansMedium(
                fontSize: 12,
                color: AppTheme.inkMutedOf(context),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  void _pickJob(List<EmployerJobModel> jobs) {
    if (jobs.length < 2) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Which job?',
              style: AppTheme.sansBold(
                fontSize: 16,
                color: AppTheme.inkOf(context),
              ),
            ),
            const SizedBox(height: 12),
            for (final j in jobs)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  j.title,
                  style: AppTheme.sansMedium(
                    fontSize: 14.5,
                    color: AppTheme.inkOf(context),
                  ),
                ),
                subtitle: Text(
                  j.location,
                  style: AppTheme.sansRegular(
                    fontSize: 12,
                    color: AppTheme.inkMutedOf(context),
                  ),
                ),
                trailing: j.id == _jobId
                    ? const Icon(Icons.check, color: AppTheme.signalPositive)
                    : null,
                onTap: () {
                  setState(() => _jobId = j.id);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _CandidateList extends StatelessWidget {
  final EmployerJobModel job;
  final CandidateSource source;

  const _CandidateList({required this.job, required this.source});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployerProvider>();
    final candidates = provider.candidatesFor(job.id, source: source);

    if (candidates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            switch (source) {
              CandidateSource.applied =>
                'Nobody has applied to this job yet. Recommended candidates are '
                    'on the next tab.',
              CandidateSource.recommended =>
                'No one in the Lucky Boss database matches this job closely '
                    'enough yet.',
              CandidateSource.external =>
                'No partner-sourced candidates for this job.',
            },
            textAlign: TextAlign.center,
            style: AppTheme.sansRegular(
              fontSize: 13.5,
              color: AppTheme.inkMutedOf(context),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
      itemCount: candidates.length,
      itemBuilder: (context, i) =>
          _CandidateCard(candidate: candidates[i], job: job),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final Candidate candidate;
  final EmployerJobModel job;

  const _CandidateCard({required this.candidate, required this.job});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployerProvider>();
    final match = candidate.matchFor(job);
    final revealed = candidate.contactRevealed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(15, 14, 12, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Initials(name: candidate.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.name,
                      style: AppTheme.sansBold(
                        fontSize: 15,
                        color: AppTheme.inkOf(context),
                      ),
                    ),
                    Text(
                      '${candidate.role}  ·  ${candidate.experienceLabel}',
                      style: AppTheme.sansRegular(
                        fontSize: 12.5,
                        color: AppTheme.inkMutedOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              _MatchBadge(score: match),
            ],
          ),

          const SizedBox(height: 12),
          _fact(context, Icons.place_outlined, candidate.location),
          if (candidate.certificates.isNotEmpty)
            _fact(
              context,
              Icons.badge_outlined,
              candidate.certificates.join(', '),
            ),
          if (candidate.languages.isNotEmpty)
            _fact(context, Icons.translate, candidate.languages.join(', ')),
          if (candidate.workPermitStatus.isNotEmpty)
            _fact(
              context,
              Icons.verified_user_outlined,
              candidate.workPermitStatus,
            ),
          if (candidate.availability.isNotEmpty)
            _fact(
              context,
              Icons.event_available_outlined,
              'Can start ${candidate.availability}',
            ),

          if (candidate.source == CandidateSource.external &&
              candidate.sourceName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.signalSourceWash,
                borderRadius: BorderRadius.circular(8),
              ),
              // Spec §16: the source field is mandatory on external records.
              child: Text(
                'Source: ${candidate.sourceName}',
                style: AppTheme.sansBold(
                  fontSize: 10.5,
                  color: AppTheme.signalSource,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          // Spec §17 — quick contact. Tapping a number should get a recruiter
          // to a call, not to a detail screen.
          if (revealed)
            Row(
              children: [
                Expanded(
                  child: _ContactChip(
                    icon: Icons.phone_outlined,
                    label: candidate.phone,
                    onTap: () => _copy(context, candidate.phone, 'Phone'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ContactChip(
                    icon: Icons.mail_outline,
                    label: candidate.email,
                    onTap: () => _copy(context, candidate.email, 'Email'),
                  ),
                ),
              ],
            )
          else
            _RevealBar(
              candidate: candidate,
              creditsLeft: provider.contactCreditsRemaining,
            ),

          const SizedBox(height: 10),
          Row(
            children: [
              _StagePill(status: candidate.status),
              const Spacer(),
              TextButton.icon(
                onPressed: () =>
                    _CandidateActions.open(context, candidate, job),
                icon: const Icon(Icons.more_horiz, size: 18),
                label: Text(
                  'Actions',
                  style: AppTheme.sansBold(
                    fontSize: 13,
                    color: AppTheme.royalBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fact(BuildContext context, IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: AppTheme.inkFaintOf(context)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: AppTheme.sansMedium(
              fontSize: 12.5,
              color: AppTheme.inkMutedOf(context),
            ),
          ),
        ),
      ],
    ),
  );

  static void _copy(BuildContext context, String value, String what) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$what copied.',
          style: AppTheme.sansMedium(
            fontSize: 13,
            color: AppTheme.onInkOf(context),
          ),
        ),
        backgroundColor: AppTheme.signalPositive,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String name;

  const _Initials({required this.name});

  @override
  Widget build(BuildContext context) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    final initials = parts.isEmpty
        ? '?'
        : (parts.length == 1
              ? parts.first.substring(0, 1)
              : parts.first.substring(0, 1) + parts.last.substring(0, 1));

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.inkOf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        initials.toUpperCase(),
        style: AppTheme.sansBold(
          fontSize: 15,
          color: AppTheme.onInkOf(context),
        ),
      ),
    );
  }
}

/// Spec §25 — the match score, and §26 — why.
class _MatchBadge extends StatelessWidget {
  final double score;

  const _MatchBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final value = score.round();
    final color = value >= 75
        ? AppTheme.signalPositive
        : (value >= 50 ? AppTheme.signalAttention : AppTheme.signalClosed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('$value%', style: AppTheme.sansBold(fontSize: 17, color: color)),
        Text(
          value >= 75 ? 'STRONG' : (value >= 50 ? 'FAIR' : 'WEAK'),
          style: AppTheme.sansBold(
            fontSize: 9,
            color: color,
          ).copyWith(letterSpacing: 0.5),
        ),
      ],
    );
  }
}

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.inkOf(context)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.sansMedium(
                fontSize: 11.5,
                color: AppTheme.inkOf(context),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Spec §71–72 — contact details behind a credit, with the cost stated before
/// it is spent rather than after.
class _RevealBar extends StatelessWidget {
  final Candidate candidate;
  final int creditsLeft;

  const _RevealBar({required this.candidate, required this.creditsLeft});

  @override
  Widget build(BuildContext context) {
    final exhausted = creditsLeft <= 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: 15,
            color: AppTheme.inkFaintOf(context),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.maskedPhone,
                  style: AppTheme.sansMedium(
                    fontSize: 12.5,
                    color: AppTheme.inkMutedOf(context),
                  ),
                ),
                Text(
                  exhausted
                      ? 'No contact credits left'
                      : 'Uses 1 of $creditsLeft credits',
                  style: AppTheme.sansRegular(
                    fontSize: 10.5,
                    color: exhausted
                        ? AppTheme.signalClosed
                        : AppTheme.inkFaintOf(context),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: exhausted
                ? null
                : () => context.read<EmployerProvider>().revealContact(
                    candidate.id,
                  ),
            child: Text(
              'Reveal',
              style: AppTheme.sansBold(
                fontSize: 12.5,
                color: exhausted
                    ? AppTheme.inkFaintOf(context)
                    : AppTheme.royalBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StagePill extends StatelessWidget {
  final String status;

  const _StagePill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      CandidateStages.hired => AppTheme.signalPositive,
      CandidateStages.offered => AppTheme.signalProgress,
      CandidateStages.interview => AppTheme.signalSource,
      CandidateStages.shortlisted => AppTheme.signalAttention,
      _ => AppTheme.inkMutedOf(context),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status, style: AppTheme.sansBold(fontSize: 11, color: color)),
    );
  }
}

/// Spec §18 — the Actions menu.
///
/// Only the actions that do something are offered. The spec lists fifteen,
/// several of which need email, WhatsApp and offer-letter generation that do
/// not exist yet; putting them on the menu as dead entries would be worse than
/// leaving them off, because a recruiter would try one mid-conversation with a
/// candidate.
class _CandidateActions {
  static void open(
    BuildContext context,
    Candidate candidate,
    EmployerJobModel job,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ActionSheet(candidate: candidate, job: job),
    );
  }
}

class _ActionSheet extends StatelessWidget {
  final Candidate candidate;
  final EmployerJobModel job;

  const _ActionSheet({required this.candidate, required this.job});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<EmployerProvider>();
    final reasons = candidate.matchReasons(job);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
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
            const SizedBox(height: 18),
            Text(
              candidate.name,
              style: AppTheme.serifTitle(
                fontSize: 22,
                color: AppTheme.inkOf(context),
              ),
            ),
            Text(
              '${candidate.role}  ·  ${candidate.location}',
              style: AppTheme.sansRegular(
                fontSize: 13,
                color: AppTheme.inkMutedOf(context),
              ),
            ),

            const SizedBox(height: 18),
            // Spec §26 — the score explained. A percentage a recruiter cannot
            // interrogate is a number they will stop trusting.
            Text(
              'WHY THIS MATCH',
              style: AppTheme.sansBold(
                fontSize: 10,
                color: AppTheme.inkFaintOf(context),
              ).copyWith(letterSpacing: 0.6),
            ),
            const SizedBox(height: 8),
            for (final reason in reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      reason.startsWith('Missing') ||
                              reason.startsWith('Currently in') ||
                              reason.startsWith('Need employer')
                          ? Icons.remove_circle_outline
                          : Icons.check_circle_outline,
                      size: 15,
                      color:
                          reason.startsWith('Missing') ||
                              reason.startsWith('Currently in') ||
                              reason.startsWith('Need employer')
                          ? AppTheme.signalAttention
                          : AppTheme.signalPositive,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reason,
                        style: AppTheme.sansMedium(
                          fontSize: 13,
                          color: AppTheme.inkOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),
            Text(
              'MOVE TO',
              style: AppTheme.sansBold(
                fontSize: 10,
                color: AppTheme.inkFaintOf(context),
              ).copyWith(letterSpacing: 0.6),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final stage in CandidateStages.all)
                  InkWell(
                    onTap: () {
                      provider.setCandidateStatus(candidate.id, stage);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: candidate.status == stage
                            ? AppTheme.signalPositiveWash
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: candidate.status == stage
                              ? AppTheme.signalPositive
                              : Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Text(
                        stage,
                        style: AppTheme.sansMedium(
                          fontSize: 13,
                          color: candidate.status == stage
                              ? AppTheme.signalPositive
                              : AppTheme.inkOf(context),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 22),
            _NoteBox(candidateId: candidate.id),

            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: () {
                provider.archiveCandidate(
                  candidate.id,
                  'Not suitable for this role',
                );
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.archive_outlined,
                size: 18,
                color: AppTheme.signalClosed,
              ),
              label: Text(
                'Archive for this job',
                style: AppTheme.sansBold(
                  fontSize: 13.5,
                  color: AppTheme.signalClosed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Spec §75 — private recruiter notes, visible only inside the company.
class _NoteBox extends StatefulWidget {
  final String candidateId;

  const _NoteBox({required this.candidateId});

  @override
  State<_NoteBox> createState() => _NoteBoxState();
}

class _NoteBoxState extends State<_NoteBox> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployerProvider>();
    final notes = provider.notesFor(widget.candidateId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INTERNAL NOTES',
          style: AppTheme.sansBold(
            fontSize: 10,
            color: AppTheme.inkFaintOf(context),
          ).copyWith(letterSpacing: 0.6),
        ),
        const SizedBox(height: 8),
        for (final note in notes)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceOf(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              note,
              style: AppTheme.sansRegular(
                fontSize: 13,
                color: AppTheme.inkOf(context),
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _add(),
                style: AppTheme.sansMedium(
                  fontSize: 13.5,
                  color: AppTheme.inkOf(context),
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Called 20 Aug, free after 30 days',
                  hintStyle: AppTheme.sansRegular(
                    fontSize: 13,
                    color: AppTheme.inkFaintOf(context),
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceOf(context),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: _controller.text.trim().isEmpty ? null : _add,
              icon: const Icon(Icons.send, size: 19),
              color: AppTheme.royalBlue,
            ),
          ],
        ),
      ],
    );
  }

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<EmployerProvider>().addNote(widget.candidateId, text);
    _controller.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {});
  }
}
