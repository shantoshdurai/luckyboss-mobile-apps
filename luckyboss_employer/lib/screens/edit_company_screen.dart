import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_data.dart';
import '../core/theme/app_theme.dart';
import '../models/employer_job.dart';
import '../providers/employer_provider.dart';
import '../services/document_service.dart';
import '../widgets/city_field.dart';
import '../widgets/searchable_chip_picker.dart';

/// Editing the company after registration.
///
/// Registration collected all of this once and then froze it: there was no way
/// to correct a typo in the company name, change the contact, or add a logo.
/// Shantosh: *"no editbale option for profile for logo adding for them"*.
///
/// The verification fields — legal name, registration number, business type —
/// are editable, but changing one on a verified account is not something the
/// employer can wave through on their own, so the screen says plainly that an
/// edit sends the account back for review. That check belongs on the server
/// when it exists; here it is at least honest about the consequence.
class EditCompanyScreen extends StatefulWidget {
  const EditCompanyScreen({super.key});

  @override
  State<EditCompanyScreen> createState() => _EditCompanyScreenState();
}

class _EditCompanyScreenState extends State<EditCompanyScreen> {
  late final CompanyProfile _original;
  late final TextEditingController _name;
  late final TextEditingController _legalName;
  late final TextEditingController _registrationNumber;
  late final TextEditingController _contactName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _city;
  late final TextEditingController _about;

  late String _type;
  late String _countryCode;
  String? _logoUrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _original = context.read<EmployerProvider>().company;
    _name = TextEditingController(text: _original.name);
    _legalName = TextEditingController(text: _original.legalName);
    _registrationNumber =
        TextEditingController(text: _original.registrationNumber);
    _contactName = TextEditingController(text: _original.contactName);
    _email = TextEditingController(text: _original.email);
    _phone = TextEditingController(text: _original.phone);
    _city = TextEditingController(text: _original.city);
    _about = TextEditingController(text: _original.about);
    _type = _original.type;
    _countryCode = _original.countryCode;
    _logoUrl = _original.logoUrl;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _legalName,
      _registrationNumber,
      _contactName,
      _email,
      _phone,
      _city,
      _about,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// True when something verification depends on has changed.
  bool get _verificationAffected =>
      _original.isVerified &&
      (_name.text.trim() != _original.name ||
          _legalName.text.trim() != _original.legalName ||
          _registrationNumber.text.trim() != _original.registrationNumber ||
          _type != _original.type);

  Future<void> _pickLogo() async {
    setState(() => _busy = true);
    final result = await DocumentService.pickDocument(imagesOnly: true);
    if (!mounted) return;
    setState(() => _busy = false);

    if (result.file == null) {
      if (result.message != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.message!)));
      }
      return;
    }

    // Stored as a data URI on the device, like every other upload here, so the
    // logo survives a restart with no server behind it.
    setState(() => _logoUrl = DocumentService.dataUri(
          result.file!.bytes,
          result.file!.mimeType,
        ));
  }

  void _save() {
    final missing = <String>[
      if (_name.text.trim().isEmpty) 'Company name',
      if (_contactName.text.trim().isEmpty) 'Contact person',
      if (_email.text.trim().isEmpty) 'Email',
      if (_phone.text.trim().isEmpty) 'Phone',
    ];

    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Still to fill in: ${missing.join(', ')}'),
      ));
      return;
    }

    final updated = _original.copyWith(
      name: _name.text.trim(),
      legalName: _legalName.text.trim(),
      registrationNumber: _registrationNumber.text.trim(),
      type: _type,
      contactName: _contactName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      countryCode: _countryCode,
      city: _city.text.trim(),
      about: _about.text.trim(),
      logoUrl: _logoUrl,
      // Editing a verified detail sends the account back to review rather than
      // letting an unchecked name keep a verified badge.
      status:
          _verificationAffected ? CompanyStatus.underReview : _original.status,
    );

    final affected = _verificationAffected;
    context.read<EmployerProvider>().updateCompany(updated);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(affected
          ? 'Saved. Your changes are back with our team for verification.'
          : 'Company profile saved.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ink = AppTheme.inkOf(context);

    return Scaffold(
      backgroundColor: AppTheme.paperOf(context),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit company',
            style: AppTheme.sansBold(fontSize: 18, color: ink)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          Center(child: _logo(context)),
          const SizedBox(height: 24),
          _label('Company name *'),
          _field(_name, 'What candidates see'),
          _label('Registered legal name'),
          _field(_legalName, 'If different from the above'),
          _label('Business type'),
          SearchableChipPicker(
            options: CompanyProfile.types,
            selected: {if (_type.isNotEmpty) _type},
            single: true,
            searchThreshold: 10,
            searchHint: 'Search, or type your own',
            onToggle: (t) => setState(() => _type = _type == t ? '' : t),
          ),
          const SizedBox(height: 8),
          _label('Business registration number'),
          _field(_registrationNumber, 'UEN, CIN, SSM or equivalent'),
          _label('Contact person *'),
          _field(_contactName, 'Who we speak to about hiring'),
          _label('Email *'),
          _field(_email, 'name@company.com',
              keyboard: TextInputType.emailAddress),
          _label('Phone *'),
          _field(_phone, 'With country code', keyboard: TextInputType.phone),
          _label('Country'),
          Wrap(
            spacing: 8,
            children: [
              for (final c in AppData.countries)
                ChoiceChip(
                  label: Text('${c['flag']}  ${c['name']}'),
                  selected: _countryCode == c['code'],
                  onSelected: (_) => setState(() => _countryCode = c['code']!),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _label('City'),
          CityField(
            controller: _city,
            country: _countryCode,
            hint: 'Where you hire',
            minChars: 1,
          ),
          _label('About the company'),
          _field(_about, 'What you do, in a sentence or two', lines: 4),
          if (_verificationAffected) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.signalAttention.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.signalAttention.withValues(alpha: 0.35)),
              ),
              child: Text(
                'You have changed a detail we verified. Saving sends your '
                'account back for review, and posting is paused until it '
                'clears.',
                style: AppTheme.sansRegular(fontSize: 13, color: ink),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _busy ? null : _save,
            child: const Text('Save changes'),
          ),
        ),
      ),
    );
  }

  Widget _logo(BuildContext context) {
    final bytes = DocumentService.bytesFromDataUri(_logoUrl);

    return Column(
      children: [
        GestureDetector(
          onTap: _busy ? null : _pickLogo,
          child: Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).dividerColor),
              image: bytes == null
                  ? null
                  : DecorationImage(
                      image: MemoryImage(bytes), fit: BoxFit.cover),
            ),
            child: bytes != null
                ? null
                : Icon(Icons.add_photo_alternate_outlined,
                    size: 30, color: AppTheme.inkMutedOf(context)),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _busy ? null : _pickLogo,
          child: Text(bytes == null ? 'Add company logo' : 'Change logo'),
        ),
        if (bytes != null)
          TextButton(
            onPressed: () => setState(() => _logoUrl = null),
            child: Text('Remove',
                style: TextStyle(color: AppTheme.inkMutedOf(context))),
          ),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 18, 0, 8),
        child: Text(text,
            style: AppTheme.sansBold(
                fontSize: 13.5, color: AppTheme.inkOf(context))),
      );

  Widget _field(
    TextEditingController controller,
    String hint, {
    int lines = 1,
    TextInputType? keyboard,
  }) =>
      TextField(
        controller: controller,
        maxLines: lines,
        keyboardType: keyboard,
        textInputAction:
            lines > 1 ? TextInputAction.newline : TextInputAction.next,
        onChanged: (_) => setState(() {}),
        style:
            AppTheme.sansRegular(fontSize: 15, color: AppTheme.inkOf(context)),
        decoration: InputDecoration(hintText: hint),
      );
}
