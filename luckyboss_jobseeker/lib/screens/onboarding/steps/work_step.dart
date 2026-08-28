import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/onboarding_model.dart';
import '../../../widgets/onboarding_components.dart';

/// Current or most recent employment — the working-track counterpart to
/// [EducationStep].
///
/// A candidate with a job title gives employers a far stronger matching signal
/// than a degree does, which is why this branch asks for the title first and
/// treats education as optional detail to be added later from the profile.
class WorkStep extends StatelessWidget {
  final OnboardingData data;
  final VoidCallback onChanged;

  const WorkStep({super.key, required this.data, required this.onChanged});

  /// Notice period drives when a candidate can actually start, which is one of
  /// the first things a recruiter filters on.
  static const List<String> _noticePeriods = [
    'Immediately', '15 days', '1 month', '2 months', '3 months', 'Serving notice',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your work',
            style: AppTheme.serifTitle(fontSize: 26, color: AppTheme.inkOf(context))),
        const SizedBox(height: 6),
        Text(
          'Tell us what you do now, or what you did most recently.',
          style: AppTheme.sansRegular(fontSize: 14, color: AppTheme.inkMutedOf(context)),
        ),
        const SizedBox(height: 24),

        RevealedField(
          label: 'Current or most recent job title *',
          child: _field(
            context,
            id: 'title',
            value: data.currentTitle,
            hint: 'e.g. Warehouse Supervisor, Staff Nurse, Flutter Developer',
            capitalise: true,
            onChanged: (v) {
              data.currentTitle = v;
              onChanged();
            },
          ),
        ),

        RevealedField(
          label: 'Company',
          child: _field(
            context,
            id: 'company',
            value: data.currentCompany,
            hint: 'Where you work, or last worked',
            capitalise: true,
            onChanged: (v) {
              data.currentCompany = v;
              onChanged();
            },
          ),
        ),

        RevealedField(
          label: 'Total experience *',
          child: _experienceStepper(context),
        ),

        RevealedField(
          label: 'Notice period',
          child: Wrap(
            spacing: 9,
            runSpacing: 10,
            children: _noticePeriods
                .map((p) => LbChoiceChip(
                      label: p,
                      selected: data.noticePeriod == p,
                      showAffordance: data.noticePeriod == p,
                      onTap: () {
                        data.noticePeriod = data.noticePeriod == p ? '' : p;
                        onChanged();
                      },
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  /// Years of experience as a stepper rather than a text field.
  ///
  /// A free-text number invites "3.5", "3 yrs", "three" — three unparseable
  /// forms of the same answer, on a field that feeds match scoring.
  Widget _experienceStepper(BuildContext context) {
    final years = data.yearsExperience;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: years > 0
                ? () {
                    data.yearsExperience = years - 1;
                    onChanged();
                  }
                : null,
            icon: const Icon(Icons.remove_circle_outline, size: 22),
            color: AppTheme.inkOf(context),
            disabledColor: Theme.of(context).dividerColor,
          ),
          Expanded(
            child: Center(
              child: Text(
                years == 0
                    ? 'Less than a year'
                    : '$years ${years == 1 ? "year" : "years"}${years >= 30 ? "+" : ""}',
                style: AppTheme.sansBold(fontSize: 15, color: AppTheme.inkOf(context)),
              ),
            ),
          ),
          IconButton(
            onPressed: years < 30
                ? () {
                    data.yearsExperience = years + 1;
                    onChanged();
                  }
                : null,
            icon: const Icon(Icons.add_circle_outline, size: 22),
            color: AppTheme.inkOf(context),
            disabledColor: Theme.of(context).dividerColor,
          ),
        ],
      ),
    );
  }

  Widget _field(
    BuildContext context, {
    required String id,
    required String value,
    required String hint,
    required ValueChanged<String> onChanged,
    bool capitalise = false,
  }) {
    return TextFormField(
      key: ValueKey('work-$id'),
      initialValue: value,
      textCapitalization:
          capitalise ? TextCapitalization.words : TextCapitalization.none,
      onChanged: onChanged,
      style: AppTheme.sansMedium(fontSize: 15, color: AppTheme.inkOf(context)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.sansRegular(fontSize: 14.5, color: AppTheme.inkFaintOf(context)),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.inkOf(context), width: 1.6),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
