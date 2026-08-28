import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A selectable option chip.
///
/// Two states carry different affordances on purpose: unselected shows `+`
/// (add this), selected shows `×` (remove it). An unlabelled filled/outlined
/// pair leaves the user guessing whether tapping selects or deselects — the
/// icon says which, so the chip is readable without experimenting.
class LbChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Hides the +/× icon. Used where the chip is a single-answer choice rather
  /// than a multi-select, and the icon would imply a list.
  final bool showAffordance;

  const LbChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showAffordance = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: EdgeInsets.only(
            left: 16,
            right: showAffordance ? 10 : 16,
            top: 10,
            bottom: 10,
          ),
          decoration: BoxDecoration(
            color: selected ? AppTheme.signalPositiveWash : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selected ? AppTheme.signalPositive : Theme.of(context).dividerColor,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: selected
                      ? AppTheme.sansSemiBold(fontSize: 14, color: AppTheme.signalPositive)
                      : AppTheme.sansMedium(fontSize: 14, color: AppTheme.inkOf(context)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showAffordance) ...[
                const SizedBox(width: 7),
                Icon(
                  selected ? Icons.close : Icons.add,
                  size: 16,
                  color: selected ? AppTheme.signalPositive : AppTheme.inkFaintOf(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The "Autofill with AI" banner that sits above every wizard step.
///
/// Persistent rather than a one-time offer on the first screen: a candidate
/// three questions deep who realises they would rather upload their CV should
/// not have to go back to find the option.
class AiAutofillBanner extends StatelessWidget {
  final VoidCallback onUpload;
  final bool busy;
  final String? fileName;

  const AiAutofillBanner({
    super.key,
    required this.onUpload,
    this.busy = false,
    this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    final done = fileName != null && !busy;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: done ? AppTheme.signalPositiveWash : AppTheme.signalSourceWash,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done ? AppTheme.signalPositive : AppTheme.signalSource,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_outline : Icons.auto_awesome,
            size: 20,
            color: done ? AppTheme.signalPositive : AppTheme.signalSource,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done ? 'Filled from your resume' : 'Autofill with AI',
                  style: AppTheme.sansBold(
                    fontSize: 14.5,
                    color: done ? AppTheme.signalPositive : AppTheme.signalSource,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  done
                      ? '$fileName — check the details below and correct anything wrong.'
                      : 'Upload your resume and we will fill this in. You can review and edit it after.',
                  style: AppTheme.sansRegular(fontSize: 12.5, color: AppTheme.inkMutedOf(context)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppTheme.signalSource),
              ),
            )
          else
            OutlinedButton(
              onPressed: onUpload,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide(
                  color: done ? AppTheme.signalPositive : AppTheme.signalSource,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                done ? 'Replace' : 'Upload resume',
                style: AppTheme.sansBold(
                  fontSize: 13,
                  color: done ? AppTheme.signalPositive : AppTheme.signalSource,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A labelled question block that only appears once its prerequisite is answered.
///
/// Progressive disclosure is what keeps the education step from opening as a
/// wall of eight fields: pick Class XII, and only then are board, medium,
/// passing year and marks revealed.
class RevealedField extends StatelessWidget {
  final String label;
  final bool visible;
  final Widget child;

  const RevealedField({
    super.key,
    required this.label,
    required this.child,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: !visible
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTheme.sansMedium(fontSize: 13, color: AppTheme.inkMutedOf(context)),
                  ),
                  const SizedBox(height: 10),
                  child,
                ],
              ),
            ),
    );
  }
}

/// Step counter and rule shown at the top of the wizard.
class WizardProgress extends StatelessWidget {
  final int step;
  final int total;
  final String label;

  const WizardProgress({
    super.key,
    required this.step,
    required this.total,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Step $step of $total',
              style: AppTheme.sansBold(fontSize: 12, color: AppTheme.inkFaintOf(context)),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.sansRegular(fontSize: 12, color: AppTheme.inkFaintOf(context)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: step / total,
            minHeight: 3,
            backgroundColor: Theme.of(context).dividerColor,
            valueColor: const AlwaysStoppedAnimation(AppTheme.signalPositive),
          ),
        ),
      ],
    );
  }
}

/// A large, tappable branch card — the student / working choice.
class TrackCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const TrackCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected ? AppTheme.signalPositiveWash : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppTheme.signalPositive : Theme.of(context).dividerColor,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.sansBold(
                        fontSize: 15.5,
                        color: selected ? AppTheme.signalPositive : AppTheme.inkOf(context),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: AppTheme.sansRegular(fontSize: 13, color: AppTheme.inkMutedOf(context)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Icon(
                selected ? Icons.check_circle : icon,
                size: 26,
                color: selected ? AppTheme.signalPositive : AppTheme.inkFaintOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
