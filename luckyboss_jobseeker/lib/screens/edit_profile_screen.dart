import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_data.dart';
import '../core/theme/app_theme.dart';
import '../providers/job_seeker_provider.dart';
import '../widgets/city_field.dart';
import '../widgets/profile_photo_avatar.dart';
import '../widgets/searchable_chip_picker.dart';

/// Everything about you, in one editable place.
///
/// Shantosh: *"the pending says to add my name but I can't even [edit] my info
/// — have like edit profile, I can change name, gmail, numbers and see them."*
/// He was right and the gap was bad: the profile screen told a candidate their
/// profile was incomplete because it had no name, and offered no way to type
/// one. The name came from registration and nothing could change it afterwards.
///
/// One screen, everything visible, saved as it is typed. There is no Save
/// button because there is nothing to submit — the profile is on the device,
/// and a Save button on a form that has already saved is how the licences sheet
/// misled people earlier.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  const EditProfileScreen.named({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _city;
  late final TextEditingController _salary;
  late final TextEditingController _bio;

  @override
  void initState() {
    super.initState();
    final p = context.read<JobSeekerProvider>().profile;
    _name = TextEditingController(text: p.name);
    _email = TextEditingController(text: p.email);
    _phone = TextEditingController(text: p.phone);
    _city = TextEditingController(text: p.currentCity);
    _salary = TextEditingController(text: p.expectedSalary);
    _bio = TextEditingController(text: p.bio);
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _city, _salary, _bio]) {
      c.dispose();
    }
    super.dispose();
  }

  JobSeekerProvider get _provider => context.read<JobSeekerProvider>();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobSeekerProvider>();
    final profile = provider.profile;
    final category = AppData.categoryByName(profile.preferredCategory);
    final role = profile.roleTitle.isNotEmpty
        ? profile.roleTitle
        : profile.currentTitle;

    return Scaffold(
      backgroundColor: AppTheme.paperOf(context),
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.inkOf(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit profile',
            style: AppTheme.sansBold(
                fontSize: 17, color: AppTheme.inkOf(context))),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text('${profile.profileStrengthPercent}%',
                  style: AppTheme.sansBold(
                      fontSize: 14, color: AppTheme.signalPositive)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Center(child: ProfilePhotoAvatar(size: 84)),
          const SizedBox(height: 8),
          Center(
            child: Text('Tap to change your photo',
                style: AppTheme.sansRegular(
                    fontSize: 12.5, color: AppTheme.inkFaintOf(context))),
          ),
          const SizedBox(height: 24),

          _section('You'),
          _field(
            label: 'Full name',
            controller: _name,
            hint: 'As on your ID',
            // Saved on every keystroke. The profile lives on this device, so
            // there is nothing to submit and nothing to lose by leaving.
            onChanged: (v) => _provider.setProfileField('name', v),
          ),
          _field(
            label: 'Mobile number',
            controller: _phone,
            hint: 'Include your country code',
            keyboard: TextInputType.phone,
            onChanged: (v) => _provider.setProfileField('phone', v),
          ),
          _field(
            label: 'Email',
            controller: _email,
            hint: 'you@example.com',
            keyboard: TextInputType.emailAddress,
            capitalise: false,
            onChanged: (v) => _provider.setProfileField('email', v),
          ),

          const SizedBox(height: 10),
          _section('Your work'),
          _readOnlyRow(
            context,
            icon: category?.icon ?? Icons.work_outline,
            label: 'Kind of work',
            value: profile.preferredCategory.isEmpty
                ? 'Not set'
                : profile.preferredCategory,
          ),
          _picker(
            label: 'Your job',
            options: category?.roleNames ?? AppData.allRoleTitles,
            selected: {if (role.isNotEmpty) role},
            single: true,
            hint: 'Search trades, or type your own',
            onToggle: (r) => _provider.setProfileField('role', role == r ? '' : r),
          ),
          _picker(
            label: 'Work you can do',
            options: AppData.abilitiesFor(
                category: profile.preferredCategory, role: role),
            selected: profile.skills.toSet(),
            hint: 'Search the work you do',
            onToggle: (a) {
              final next = [...profile.skills];
              next.contains(a) ? next.remove(a) : next.add(a);
              _provider.setProfileField('skills', next);
            },
          ),

          const SizedBox(height: 10),
          _section('Where and when'),
          _labelled(
            'City',
            CityField(
              controller: _city,
              minChars: 2,
              hint: 'Where you are now',
              onChanged: (v) => _provider.setProfileField('city', v),
            ),
          ),
          _picker(
            label: 'Countries you can work in',
            options: AppData.countries.map((c) => c['name']!).toList(),
            selected: {
              for (final c in AppData.countries)
                if (profile.preferredCountries.contains(c['code'])) c['name']!,
            },
            hint: '',
            onToggle: (name) {
              final code = AppData.countries
                  .firstWhere((c) => c['name'] == name)['code']!;
              final next = [...profile.preferredCountries];
              next.contains(code) ? next.remove(code) : next.add(code);
              _provider.setProfileField('countries', next);
            },
          ),
          _picker(
            label: 'When you can start',
            options: AppData.availabilityOptions,
            selected: {
              if (profile.availability.isNotEmpty) profile.availability
            },
            single: true,
            hint: '',
            onToggle: (a) => _provider.setProfileField(
                'availability', profile.availability == a ? '' : a),
          ),
          _picker(
            label: 'Can you work there?',
            options: AppData.workPermitStatuses,
            selected: {
              if (profile.workPermitStatus.isNotEmpty) profile.workPermitStatus
            },
            single: true,
            hint: '',
            onToggle: (p) => _provider.setProfileField(
                'permit', profile.workPermitStatus == p ? '' : p),
          ),
          _picker(
            label: 'Languages you speak',
            options: AppData.commonLanguages,
            selected: profile.languages.toSet(),
            hint: 'Search languages',
            onToggle: (l) {
              final next = [...profile.languages];
              next.contains(l) ? next.remove(l) : next.add(l);
              _provider.setProfileField('languages', next);
            },
          ),

          const SizedBox(height: 10),
          _section('Pay'),
          _picker(
            label: 'How you want pay quoted',
            options: AppData.payPeriods,
            selected: {profile.payPeriod},
            single: true,
            hint: '',
            onToggle: (p) => _provider.setProfileField('payPeriod', p),
          ),
          _field(
            label: 'Expected pay',
            controller: _salary,
            hint: 'Amount — leave blank to discuss',
            keyboard: TextInputType.number,
            onChanged: (v) => _provider.setProfileField('salary', v),
          ),

          const SizedBox(height: 10),
          _section('About you'),
          _labelled(
            profile.isFieldWork ? 'Anything else employers should know' : 'Summary',
            TextField(
              controller: _bio,
              minLines: 3,
              maxLines: 7,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (v) => _provider.setProfileField('bio', v),
              style: AppTheme.sansRegular(
                  fontSize: 14.5, color: AppTheme.inkOf(context)),
              decoration: _decoration(profile.isFieldWork
                  ? 'e.g. I have my own tools and can start any day.'
                  : 'Two or three sentences.'),
            ),
          ),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceOf(context),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 17, color: AppTheme.signalPositive),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Everything here saves as you type. There is nothing to '
                    'submit.',
                    style: AppTheme.sansMedium(
                        fontSize: 12.5, color: AppTheme.inkMutedOf(context)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ pieces

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 6),
        child: Text(title.toUpperCase(),
            style: AppTheme.sansBold(
                    fontSize: 10, color: AppTheme.inkFaintOf(context))
                .copyWith(letterSpacing: 0.6)),
      );

  Widget _labelled(String label, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTheme.sansMedium(
                    fontSize: 13, color: AppTheme.inkMutedOf(context))),
            const SizedBox(height: 8),
            child,
          ],
        ),
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

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
    TextInputType? keyboard,
    bool capitalise = true,
  }) =>
      _labelled(
        label,
        TextField(
          controller: controller,
          keyboardType: keyboard,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          textCapitalization:
              capitalise ? TextCapitalization.words : TextCapitalization.none,
          onChanged: onChanged,
          style:
              AppTheme.sansMedium(fontSize: 15, color: AppTheme.inkOf(context)),
          decoration: _decoration(hint),
        ),
      );

  Widget _picker({
    required String label,
    required List<String> options,
    required Set<String> selected,
    required ValueChanged<String> onToggle,
    required String hint,
    bool single = false,
  }) =>
      _labelled(
        label,
        SearchableChipPicker(
          options: options,
          selected: selected,
          single: single,
          searchHint: hint.isEmpty ? 'Search' : hint,
          onToggle: onToggle,
        ),
      );

  Widget _readOnlyRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          children: [
            Icon(icon, size: 19, color: AppTheme.inkMutedOf(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTheme.sansRegular(
                          fontSize: 12, color: AppTheme.inkFaintOf(context))),
                  Text(value,
                      style: AppTheme.sansSemiBold(
                          fontSize: 14.5, color: AppTheme.inkOf(context))),
                ],
              ),
            ),
            // Changing category re-picks the trade and everything chosen from
            // its vocabulary, so it goes through the wizard rather than being
            // swapped silently here.
            TextButton(
              onPressed: () => _changeCategory(context),
              child: Text('Change',
                  style: AppTheme.sansBold(
                      fontSize: 13, color: AppTheme.royalBlue)),
            ),
          ],
        ),
      );

  Future<void> _changeCategory(BuildContext context) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (ctx, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              Text('What kind of work?',
                  style: AppTheme.sansBold(
                      fontSize: 17, color: AppTheme.inkOf(context))),
              const SizedBox(height: 6),
              Text(
                'Changing this clears your trade and the work you picked, '
                'because they come from the category you chose.',
                style: AppTheme.sansRegular(
                    fontSize: 12.5, color: AppTheme.inkMutedOf(context)),
              ),
              const SizedBox(height: 14),
              for (final category in AppData.workCategories)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(category.icon,
                      size: 21, color: AppTheme.inkMutedOf(context)),
                  title: Text(category.name,
                      style: AppTheme.sansMedium(
                          fontSize: 14.5, color: AppTheme.inkOf(context))),
                  onTap: () => Navigator.pop(ctx, category.name),
                ),
            ],
          ),
        ),
      ),
    );

    if (chosen == null || !mounted) return;
    await _provider.setProfileField('category', chosen);
    if (!mounted) return;
    await _provider.setProfileField('role', '');
    if (!mounted) return;
    await _provider.setProfileField('skills', <String>[]);
  }
}
