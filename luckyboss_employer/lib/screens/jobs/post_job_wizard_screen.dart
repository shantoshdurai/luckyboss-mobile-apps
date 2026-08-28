import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_data.dart';
import '../../core/theme/app_theme.dart';
import '../../models/employer_job.dart';
import '../../providers/employer_provider.dart';
import '../../widgets/city_field.dart';
import '../../widgets/onboarding_components.dart';
import '../../widgets/searchable_chip_picker.dart';

/// Posting a vacancy, rebuilt as the mirror of the candidate's onboarding.
///
/// The wizard this replaces was one long form of free-text fields: a title box,
/// a category dropdown, a salary pair and a description. Three things were
/// wrong with it, and they are the same three things that were wrong on the
/// seeker side.
///
/// **It could not describe field work.** There was nowhere to say a rate was
/// per day, that accommodation came with the job, that a work permit would be
/// sponsored, or that a forklift licence was required. For most of what this
/// agency places, that is the posting.
///
/// **Free text broke matching.** A title typed as "fork lift driver" is the
/// same job as "Forklift Driver" to a person and a different string to a
/// scorer. The trade is now chosen from the same 119-role taxonomy the seeker
/// app builds profiles from, so both sides describe work identically and a
/// match percentage means something.
///
/// **It asked an employer to write the requirements from memory.** Picking the
/// role now offers exactly the tasks and licences that trade uses.
class PostJobWizardScreen extends StatefulWidget {
  const PostJobWizardScreen({super.key});

  @override
  State<PostJobWizardScreen> createState() => _PostJobWizardScreenState();
}

class _PostJobWizardScreenState extends State<PostJobWizardScreen> {
  final PageController _pager = PageController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  int _step = 0;
  static const int _totalSteps = 4;

  // Anchors for questions revealed by an earlier answer, so the wizard scrolls
  // to them. Picking an industry used to reveal "Which job?" below the fold —
  // every posting began with a hunt for a question that had just appeared.
  final GlobalKey _roleKey = GlobalKey();
  final GlobalKey _vacanciesKey = GlobalKey();
  final GlobalKey _cityKey = GlobalKey();
  final GlobalKey _payPeriodKey = GlobalKey();

  static const List<String> _labels = [
    'The work',
    'Requirements',
    'Pay & place',
    'Details',
  ];

  // --- answers ---
  String _category = '';
  String _role = '';
  final Set<String> _skills = {};
  final Set<String> _certificates = {};
  String _country = 'SG';
  String _payPeriod = 'Per month';
  String _workMode = 'On-site';
  final Set<String> _selectedShifts = {};
  int _vacancies = 1;
  bool _accommodation = false;
  bool _transport = false;
  bool _permitSponsored = false;
  bool _training = false;

  static const List<String> _shifts = [
    'Day shift',
    'Night shift',
    'Rotating two-shift',
    'Split shift',
    'Twelve-hour shifts',
    'Five and a half days a week',
    'Six days a week with one rest day',
  ];

  WorkCategory? get _workCategory => AppData.categoryByName(_category);

  bool get _canAdvance => switch (_step) {
        0 => _category.isNotEmpty && _role.isNotEmpty,
        1 => true,
        2 => _cityController.text.trim().isNotEmpty,
        3 => true,
        _ => false,
      };

  @override
  void dispose() {
    _pager.dispose();
    _cityController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  void _next() {
    if (!_canAdvance) return;
    _dismissKeyboard();
    if (_step == _totalSteps - 1) {
      _publish();
      return;
    }
    setState(() => _step++);
    _pager.animateToPage(_step,
        duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
  }

  void _back() {
    _dismissKeyboard();
    if (_step == 0) {
      Navigator.maybePop(context);
      return;
    }
    setState(() => _step--);
    _pager.animateToPage(_step,
        duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
  }

  String get _currency => AppData.countries
      .firstWhere((c) => c['code'] == _country,
          orElse: () => const {'currency': 'SGD'})['currency']!;

  void _publish() {
    final provider = context.read<EmployerProvider>();

    // A vacancy with no employer on it is not publishable. A candidate cannot
    // decide whether to apply to nobody, and the seeker app has nothing to put
    // on the card.
    if (provider.company.name.trim().isEmpty) {
      _askCompanyName(provider);
      return;
    }

    final title = _titleController.text.trim();

    provider.postJob(EmployerJobModel(
      id: 'job-${DateTime.now().microsecondsSinceEpoch}',
      role: _role,
      title: title.isEmpty ? _role : title,
      category: _category,
      // Identity travels with the posting. Reading `company.name` alone was
      // not enough: it is empty for anyone who has not filled in their profile,
      // and nothing made them, so jobs were being posted anonymously.
      companyId: provider.companyId,
      companyName: provider.company.name,
      companyLogoUrl: provider.company.logoUrl,
      companyVerified: provider.company.isVerified,
      companyType: provider.company.type,
      location: _cityController.text.trim(),
      countryCode: _country,
      minSalary: _minController.text.trim(),
      maxSalary: _maxController.text.trim(),
      currency: _currency,
      payPeriod: _payPeriod,
      workMode: _workMode,
      shift: _selectedShifts.join(', '),
      description: _descriptionController.text.trim(),
      requiredSkills: _skills.toList(),
      requiredCertificates: _certificates.toList(),
      accommodationProvided: _accommodation,
      transportProvided: _transport,
      permitSponsored: _permitSponsored,
      trainingProvided: _training,
      vacancies: _vacancies,
      // An unverified company saves a draft rather than publishing.
      //
      // Not a refusal — losing four screens of work at the last button is the
      // worst possible place to enforce this, and the vacancy is perfectly
      // good. It simply does not reach candidates until Lucky Boss has checked
      // who is hiring, which is the whole product.
      status: provider.canPost ? JobStatus.published : JobStatus.draft,
      postedDate: DateTime.now(),
    ));

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.canPost
              ? '$_role posted. Matching candidates are ready now.'
              : '$_role saved as a draft. It goes live the moment your '
                  'company is verified.',
          style: AppTheme.sansMedium(
              fontSize: 13, color: AppTheme.onInkOf(context)),
        ),
        backgroundColor: provider.canPost
            ? AppTheme.signalPositive
            : AppTheme.signalAttention,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Collects the company name at the last possible moment, for an employer who
  /// reached Post without filling in their profile.
  ///
  /// Better than a validation error pointing at another screen: they are one
  /// field away from finishing, and sending them to Settings to come back loses
  /// the posting.
  Future<void> _askCompanyName(EmployerProvider provider) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Who is hiring?',
            style: AppTheme.sansBold(
                fontSize: 16, color: AppTheme.inkOf(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Candidates see this on the job. We cannot post a vacancy '
              'without it.',
              style: AppTheme.sansRegular(
                  fontSize: 13, color: AppTheme.inkMutedOf(context)),
            ),
            const SizedBox(height: 12),
            TextField(
                            textInputAction: TextInputAction.done,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  hintText: 'e.g. Ravi Constructions Pte Ltd'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTheme.sansMedium(
                    fontSize: 14, color: AppTheme.inkMutedOf(context))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text('Save & post',
                style: AppTheme.sansBold(
                    fontSize: 14, color: AppTheme.signalSource)),
          ),
        ],
      ),
    );

    if (!mounted || name == null || name.isEmpty) return;
    provider.updateCompany(provider.company.copyWith(name: name));
    if (!mounted) return;
    _publish();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paperOf(context),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.inkOf(context)),
          onPressed: _back,
        ),
        title: WizardProgress(
          step: _step + 1,
          total: _totalSteps,
          label: _labels[_step],
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pager,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _scroll(_workStep()),
                  _scroll(_requirementsStep()),
                  _scroll(_payStep()),
                  _scroll(_detailsStep()),
                ],
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _scroll(Widget child) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: child,
      );

  // ---------------------------------------------------------------- step one

  Widget _workStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('What work are you hiring for?'),
        _subtitle('Pick the trade. Candidates search by exactly this.'),
        const SizedBox(height: 20),

        RevealedField(
          label: 'Industry *',
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AppData.workCategories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.5,
            ),
            itemBuilder: (context, i) {
              final category = AppData.workCategories[i];
              final selected = category.name == _category;
              return InkWell(
                onTap: () {
                  setState(() {
                    if (_category != category.name) {
                      // The old role belongs to a vocabulary that no longer
                      // applies. Keeping it would post a Plumber under Security.
                      _role = '';
                      _skills.clear();
                      _certificates.clear();
                    }
                    _category = category.name;
                  });
                  revealNextQuestion(_roleKey);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.signalSource.withValues(alpha: 0.08)
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? AppTheme.signalSource
                          : Theme.of(context).dividerColor,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(category.icon,
                          size: 20,
                          color: selected
                              ? AppTheme.signalSource
                              : AppTheme.inkMutedOf(context)),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(category.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.sansSemiBold(
                                fontSize: 12.5,
                                color: selected
                                    ? AppTheme.signalSource
                                    : AppTheme.inkOf(context))),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        RevealedField(
          key: _roleKey,
          label: 'Which job? *',
          visible: _workCategory != null,
          child: SearchableChipPicker(
            options: _workCategory?.roleNames ?? const [],
            selected: {if (_role.isNotEmpty) _role},
            single: true,
            searchHint: 'Search trades, or type your own',
            onToggle: (r) {
              setState(() {
                _role = _role == r ? '' : r;
                _skills.clear();
                _certificates.clear();
              });
              if (_role.isNotEmpty) revealNextQuestion(_vacanciesKey);
            },
          ),
        ),

        RevealedField(
          key: _vacanciesKey,
          label: 'How many people do you need?',
          visible: _role.isNotEmpty,
          child: Row(
            children: [
              for (final n in [1, 2, 5, 10, 20, 50])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: LbChoiceChip(
                    label: n == 50 ? '50+' : '$n',
                    selected: _vacancies == n,
                    showAffordance: false,
                    onTap: () => setState(() => _vacancies = n),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- step two

  Widget _requirementsStep() {
    final abilities =
        AppData.abilitiesFor(category: _category, role: _role);
    final certificates =
        AppData.certificatesFor(category: _category, role: _role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('What must they be able to do?'),
        _subtitle(
            'Only tick what the job genuinely needs. Every extra requirement '
            'narrows who we can send you.'),
        const SizedBox(height: 20),

        RevealedField(
          label: 'Work involved',
          child: SearchableChipPicker(
            options: abilities,
            selected: _skills,
            searchHint: 'Search the work, or type it',
            onToggle: (a) => setState(
                () => _skills.contains(a) ? _skills.remove(a) : _skills.add(a)),
          ),
        ),

        if (certificates.isNotEmpty)
          RevealedField(
            label: 'Licences required for a $_role',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A licence here is a hard requirement. Candidates without it '
                  'are ranked down rather than sent to you.',
                  style: AppTheme.sansRegular(
                      fontSize: 12.5, color: AppTheme.inkFaintOf(context)),
                ),
                const SizedBox(height: 10),
                SearchableChipPicker(
                  options: certificates,
                  selected: _certificates,
                  searchThreshold: 8,
                  searchHint: 'Search licences, or type one',
                  onToggle: (c) => setState(() => _certificates.contains(c)
                      ? _certificates.remove(c)
                      : _certificates.add(c)),
                ),
              ],
            ),
          ),

        RevealedField(
          label: 'Will you take someone with no experience?',
          child: _chips(
            const ['Yes, we train', 'No, must be experienced'],
            isSelected: (v) => _training == (v == 'Yes, we train'),
            single: true,
            onTap: (v) => setState(() => _training = v == 'Yes, we train'),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------- step three

  Widget _payStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Where, and for how much?'),
        _subtitle('Pay is the first thing a candidate looks at.'),
        const SizedBox(height: 20),

        // Single, unlike the candidate's answer. A vacancy is at one site in
        // one country; a candidate can be willing to work in three. Making this
        // multi-select would produce postings nobody could actually turn up to.
        RevealedField(
          label: 'Country *',
          child: _chips(
            AppData.countries.map((c) => c['name']!).toList(),
            isSelected: (name) =>
                _country ==
                AppData.countries.firstWhere((c) => c['name'] == name)['code'],
            single: true,
            onTap: (name) {
              setState(() => _country = AppData.countries
                  .firstWhere((c) => c['name'] == name)['code']!);
              revealNextQuestion(_cityKey);
            },
          ),
        ),

        RevealedField(
          key: _cityKey,
          label: 'Where is the work? *',
          child: CityField(
            controller: _cityController,
            country: _country,
            hint: 'Site, town or area',
            minChars: 2,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => revealNextQuestion(_payPeriodKey),
          ),
        ),

        RevealedField(
          key: _payPeriodKey,
          label: 'How is the pay quoted?',
          child: _chips(
            AppData.payPeriods,
            isSelected: (p) => _payPeriod == p,
            single: true,
            onTap: (p) => setState(() => _payPeriod = p),
          ),
        ),

        RevealedField(
          label: 'Pay range ($_currency)',
          child: Row(
            children: [
              Expanded(child: _numberField(_minController, 'From')),
              const SizedBox(width: 10),
              Expanded(child: _numberField(_maxController, 'To')),
            ],
          ),
        ),

        RevealedField(
          label: 'What comes with the job?',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'These decide more applications than pay does, especially for '
                'workers moving for the job.',
                style: AppTheme.sansRegular(
                    fontSize: 12.5, color: AppTheme.inkFaintOf(context)),
              ),
              const SizedBox(height: 10),
              _toggle('Accommodation provided', _accommodation,
                  (v) => setState(() => _accommodation = v)),
              _toggle('Transport provided', _transport,
                  (v) => setState(() => _transport = v)),
              _toggle('Work permit sponsored', _permitSponsored,
                  (v) => setState(() => _permitSponsored = v)),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------- step four

  Widget _detailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Anything else?'),
        _subtitle('All optional. The job can be posted as it stands.'),
        const SizedBox(height: 20),

        // Multi-select: a site running days and nights is hiring for both,
        // and a single answer described half the vacancy.
        RevealedField(
          label: 'Shift pattern',
          child: _chips(
            _shifts,
            isSelected: _selectedShifts.contains,
            onTap: (v) => setState(() => _selectedShifts.contains(v)
                ? _selectedShifts.remove(v)
                : _selectedShifts.add(v)),
          ),
        ),

        RevealedField(
          label: 'Work mode',
          child: _chips(
            const ['On-site', 'Hybrid', 'Remote'],
            isSelected: (v) => _workMode == v,
            single: true,
            onTap: (v) => setState(() => _workMode = v),
          ),
        ),

        RevealedField(
          label: 'Job title as candidates will see it',
          child: TextField(
                        textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
controller: _titleController,
            textCapitalization: TextCapitalization.words,
            style: AppTheme.sansMedium(
                fontSize: 15, color: AppTheme.inkOf(context)),
            decoration: _inputDecoration(
                _role.isEmpty ? 'Job title' : 'Defaults to "$_role"'),
          ),
        ),

        RevealedField(
          label: 'Description',
          child: TextField(
            controller: _descriptionController,
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            style: AppTheme.sansRegular(
                fontSize: 14.5, color: AppTheme.inkOf(context)),
            decoration: _inputDecoration(
                'Working hours, what the day looks like, who to ask for.'),
          ),
        ),

        const SizedBox(height: 8),
        _summary(),
      ],
    );
  }

  /// What the candidate will see, before it is posted.
  ///
  /// A wizard that spreads a posting over four screens owes the employer one
  /// place to check it. Publishing and only then discovering the rate says
  /// "per month" is a bad way to find out.
  Widget _summary() {
    final title =
        _titleController.text.trim().isEmpty ? _role : _titleController.text.trim();
    final min = _minController.text.trim();
    final max = _maxController.text.trim();
    final unit = switch (_payPeriod) {
      'Per day' => '/ day',
      'Per year' => '/ year',
      _ => '/ month',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.signalSourceWash,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.signalSource.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HOW CANDIDATES WILL SEE IT',
              style: AppTheme.sansBold(fontSize: 10, color: AppTheme.signalSource)
                  .copyWith(letterSpacing: 0.6)),
          const SizedBox(height: 10),
          Text(title.isEmpty ? 'Your vacancy' : title,
              style: AppTheme.sansBold(
                  fontSize: 16, color: AppTheme.inkOf(context))),
          const SizedBox(height: 3),
          Text(
            [
              if (_cityController.text.trim().isNotEmpty)
                _cityController.text.trim(),
              if (min.isNotEmpty) '$_currency $min${max.isEmpty ? '' : ' – $max'} $unit',
              if (_vacancies > 1) '$_vacancies positions',
            ].join('  ·  '),
            style: AppTheme.sansMedium(
                fontSize: 13, color: AppTheme.inkMutedOf(context)),
          ),
          if (_certificates.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Requires: ${_certificates.join(', ')}',
                style: AppTheme.sansMedium(
                    fontSize: 12.5, color: AppTheme.signalAttention)),
          ],
          if (_accommodation || _transport || _permitSponsored || _training) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final b in [
                  if (_accommodation) 'Accommodation',
                  if (_transport) 'Transport',
                  if (_permitSponsored) 'Permit sponsored',
                  if (_training) 'Training given',
                ])
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.signalPositiveWash,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(b,
                        style: AppTheme.sansBold(
                            fontSize: 11, color: AppTheme.signalPositive)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ pieces

  Widget _title(String text) => Text(text,
      style: AppTheme.serifTitle(fontSize: 25, color: AppTheme.inkOf(context)));

  Widget _subtitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(text,
            style: AppTheme.sansRegular(
                fontSize: 14, color: AppTheme.inkMutedOf(context))),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.sansRegular(
            fontSize: 14, color: AppTheme.inkFaintOf(context)),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  Widget _numberField(TextEditingController controller, String hint) =>
      TextField(
                textInputAction: TextInputAction.done,
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
controller: controller,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        style:
            AppTheme.sansSemiBold(fontSize: 15, color: AppTheme.inkOf(context)),
        decoration: _inputDecoration(hint),
      );

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) =>
      InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Icon(
                value
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 22,
                color:
                    value ? AppTheme.signalPositive : AppTheme.inkFaintOf(context),
              ),
              const SizedBox(width: 11),
              Text(label,
                  style: AppTheme.sansMedium(
                      fontSize: 14.5, color: AppTheme.inkOf(context))),
            ],
          ),
        ),
      );

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

  Widget _footer() {
    final last = _step == _totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Text(
                switch (_step) {
                  0 when _category.isEmpty => 'Pick an industry to continue',
                  0 when _role.isEmpty => 'Pick the job',
                  2 when _cityController.text.trim().isEmpty =>
                    'Where is the work?',
                  _ => '',
                },
                style: AppTheme.sansMedium(
                    fontSize: 12.5, color: AppTheme.inkFaintOf(context)),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _canAdvance ? _next : null,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
              ),
              child: Text(last ? 'Post this job' : 'Continue',
                  style: AppTheme.sansBold(
                      fontSize: 14.5, color: AppTheme.onInkOf(context))),
            ),
          ],
        ),
      ),
    );
  }
}
