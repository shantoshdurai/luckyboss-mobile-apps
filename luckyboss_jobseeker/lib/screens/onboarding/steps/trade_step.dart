import 'package:flutter/material.dart';

import '../../../core/constants/app_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/onboarding_model.dart';
import '../../../widgets/onboarding_components.dart';
import '../../../widgets/searchable_chip_picker.dart';

/// The field-work counterpart to [KeySkillsStep]: trade, years, work done, cards.
///
/// The screen it replaces asked every candidate to type their "key skills" into
/// a chip field. That works for a developer who thinks in named technologies. It
/// does not work for a mason, who does not have a list of skills in mind and has
/// no idea what the app is expecting — so the field stays empty, the profile
/// scores nothing, and no employer ever sees them.
///
/// Here nothing has to be typed at all. The trade is a tap, the years are a tap,
/// the work and the cards are taps from the vocabulary of that specific trade.
/// A candidate who does not read English well can still complete this screen,
/// and the profile that comes out the other side is richer than the one the
/// chip field was producing.
class TradeStep extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onChanged;

  const TradeStep({super.key, required this.data, required this.onChanged});

  @override
  State<TradeStep> createState() => _TradeStepState();
}

class _TradeStepState extends State<TradeStep> {
  // Anchors for the questions that appear once the trade is picked, so the app
  // scrolls to them rather than leaving the candidate to find them.
  final GlobalKey _yearsKey = GlobalKey();
  final GlobalKey _abilitiesKey = GlobalKey();

  OnboardingData get data => widget.data;
  void onChanged() => widget.onChanged();

  /// Years offered as buckets rather than a number pad. Nobody knows whether
  /// they have done seven years or eight, and a keyboard on this screen is a
  /// wall in front of a candidate who is otherwise only tapping.
  static const List<(String, int)> years = [
    ('No experience', 0),
    ('Under 1 year', 1),
    ('1–3 years', 2),
    ('3–5 years', 4),
    ('5–10 years', 7),
    ('Over 10 years', 12),
  ];

  @override
  Widget build(BuildContext context) {
    final category = data.workCategory;
    if (category == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(category.icon, size: 24, color: AppTheme.signalSource),
            const SizedBox(width: 10),
            Expanded(
              child: Text(category.name,
                  style: AppTheme.sansSemiBold(
                      fontSize: 14, color: AppTheme.signalSource)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text('What is your work?',
            style: AppTheme.serifTitle(fontSize: 26, color: AppTheme.inkOf(context))),
        const SizedBox(height: 6),
        Text(
          'Tap what you do. Employers search by this.',
          style: AppTheme.sansRegular(fontSize: 14, color: AppTheme.inkMutedOf(context)),
        ),
        const SizedBox(height: 24),

        // Searchable, and it takes a typed trade — the separate "Not in the
        // list? Type it" box this replaces sat below a wall of chips, so it was
        // only found by the people who had already given up scrolling.
        RevealedField(
          label: 'Your job *',
          child: SearchableChipPicker(
            options: category.roleNames,
            selected: {if (data.roleTitle.isNotEmpty) data.roleTitle},
            single: true,
            searchHint: 'Search trades, or type your own',
            onToggle: (r) {
              data.roleTitle = data.roleTitle == r ? '' : r;
              onChanged();
              if (data.roleTitle.isNotEmpty) revealNextQuestion(_yearsKey);
            },
          ),
        ),

        RevealedField(
          key: _yearsKey,
          label: 'How long have you done this work?',
          visible: data.roleTitle.isNotEmpty,
          child: _chips(
            years.map((y) => y.$1).toList(),
            isSelected: (label) =>
                data.yearsInTrade == years.firstWhere((y) => y.$1 == label).$2,
            onTap: (label) {
              data.yearsInTrade = years.firstWhere((y) => y.$1 == label).$2;
              onChanged();
              revealNextQuestion(_abilitiesKey);
            },
            single: true,
          ),
        ),

        RevealedField(
          key: _abilitiesKey,
          label: 'What can you do? Pick everything that applies',
          visible: data.roleTitle.isNotEmpty,
          // Once a role is picked these narrow to that role's own work, so a
          // plumber is offered pipe fitting and leak repairs rather than every
          // task anyone on a construction site performs.
          child: SearchableChipPicker(
            options:
                AppData.abilitiesFor(category: category.name, role: data.roleTitle),
            selected: data.skills.toSet(),
            searchHint: 'Search the work you do, or type it',
            onToggle: (a) {
              if (!data.skills.remove(a)) data.skills.add(a);
              onChanged();
            },
          ),
        ),

        if (_certificates(category).isNotEmpty)
          RevealedField(
            label: 'Licences and cards for a ${data.roleTitle}',
            visible: data.roleTitle.isNotEmpty,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'These get you shortlisted faster than anything else on your '
                  'profile. Leave blank if you have none.',
                  style: AppTheme.sansRegular(
                      fontSize: 12.5, color: AppTheme.inkFaintOf(context)),
                ),
                const SizedBox(height: 10),
                SearchableChipPicker(
                  options: _certificates(category),
                  selected: data.certificates,
                  searchHint: 'Search licences, or type one',
                  onToggle: (c) {
                    if (!data.certificates.remove(c)) data.certificates.add(c);
                    onChanged();
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Licences for the chosen role only.
  ///
  /// Deliberately not widened to the category. Showing a plumber a crane
  /// operator licence is not a harmless extra option — it is the app saying it
  /// does not know what his job is.
  List<String> _certificates(WorkCategory category) =>
      AppData.certificatesFor(category: category.name, role: data.roleTitle);

  Widget _chips(
    List<String> options, {
    required bool Function(String) isSelected,
    required ValueChanged<String> onTap,
    bool single = false,
  }) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in options)
            LbChoiceChip(
              label: option,
              selected: isSelected(option),
              showAffordance: !single,
              onTap: () => onTap(option),
            ),
        ],
      );
}
