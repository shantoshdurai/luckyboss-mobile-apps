import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Shared components for the Ledger system.
///
/// Everything here obeys the one rule: the furniture is achromatic, and colour
/// only appears where it carries data meaning.

// =============================================================================
// BRAND RULE — the 2px gradient under the app bar.
//
// This and the logo are the only places the brand ramp is allowed to appear as
// decoration. Everywhere else, colour must mean something.
// =============================================================================

class BrandRule extends StatelessWidget {
  final double height;
  const BrandRule({super.key, this.height = 2});

  @override
  Widget build(BuildContext context) =>
      Container(height: height, decoration: const BoxDecoration(gradient: AppTheme.brandRule));
}

// =============================================================================
// TRACKED CAPS — the logo's tagline tracking, reused for every factual label.
// =============================================================================

class MetaText extends StatelessWidget {
  final String text;
  final Color? color;
  final double size;

  const MetaText(this.text, {super.key, this.color, this.size = 10});

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: AppTheme.meta(color: color ?? AppTheme.inkFaintOf(context), size: size),
      );
}

// =============================================================================
// STAGE PILL — six colours, seventeen words.
//
// The pill takes its ink from the stage; the text is the exact status. That is
// how "Offer Sent" and "Offer Accepted" stay distinguishable without inventing
// a seventeenth hue nobody can learn.
// =============================================================================

class StagePill extends StatelessWidget {
  final String status;
  const StagePill(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final stage = CandidateStageStyle.of(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: stage.wash,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: MetaText(status, color: stage.color, size: 10),
    );
  }
}

// =============================================================================
// MATCH CELL — a number, a tier word, and a bar that drains as the score falls.
//
// Tapping it opens the breakdown. A recruiter who cannot see why a score is 74
// has no reason to trust it, so the score is always explainable.
// =============================================================================

class MatchCell extends StatelessWidget {
  final double? score;
  final VoidCallback? onExplain;

  const MatchCell({super.key, required this.score, this.onExplain});

  @override
  Widget build(BuildContext context) {
    final tier = MatchTierStyle.of(score);
    final unscored = score == null;

    return InkWell(
      onTap: onExplain,
      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  unscored ? '4/6' : score!.toStringAsFixed(0),
                  style: AppTheme.score(color: tier.color, size: unscored ? 15 : 22),
                ),
                if (onExplain != null) ...[
                  const SizedBox(width: 3),
                  Icon(Icons.unfold_more, size: 11, color: AppTheme.inkFaintOf(context)),
                ],
              ],
            ),
            const SizedBox(height: 2),
            MetaText(tier.label, color: tier.color, size: 9),
            const SizedBox(height: 4),
            // The bar is the score made physical. It shortens and greys together.
            SizedBox(
              width: 54,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: LinearProgressIndicator(
                  value: unscored ? 4 / 6 : (score! / 100).clamp(0.0, 1.0),
                  minHeight: 3,
                  backgroundColor: AppTheme.ruleOf(context),
                  valueColor: AlwaysStoppedAnimation(tier.color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The breakdown behind a score. Opened from MatchCell.
class MatchBreakdownSheet extends StatelessWidget {
  final String candidateName;
  final double? score;
  final Map<String, double> factors;
  final String? reasoning;

  const MatchBreakdownSheet({
    super.key,
    required this.candidateName,
    required this.score,
    required this.factors,
    this.reasoning,
  });

  @override
  Widget build(BuildContext context) {
    final tier = MatchTierStyle.of(score);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(color: AppTheme.ruleOf(context), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MetaText('Match breakdown'),
                    const SizedBox(height: 4),
                    Text(candidateName, style: AppTheme.personName(size: 19)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(score?.toStringAsFixed(0) ?? '—', style: AppTheme.score(color: tier.color, size: 30)),
                  MetaText(tier.label, color: tier.color, size: 9),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...factors.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(width: 96, child: MetaText(e.key, size: 10)),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(1),
                        child: LinearProgressIndicator(
                          value: (e.value / 100).clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: AppTheme.ruleOf(context),
                          valueColor: AlwaysStoppedAnimation(MatchTierStyle.of(e.value).color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 30,
                      child: Text(e.value.toStringAsFixed(0),
                          textAlign: TextAlign.right, style: AppTheme.small(color: AppTheme.ink)),
                    ),
                  ],
                ),
              )),
          if (reasoning != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.paperOf(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusRow),
                border: Border.all(color: AppTheme.ruleOf(context), width: AppTheme.hairline),
              ),
              child: Text(reasoning!, style: AppTheme.body()),
            ),
          ],
          if (score == null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.signalAttentionWash,
                borderRadius: BorderRadius.circular(AppTheme.radiusRow),
              ),
              child: Text(
                'AI scoring is unavailable, so this candidate was matched on rules only — '
                'required skills, experience band and location. Enable AI to get a weighted score.',
                style: AppTheme.body(color: AppTheme.signalAttention),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// SOURCE BADGE — where a candidate came from is never hidden.
//
// For external candidates the badge carries the actual provider name, because
// "external" alone tells a recruiter nothing about whether they can trust it.
// =============================================================================

class SourceBadge extends StatelessWidget {
  final CandidateSource source;
  final String? providerName;

  const SourceBadge({super.key, required this.source, this.providerName});

  @override
  Widget build(BuildContext context) {
    final label = source == CandidateSource.external && providerName != null
        ? 'External · $providerName'
        : source.label;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: source.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        MetaText(label, color: source.color, size: 9),
      ],
    );
  }
}

// =============================================================================
// CREDIT METER — visible, but never the loudest thing on screen.
//
// Turns to attention ink under 15% so a recruiter finds out before they are
// mid-shortlist, not after.
// =============================================================================

class CreditMeter extends StatelessWidget {
  final String label;
  final int used;
  final int total;

  const CreditMeter({super.key, required this.label, required this.used, required this.total});

  @override
  Widget build(BuildContext context) {
    final remaining = total - used;
    final low = total > 0 && remaining / total < 0.15;
    final color = low ? AppTheme.signalAttention : AppTheme.inkMutedOf(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MetaText(label, size: 9),
        const SizedBox(width: 5),
        Text('$remaining', style: AppTheme.meta(color: color, size: 11, weight: FontWeight.w700)),
        Text('/$total', style: AppTheme.meta(color: AppTheme.inkFaintOf(context), size: 10)),
      ],
    );
  }
}

// =============================================================================
// CONTACT — revealed, or gated behind a credit.
//
// Someone who applied to this job volunteered their number. Charging to see it
// would be indefensible, so `alwaysVisible` short-circuits the gate entirely.
// =============================================================================

class ContactActions extends StatelessWidget {
  final bool revealed;
  final VoidCallback? onCall;
  final VoidCallback? onEmail;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onReveal;
  final int creditCost;

  const ContactActions({
    super.key,
    required this.revealed,
    this.onCall,
    this.onEmail,
    this.onWhatsApp,
    this.onReveal,
    this.creditCost = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (!revealed) {
      return OutlinedButton.icon(
        onPressed: onReveal,
        icon: const Icon(Icons.lock_outline, size: 13),
        label: Text('Reveal · $creditCost credit${creditCost == 1 ? '' : 's'}'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 34),
          padding: const EdgeInsets.symmetric(horizontal: 11),
          foregroundColor: AppTheme.inkMutedOf(context),
          side: BorderSide(color: AppTheme.ruleOf(context), width: AppTheme.hairline),
          textStyle: AppTheme.meta(color: AppTheme.inkMutedOf(context), size: 10),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconAction(icon: Icons.call_outlined, onTap: onCall, tooltip: 'Call'),
        _IconAction(icon: Icons.mail_outline, onTap: onEmail, tooltip: 'Email'),
        _IconAction(icon: Icons.chat_bubble_outline, onTap: onWhatsApp, tooltip: 'WhatsApp'),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  const _IconAction({required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          // 44px tap target — the visual mark is smaller, the target is not.
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 17, color: AppTheme.inkMutedOf(context)),
          ),
        ),
      );
}

/// Confirmation before a credit is spent. Recruiters should never discover a
/// charge after the fact.
class RevealContactDialog extends StatelessWidget {
  final String candidateName;
  final int remaining;

  const RevealContactDialog({super.key, required this.candidateName, required this.remaining});

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: AppTheme.surfaceOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSheet)),
        title: Text('Reveal contact details', style: AppTheme.sectionTitle()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will use 1 contact credit to reveal the phone number and email for '
              '$candidateName.',
              style: AppTheme.body(),
            ),
            const SizedBox(height: 12),
            MetaText('$remaining credits remaining after this'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
            child: const Text('Reveal'),
          ),
        ],
      );
}

// =============================================================================
// AI ENTRY POINT — the hardest object in an achromatic system.
//
// An AI affordance normally wants exactly what this system forbids: a gradient,
// a sparkle, decoration. Dropping that in would be the stray coloured button
// that makes every other hue on screen stop meaning anything.
//
// The resolution: the mark is drawn in ink like everything else, and the ONE
// gradient touch is a small dot that indicates AI availability. That dot is not
// decoration — it is state. Live AI, brand ramp. No credits or AI disabled, the
// dot goes to faint ink and the label says why. Colour still means something,
// and the brand still gets its moment.
// =============================================================================

enum AiAvailability { live, noCredits, disabled }

class AiEntryPoint extends StatelessWidget {
  final AiAvailability availability;
  final VoidCallback? onTap;
  final bool compact;

  const AiEntryPoint({
    super.key,
    required this.availability,
    this.onTap,
    this.compact = false,
  });

  String get _unavailableReason {
    switch (availability) {
      case AiAvailability.noCredits:
        return 'AI credits exhausted';
      case AiAvailability.disabled:
        return 'AI is turned off for your plan';
      case AiAvailability.live:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = availability == AiAvailability.live;

    final mark = Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.auto_awesome_outlined,
            size: compact ? 17 : 19, color: live ? AppTheme.ink : AppTheme.inkFaintOf(context)),
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: live ? AppTheme.brandRule : null,
              color: live ? null : AppTheme.inkFaintOf(context),
            ),
          ),
        ),
      ],
    );

    if (compact) {
      return Tooltip(
        message: live ? 'Lucky AI' : _unavailableReason,
        child: InkWell(
          onTap: live ? onTap : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          child: SizedBox(width: 44, height: 44, child: Center(child: mark)),
        ),
      );
    }

    return InkWell(
      onTap: live ? onTap : null,
      borderRadius: BorderRadius.circular(AppTheme.radiusControl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceOf(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusControl),
          border: Border.all(color: AppTheme.ruleOf(context), width: AppTheme.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            mark,
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Lucky AI',
                    style: AppTheme.button(color: live ? AppTheme.ink : AppTheme.inkFaintOf(context))),
                if (!live) ...[
                  const SizedBox(height: 1),
                  MetaText(_unavailableReason, size: 9),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// LOCKED ACTION — a feature the plan does not include.
//
// Hidden features lose the upgrade prompt and confuse anyone who read the
// pricing page. So they stay visible, greyed, with the reason attached.
// =============================================================================

class LockedActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onUpgrade;

  const LockedActionTile({super.key, required this.icon, required this.label, this.onUpgrade});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: ListTile(
          enabled: false,
          leading: Icon(icon, size: 19, color: AppTheme.inkFaintOf(context)),
          title: Text(label, style: AppTheme.body(color: AppTheme.inkFaintOf(context))),
          trailing: TextButton(
            onPressed: onUpgrade,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.signalAttention,
              textStyle: AppTheme.meta(color: AppTheme.signalAttention, size: 10),
            ),
            child: const Text('UPGRADE'),
          ),
        ),
      );
}

// =============================================================================
// EMPTY STATE — three tabs means three different kinds of nothing, and they
// need different explanations. "No candidates" is useless in all three cases.
// =============================================================================

class LedgerEmptyState extends StatelessWidget {
  final String headline;
  final String explanation;
  final Widget? action;

  const LedgerEmptyState({
    super.key,
    required this.headline,
    required this.explanation,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 28, height: AppTheme.hairline, color: AppTheme.ruleOf(context)),
              const SizedBox(height: 18),
              Text(headline, style: AppTheme.sectionTitle(), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(explanation, style: AppTheme.body(), textAlign: TextAlign.center),
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      );
}
