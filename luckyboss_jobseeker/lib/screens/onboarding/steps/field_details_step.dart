import 'package:flutter/material.dart';

import '../../../core/constants/app_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/onboarding_model.dart';
import '../../../widgets/city_field.dart';
import '../../../widgets/onboarding_components.dart';

/// The rest of what an employer needs before they will call a field worker.
///
/// Every question here comes from spec §31 — Languages, Preferred Location,
/// Preferred Salary, Availability, Work Permit Information — and none of them
/// were being asked anywhere in the app. For an agency placing across
/// Singapore, Malaysia and India these are not profile decoration:
///
/// * **Work permit status** decides whether a candidate can be put forward at
///   all, and it is asked as a status rather than a yes/no because "needs
///   sponsorship" and "holds a valid permit" are entirely different
///   propositions to an employer that a boolean flattens into the same answer.
/// * **Languages** decide most domestic, care and service placements outright.
/// * **Pay** is asked with its period attached. A site worker quotes a day rate.
///   A monthly-only field either gets left blank or gets a daily number typed
///   into it, which is worse than blank.
class FieldDetailsStep extends StatefulWidget {
  final OnboardingData data;
  final TextEditingController cityController;
  final VoidCallback onChanged;

  const FieldDetailsStep({
    super.key,
    required this.data,
    required this.cityController,
    required this.onChanged,
  });

  @override
  State<FieldDetailsStep> createState() => _FieldDetailsStepState();
}

class _FieldDetailsStepState extends State<FieldDetailsStep> {
  // Anchors so answering one question scrolls to the next, the same as the
  // trade step. This screen had none, which is the inconsistency Shantosh
  // noticed: *"the flawless animation one after another is on one tab but not
  // on others."*
  final GlobalKey _countriesKey = GlobalKey();
  final GlobalKey _permitKey = GlobalKey();
  final GlobalKey _languagesKey = GlobalKey();
  final GlobalKey _payKey = GlobalKey();
  final GlobalKey _availabilityKey = GlobalKey();

  OnboardingData get data => widget.data;
  TextEditingController get cityController => widget.cityController;
  void onChanged() => widget.onChanged();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('A few last things',
            style: AppTheme.serifTitle(fontSize: 26, color: AppTheme.inkOf(context))),
        const SizedBox(height: 6),
        Text(
          'This is what employers ask us before they call you.',
          style: AppTheme.sansRegular(fontSize: 14, color: AppTheme.inkMutedOf(context)),
        ),
        const SizedBox(height: 24),

        RevealedField(
          label: 'Where are you now? *',
          child: CityField(
            controller: cityController,
            hint: 'City or town',
            onChanged: (v) {
              data.currentCity = v;
              onChanged();
            },
            onSubmitted: (_) => revealNextQuestion(_countriesKey),
          ),
        ),

        // Multi-select. Somebody willing to work in Singapore *and* Malaysia
        // should not have to pick a favourite — it halves the jobs we can put
        // in front of them for no benefit to anyone.
        RevealedField(
          key: _countriesKey,
          label: 'Which countries can you work in?',
          child: _chips(
            AppData.countries.map((c) => c['name']!).toList(),
            isSelected: (name) => data.preferredCountries.contains(_codeFor(name)),
            onTap: (name) {
              final code = _codeFor(name);
              if (!data.preferredCountries.remove(code)) {
                data.preferredCountries.add(code);
              }
              onChanged();
            },
          ),
        ),

        RevealedField(
          key: _permitKey,
          label: 'Can you work there?',
          child: _chips(
            AppData.workPermitStatuses,
            isSelected: data.workPermitStatuses.contains,
            onTap: (s) {
              if (!data.workPermitStatuses.remove(s)) {
                data.workPermitStatuses.add(s);
              }
              // Kept in step with the older boolean the matching engine
              // still reads. True if *any* answer means they can already work.
              const allowed = {
                'Citizen',
                'Permanent Resident',
                'Have a valid work permit',
                'Have an employment pass',
              };
              data.hasWorkPermit = data.workPermitStatuses.isEmpty
                  ? null
                  : data.workPermitStatuses.any(allowed.contains);
              onChanged();
            },
          ),
        ),

        RevealedField(
          key: _languagesKey,
          label: 'What languages do you speak?',
          child: _chips(
            AppData.commonLanguages,
            isSelected: data.languages.contains,
            onTap: (l) {
              if (!data.languages.remove(l)) data.languages.add(l);
              onChanged();
            },
          ),
        ),

        RevealedField(
          key: _payKey,
          label: 'How much do you expect to be paid?',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _chips(
                AppData.payPeriods,
                isSelected: (p) => data.payPeriod == p,
                onTap: (p) {
                  data.payPeriod = p;
                  onChanged();
                },
                single: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: data.expectedSalary,
                keyboardType: TextInputType.number,
                style: AppTheme.sansMedium(
                    fontSize: 15, color: AppTheme.inkOf(context)),
                decoration: InputDecoration(
                  hintText: 'Amount',
                  hintStyle: AppTheme.sansRegular(
                      fontSize: 14, color: AppTheme.inkFaintOf(context)),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) {
                  data.expectedSalary = v.trim();
                  onChanged();
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Leave blank if you would rather discuss it.',
                style: AppTheme.sansRegular(
                    fontSize: 12.5, color: AppTheme.inkFaintOf(context)),
              ),
            ],
          ),
        ),

        RevealedField(
          key: _availabilityKey,
          label: 'When can you start?',
          child: _chips(
            AppData.availabilityOptions,
            isSelected: (a) => data.availability == a,
            onTap: (a) {
              data.availability = data.availability == a ? '' : a;
              onChanged();
              if (data.availability.isNotEmpty) revealNextQuestion(_payKey);
            },
            single: true,
          ),
        ),

        RevealedField(
          label: 'Would you move to another city for work?',
          child: _chips(
            const ['Yes', 'No'],
            isSelected: (v) => data.openToRelocate == (v == 'Yes'),
            onTap: (v) {
              final answer = v == 'Yes';
              data.openToRelocate = data.openToRelocate == answer ? null : answer;
              onChanged();
            },
            single: true,
          ),
        ),

        RevealedField(
          label: 'About You (Optional)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: data.bio,
                maxLines: 3,
                style: AppTheme.sansMedium(
                    fontSize: 14, color: AppTheme.inkOf(context)),
                decoration: InputDecoration(
                  hintText: 'Brief summary of your experience, skills, or what you are looking for...',
                  hintStyle: AppTheme.sansRegular(
                      fontSize: 13, color: AppTheme.inkFaintOf(context)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (v) {
                  data.bio = v.trim();
                  onChanged();
                },
              ),
              const SizedBox(height: 6),
              Text(
                'Tell employers about your strengths or background in a few words.',
                style: AppTheme.sansRegular(
                    fontSize: 12, color: AppTheme.inkFaintOf(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _codeFor(String name) => AppData.countries
      .firstWhere((c) => c['name'] == name, orElse: () => const {})['code'] ??
      '';

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
