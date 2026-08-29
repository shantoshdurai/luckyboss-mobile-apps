import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_data.dart';
import '../../core/theme/app_theme.dart';
import '../../models/employer_job.dart';
import '../../models/uploaded_document.dart';
import '../../providers/employer_provider.dart';
import '../../services/document_service.dart';
import '../../widgets/city_field.dart';
import '../../widgets/onboarding_components.dart';
import '../../widgets/searchable_chip_picker.dart';
import 'employer_login_screen.dart';
import 'verification_pending_screen.dart';

/// Registering a company — a submission for checking, not a sign-up.
///
/// Shantosh: *"it is not straight register, we take all info to process to
/// verify them with AI letting them know we contact them after verification"*
/// and *"they need to get verified before even applying"*.
///
/// That reframes the whole screen. What this replaces was a dead
/// `onPressed: () {}` on the login screen, and what sat behind the login form
/// was worse: any email and any eight characters produced a live employer
/// account that could post jobs to candidates. An agency whose product is
/// *"we checked who is hiring"* cannot hand that out on an email address.
///
/// So this ends at [CompanyStatus.submitted] and says so. It never grants a
/// posting account. Verification is a server decision — see
/// [EmployerProvider.submitForVerification].
class CompanyRegistrationScreen extends StatefulWidget {
  const CompanyRegistrationScreen({super.key});

  @override
  State<CompanyRegistrationScreen> createState() =>
      _CompanyRegistrationScreenState();
}

class _CompanyRegistrationScreenState extends State<CompanyRegistrationScreen> {
  final PageController _pager = PageController();

  final _name = TextEditingController();
  final _legalName = TextEditingController();
  final _registrationNumber = TextEditingController();
  final _contactName = TextEditingController();
  final _contactRole = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _about = TextEditingController();

  final GlobalKey _typeKey = GlobalKey();
  final GlobalKey _regNumberKey = GlobalKey();
  final GlobalKey _cityKey = GlobalKey();

  String _type = '';
  String _country = 'SG';
  int _step = 0;
  bool _submitting = false;

  static const int _totalSteps = 4;
  static const List<String> _labels = [
    'Your company',
    'Who to contact',
    'Proof',
    'Check & send',
  ];

  /// The documents Lucky Boss checks. Business registration is the only hard
  /// requirement — a small contractor may hold nothing else, and refusing them
  /// at the door would cut out most of the market this agency serves.
  static const List<({DocumentKind kind, String label, String why, bool required})>
      _requiredDocuments = [
    (
      kind: DocumentKind.companyRegistration,
      label: 'Business registration certificate',
      why: 'Proves the company exists and matches the name you gave.',
      required: true,
    ),
    (
      kind: DocumentKind.licence,
      label: 'Trade or agency licence',
      why: 'If your work needs one — employment agency, construction, security.',
      required: false,
    ),
    (
      kind: DocumentKind.taxCertificate,
      label: 'Tax or GST registration',
      why: 'Helps us verify you faster.',
      required: false,
    ),
    (
      kind: DocumentKind.companyPhoto,
      label: 'Photos of your office or site',
      why: 'Candidates see these. A real workplace gets more applications.',
      required: false,
    ),
  ];

  @override
  void dispose() {
    _pager.dispose();
    for (final c in [
      _name,
      _legalName,
      _registrationNumber,
      _contactName,
      _contactRole,
      _email,
      _phone,
      _city,
      _about,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canAdvance => switch (_step) {
        0 => _name.text.trim().isNotEmpty &&
            _type.isNotEmpty &&
            _registrationNumber.text.trim().isNotEmpty &&
            _city.text.trim().isNotEmpty,
        1 => _contactName.text.trim().isNotEmpty &&
            _email.text.trim().contains('@') &&
            _phone.text.trim().length >= 7,
        2 => _hasRequiredDocuments,
        3 => true,
        _ => false,
      };

  bool get _hasRequiredDocuments {
    final provider = context.read<EmployerProvider>();
    return provider.documents
        .any((d) => d.kind == DocumentKind.companyRegistration);
  }

  void _dismissKeyboard() => dismissKeyboard(context);

  /// What is still missing on this step, named rather than counted.
  ///
  /// The hint under the button used to say "fill in the starred fields", which
  /// is only useful to somebody who can already see which one they skipped.
  List<String> get _missing => switch (_step) {
        0 => [
            if (_name.text.trim().isEmpty) 'the company name',
            if (_type.isEmpty) 'the business type',
            if (_registrationNumber.text.trim().isEmpty)
              'the registration number',
            if (_city.text.trim().isEmpty) 'the city',
          ],
        1 => [
            if (_contactName.text.trim().isEmpty) 'a contact name',
            if (!_email.text.trim().contains('@')) 'a valid email',
            if (_phone.text.trim().length < 7) 'a phone number',
          ],
        2 => [
            if (!_hasRequiredDocuments)
              'your business registration certificate',
          ],
        _ => const [],
      };

  String get _missingSentence {
    final missing = _missing;
    if (missing.isEmpty) return '';
    final what = missing.length == 1
        ? missing.first
        : '${missing.take(missing.length - 1).join(', ')} and ${missing.last}';
    return 'We still need $what.';
  }

  void _sayWhatIsLeft() {
    if (_missingSentence.isEmpty) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 4),
        content: Text(_missingSentence),
      ));
  }

  void _next() {
    if (!_canAdvance) {
      _sayWhatIsLeft();
      return;
    }
    _dismissKeyboard();
    if (_step == _totalSteps - 1) {
      _submit();
      return;
    }
    setState(() => _step++);
    _pager.animateToPage(_step,
        duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
  }

  void _back() {
    _dismissKeyboard();
    if (_step == 0) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EmployerLoginScreen()),
        );
      }
      return;
    }
    setState(() => _step--);
    _pager.animateToPage(_step,
        duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final provider = context.read<EmployerProvider>();

    provider.updateCompany(provider.company.copyWith(
      name: _name.text.trim(),
      legalName: _legalName.text.trim(),
      type: _type,
      registrationNumber: _registrationNumber.text.trim(),
      contactName: _contactName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      countryCode: _country,
      city: _city.text.trim(),
      about: _about.text.trim(),
    ));
    provider.submitForVerification();
    // Signed in as part of registering. Without this the company would be sent
    // back to a login screen that has just been taught to reject unknown
    // accounts — and its own would not be recognised until it signed in again.
    provider.setAuthenticated(true);
    await provider.flush();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const VerificationPendingScreen()),
      (route) => false,
    );
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
                  _scroll(_companyStep()),
                  _scroll(_contactStep()),
                  _scroll(_proofStep()),
                  _scroll(_reviewStep()),
                ],
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  /// One page of the wizard.
  ///
  /// The `FocusScope` is what stops a text field on a page the user has left
  /// from reclaiming focus and pulling the keyboard back up — a PageView keeps
  /// all its pages mounted, so without this they compete.
  Widget _scroll(Widget child) => FocusScope(
        child: _scrollBody(child),
      );

  Widget _scrollBody(Widget child) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: child,
      );

  // --------------------------------------------------------------- step one

  Widget _companyStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Register your company'),
          _subtitle(
              'Lucky Boss checks every employer before candidates see their '
              'jobs. This takes a few minutes.'),
          const SizedBox(height: 22),
          RevealedField(
            label: 'Company name *',
            child: _text(_name, 'As candidates should see it'),
          ),
          RevealedField(
            key: _typeKey,
            label: 'Registered legal name',
            child: _text(_legalName, 'If different from the above'),
          ),
          RevealedField(
            label: 'What kind of business? *',
            child: SearchableChipPicker(
              options: CompanyProfile.types,
              selected: {if (_type.isNotEmpty) _type},
              single: true,
              searchThreshold: 10,
              searchHint: 'Search, or type your own',
              onToggle: (t) {
                setState(() => _type = _type == t ? '' : t);
                if (_type.isNotEmpty) revealNextQuestion(_regNumberKey);
              },
            ),
          ),
          RevealedField(
            key: _regNumberKey,
            label: 'Business registration number *',
            child: _text(_registrationNumber, 'UEN, CIN, SSM or equivalent'),
          ),
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
            label: 'City *',
            child: CityField(
              controller: _city,
              country: _country,
              minChars: 2,
              hint: 'Where you are based',
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      );

  // --------------------------------------------------------------- step two

  Widget _contactStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Who should we speak to?'),
          _subtitle('We call this person to complete verification.'),
          const SizedBox(height: 22),
          RevealedField(
            label: 'Name *',
            child: _text(_contactName, 'Full name'),
          ),
          RevealedField(
            label: 'Their role',
            child: _text(_contactRole, 'e.g. HR Manager, Director'),
          ),
          RevealedField(
            label: 'Work email *',
            child: _text(_email, 'name@company.com',
                keyboard: TextInputType.emailAddress, capitalise: false),
          ),
          RevealedField(
            label: 'Phone *',
            child: _text(_phone, 'Include the country code',
                keyboard: TextInputType.phone, capitalise: false),
          ),
          RevealedField(
            label: 'About the company',
            child: TextField(
              controller: _about,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              style: AppTheme.sansRegular(
                  fontSize: 14.5, color: AppTheme.inkOf(context)),
              decoration: _decoration(
                  'What you do, how many people you hire in a year.'),
            ),
          ),
        ],
      );

  // ------------------------------------------------------------- step three

  Widget _proofStep() {
    final provider = context.watch<EmployerProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Prove the company is real'),
        _subtitle(
            'A photo of each document is fine. PDFs work too. Only Lucky Boss '
            'sees these — candidates never do.'),
        const SizedBox(height: 20),
        for (final doc in _requiredDocuments)
          _DocumentRow(
            kind: doc.kind,
            label: doc.label,
            why: doc.why,
            required: doc.required,
            uploaded: provider.documents
                .where((d) => d.kind == doc.kind)
                .toList(),
          ),
      ],
    );
  }

  // -------------------------------------------------------------- step four

  Widget _reviewStep() {
    final provider = context.watch<EmployerProvider>();
    final documents = provider.documents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Check and send'),
        _subtitle('Make sure this is right — we verify against it.'),
        const SizedBox(height: 20),
        _reviewCard('Company', [
          (_name.text.trim(), 'Name'),
          if (_legalName.text.trim().isNotEmpty)
            (_legalName.text.trim(), 'Legal name'),
          (_type, 'Business type'),
          (_registrationNumber.text.trim(), 'Registration number'),
          ('${_city.text.trim()}, $_country', 'Based in'),
        ]),
        const SizedBox(height: 12),
        _reviewCard('Contact', [
          (_contactName.text.trim(), 'Name'),
          if (_contactRole.text.trim().isNotEmpty)
            (_contactRole.text.trim(), 'Role'),
          (_email.text.trim(), 'Email'),
          (_phone.text.trim(), 'Phone'),
        ]),
        const SizedBox(height: 12),
        _reviewCard(
          'Documents',
          [for (final d in documents) (d.fileName, d.kind.label)],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppTheme.signalSourceWash,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: AppTheme.signalSource.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  size: 17, color: AppTheme.signalSource),
              const SizedBox(width: 10),
              Expanded(
                // Said before they press the button, not after. An employer who
                // expects to post immediately and cannot is a support call.
                child: Text(
                  'You will not be able to post jobs yet. We check your '
                  'documents and call you on ${_phone.text.trim().isEmpty ? 'the number above' : _phone.text.trim()} '
                  'to finish — usually within one working day.',
                  style: AppTheme.sansMedium(
                      fontSize: 13, color: AppTheme.inkOf(context)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewCard(String heading, List<(String, String)> rows) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(heading.toUpperCase(),
                style: AppTheme.sansBold(
                        fontSize: 10, color: AppTheme.inkFaintOf(context))
                    .copyWith(letterSpacing: 0.6)),
            const SizedBox(height: 10),
            if (rows.isEmpty)
              Text('Nothing added',
                  style: AppTheme.sansRegular(
                      fontSize: 13, color: AppTheme.signalClosed))
            else
              for (final (value, label) in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(label,
                            style: AppTheme.sansRegular(
                                fontSize: 12.5,
                                color: AppTheme.inkFaintOf(context))),
                      ),
                      Expanded(
                        child: Text(value.isEmpty ? '—' : value,
                            style: AppTheme.sansSemiBold(
                                fontSize: 13,
                                color: AppTheme.inkOf(context))),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      );

  // ------------------------------------------------------------------ parts

  Widget _title(String text) => Text(text,
      style: AppTheme.serifTitle(fontSize: 25, color: AppTheme.inkOf(context)));

  Widget _subtitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(text,
            style: AppTheme.sansRegular(
                fontSize: 14, color: AppTheme.inkMutedOf(context))),
      );

  InputDecoration _decoration(String hint) => InputDecoration(
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

  Widget _text(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboard,
    bool capitalise = true,
  }) =>
      TextField(
                textInputAction: TextInputAction.done,
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
controller: controller,
        keyboardType: keyboard,
        textCapitalization:
            capitalise ? TextCapitalization.words : TextCapitalization.none,
        onChanged: (_) => setState(() {}),
        style:
            AppTheme.sansMedium(fontSize: 15, color: AppTheme.inkOf(context)),
        decoration: _decoration(hint),
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
                _canAdvance ? '' : _missingSentence,
                style: AppTheme.sansMedium(
                    fontSize: 12.5, color: AppTheme.inkFaintOf(context)),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              // Tappable unless a submit is already in flight: a dead button
              // cannot tell anyone what is missing.
              onPressed: _submitting ? null : _next,
              style: FilledButton.styleFrom(
                backgroundColor:
                    _canAdvance ? null : Theme.of(context).dividerColor,
                foregroundColor:
                    _canAdvance ? null : AppTheme.inkFaintOf(context),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(last ? 'Send for verification' : 'Continue',
                      style: AppTheme.sansBold(
                          fontSize: 14.5,
                          color: _canAdvance
                              ? AppTheme.onInkOf(context)
                              : AppTheme.inkFaintOf(context))),
            ),
          ],
        ),
      ),
    );
  }
}

/// One document to upload, with what it is for.
///
/// The "why" line is not decoration. An employer asked for a tax certificate
/// with no explanation assumes the worst; told it makes verification faster,
/// they usually have it to hand.
class _DocumentRow extends StatefulWidget {
  final DocumentKind kind;
  final String label;
  final String why;
  final bool required;
  final List<UploadedDocument> uploaded;

  const _DocumentRow({
    required this.kind,
    required this.label,
    required this.why,
    required this.required,
    required this.uploaded,
  });

  @override
  State<_DocumentRow> createState() => _DocumentRowState();
}

class _DocumentRowState extends State<_DocumentRow> {
  bool _busy = false;

  Future<void> _upload() async {
    final source = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.label,
                style: AppTheme.sansBold(
                    fontSize: 16, color: AppTheme.inkOf(context))),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('Take a photo',
                  style: AppTheme.sansMedium(
                      fontSize: 15, color: AppTheme.inkOf(context))),
              onTap: () => Navigator.pop(ctx, true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_open_outlined),
              title: Text('Choose a file',
                  style: AppTheme.sansMedium(
                      fontSize: 15, color: AppTheme.inkOf(context))),
              onTap: () => Navigator.pop(ctx, false),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    setState(() => _busy = true);
    final picked = source
        ? await DocumentService.captureWithCamera()
        : await DocumentService.pickDocument();
    if (!mounted) return;
    setState(() => _busy = false);

    if (!picked.isOk) {
      if (picked.failure == PickFailure.cancelled) return;
      if (picked.message != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(picked.message!,
              style: AppTheme.sansMedium(
                  fontSize: 13, color: AppTheme.onInkOf(context))),
          backgroundColor: AppTheme.signalClosed,
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    final document = await DocumentService.save(
      file: picked.file!,
      kind: widget.kind,
      label: widget.label,
    );
    if (!mounted) return;
    await context.read<EmployerProvider>().addDocument(document);
  }

  @override
  Widget build(BuildContext context) {
    final has = widget.uploaded.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
      decoration: BoxDecoration(
        color: has
            ? AppTheme.signalPositiveWash
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: has
              ? AppTheme.signalPositive.withValues(alpha: 0.35)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(has ? Icons.check_circle : Icons.upload_file_outlined,
                  size: 19,
                  color: has
                      ? AppTheme.signalPositive
                      : AppTheme.inkFaintOf(context)),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.required
                          ? '${widget.label} *'
                          : widget.label,
                      style: AppTheme.sansSemiBold(
                          fontSize: 14, color: AppTheme.inkOf(context)),
                    ),
                    Text(widget.why,
                        style: AppTheme.sansRegular(
                            fontSize: 11.5,
                            color: AppTheme.inkMutedOf(context))),
                  ],
                ),
              ),
              if (_busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton(
                  onPressed: _upload,
                  child: Text(has ? 'Add' : 'Upload',
                      style: AppTheme.sansBold(
                          fontSize: 13, color: AppTheme.royalBlue)),
                ),
            ],
          ),
          for (final document in widget.uploaded)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 30),
              child: Row(
                children: [
                  Icon(
                      document.isPdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.image_outlined,
                      size: 14,
                      color: AppTheme.inkMutedOf(context)),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(document.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.sansMedium(
                            fontSize: 12,
                            color: AppTheme.inkMutedOf(context))),
                  ),
                  Text(document.sizeDisplay,
                      style: AppTheme.sansRegular(
                          fontSize: 11,
                          color: AppTheme.inkFaintOf(context))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
