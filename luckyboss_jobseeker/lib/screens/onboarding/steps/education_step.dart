import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/onboarding_model.dart';
import '../../../widgets/onboarding_components.dart';

/// Education details, revealed progressively.
///
/// Opens as a single question — highest qualification — and only unfolds the
/// rest once that is answered. The follow-ups differ by answer: Class XII needs
/// a board and language medium, a Graduate needs a course and specialisation.
/// Showing all of them at once would put irrelevant fields in front of every
/// candidate and make the form feel longer than it is.
class EducationStep extends StatelessWidget {
  final OnboardingData data;
  final VoidCallback onChanged;

  const EducationStep({super.key, required this.data, required this.onChanged});

  static const List<String> _boards = [
    'CBSE', 'ICSE', 'State Board', 'IB', 'IGCSE', 'Other',
  ];

  static const List<String> _mediums = [
    'English', 'Hindi', 'Tamil', 'Malay', 'Mandarin', 'Other',
  ];

  static const List<String> _courses = [
    'B.E / B.Tech', 'B.Sc', 'B.Com', 'BBA / BMS', 'BCA', 'B.A',
    'M.E / M.Tech', 'M.Sc', 'M.Com', 'MBA / PGDM', 'MCA', 'Diploma', 'Other',
  ];

  /// Passing years, newest first — a recent graduate finds theirs immediately
  /// instead of scrolling past decades they were not alive for.
  List<String> get _years {
    final now = DateTime.now().year;
    return List.generate(52, (i) => '${now + 1 - i}');
  }

  @override
  Widget build(BuildContext context) {
    final q = data.qualification;
    final chosen = q != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Education',
            style: AppTheme.serifTitle(fontSize: 26, color: AppTheme.inkOf(context))),
        const SizedBox(height: 6),
        Text(
          'These details help employers understand your background.',
          style: AppTheme.sansRegular(fontSize: 14, color: AppTheme.inkMutedOf(context)),
        ),
        const SizedBox(height: 24),

        RevealedField(
          label: 'Highest qualification *',
          child: Wrap(
            spacing: 9,
            runSpacing: 10,
            children: Qualification.values
                .map((value) => LbChoiceChip(
                      label: value.label,
                      selected: q == value,
                      showAffordance: q == value,
                      onTap: () {
                        // Switching qualification clears the answers that
                        // belonged to the previous branch. Leaving a CBSE board
                        // attached to an MBA would quietly ship nonsense to
                        // employers.
                        if (data.qualification != value) {
                          data.examinationBoard = '';
                          data.languageMedium = '';
                          data.course = '';
                          data.specialisation = '';
                        }
                        data.qualification = value;
                        onChanged();
                      },
                    ))
                .toList(),
          ),
        ),

        if (chosen && q.isSchoolLevel) ...[
          RevealedField(
            label: 'Examination board *',
            child: _wrapOf(_boards, data.examinationBoard, (v) {
              data.examinationBoard = v;
              onChanged();
            }),
          ),
          RevealedField(
            label: 'Language medium *',
            child: _wrapOf(_mediums, data.languageMedium, (v) {
              data.languageMedium = v;
              onChanged();
            }),
          ),
        ],

        if (chosen && !q.isSchoolLevel) ...[
          RevealedField(
            label: 'Course *',
            child: _wrapOf(_courses, data.course, (v) {
              data.course = v;
              onChanged();
            }),
          ),
          RevealedField(
            label: 'Specialisation',
            child: _textField(
              context,
              value: data.specialisation,
              hint: 'e.g. Computer Science, Finance, Mechanical',
              onChanged: (v) {
                data.specialisation = v;
                onChanged();
              },
            ),
          ),
        ],

        if (chosen)
          RevealedField(
            label: 'Passing year *',
            child: _yearPicker(context),
          ),

        if (chosen)
          RevealedField(
            label: q.isSchoolLevel ? 'Percentage of marks' : 'CGPA or percentage',
            child: _textField(
              context,
              value: data.marks,
              hint: q.isSchoolLevel ? 'e.g. 81.0' : 'e.g. 8.4 or 78%',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) {
                data.marks = v;
                onChanged();
              },
            ),
          ),
      ],
    );
  }

  Widget _wrapOf(List<String> options, String current, ValueChanged<String> onPick) {
    return Wrap(
      spacing: 9,
      runSpacing: 10,
      children: options
          .map((o) => LbChoiceChip(
                label: o,
                selected: current == o,
                showAffordance: current == o,
                // Tapping the chosen chip clears it, so a mis-tap is undoable
                // without hunting for a reset control.
                onTap: () => onPick(current == o ? '' : o),
              ))
          .toList(),
    );
  }

  Widget _yearPicker(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: data.passingYear.isEmpty ? null : data.passingYear,
          hint: Text('Select year',
              style: AppTheme.sansRegular(fontSize: 14.5, color: AppTheme.inkFaintOf(context))),
          borderRadius: BorderRadius.circular(14),
          icon: Icon(Icons.expand_more, size: 20, color: AppTheme.inkMutedOf(context)),
          items: _years
              .map((y) => DropdownMenuItem(
                    value: y,
                    child: Text(y,
                        style: AppTheme.sansMedium(
                            fontSize: 14.5, color: AppTheme.inkOf(context))),
                  ))
              .toList(),
          onChanged: (v) {
            data.passingYear = v ?? '';
            onChanged();
          },
        ),
      ),
    );
  }

  Widget _textField(
    BuildContext context, {
    required String value,
    required String hint,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      // The key ties the field's state to the branch it belongs to, so
      // switching qualification rebuilds it empty rather than carrying the old
      // branch's text across.
      key: ValueKey('$hint-${data.qualification?.name}'),
      initialValue: value,
      keyboardType: keyboardType,
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
