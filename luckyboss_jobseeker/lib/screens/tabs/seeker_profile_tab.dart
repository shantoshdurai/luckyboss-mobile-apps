import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../edit_profile_screen.dart';
import '../../widgets/profile_photo_avatar.dart';
import '../../widgets/profile_photo_sheet.dart';
import '../../widgets/profile_boost_cards.dart';
import '../../widgets/document_preview.dart';
import '../../widgets/licences_sheet.dart';
import '../../widgets/profile_field_editor.dart';
import '../../services/document_service.dart';
import '../../services/resume_service.dart';
import '../../core/constants/app_data.dart';
import '../../models/uploaded_document.dart';
import '../../providers/job_seeker_provider.dart';
import '../../services/auth_service.dart';
import '../auth/sign_in_screen.dart';

class SeekerProfileTab extends StatefulWidget {
  const SeekerProfileTab({super.key});

  @override
  State<SeekerProfileTab> createState() => _SeekerProfileTabState();
}

class _SeekerProfileTabState extends State<SeekerProfileTab> {
  bool _pushNotifications = true;


  // --- Skills Picker with Search and Custom Tag Creation ---
  void _showAddSkillDialog(BuildContext context, JobSeekerProvider provider) {
    String searchFilter = '';
    final customSkillCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredSkills = AppData.verifiedSkillDictionary
                .where((s) => s.toLowerCase().contains(searchFilter.toLowerCase()))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: AppTheme.borderMedium, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select & Search Skills',
                    style: const TextStyle(fontFamily: 'Archivo').copyWith(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.inkOf(context)),
                  ),
                  const SizedBox(height: 12),

                  // Search Bar
                  TextField(
                    onChanged: (v) => setModalState(() => searchFilter = v),
                    decoration: InputDecoration(
                      hintText: 'Search skills (e.g. Flutter, React, Supply Chain)...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      fillColor: AppTheme.bgPaper,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Custom Skill Adder
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                                                    textInputAction: TextInputAction.done,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
controller: customSkillCtrl,
                          decoration: InputDecoration(
                            hintText: 'Add custom skill tag...',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            fillColor: AppTheme.bgPaper,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final text = customSkillCtrl.text.trim();
                          if (text.isNotEmpty) {
                            provider.addSkill(text);
                            customSkillCtrl.clear();
                            setModalState(() {});
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emeraldDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('+ Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Skills Wrap
                  Expanded(
                    child: ListView(
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: filteredSkills.map((skill) {
                            final isAdded = provider.profile.skills.contains(skill);
                            return FilterChip(
                              label: Text(skill),
                              selected: isAdded,
                              selectedColor: AppTheme.inkOf(context),
                              labelStyle: AppTheme.sansSemiBold(
                                fontSize: 12,
                                color: isAdded ? Colors.white : AppTheme.textPrimary,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              onSelected: (selected) {
                                if (selected) {
                                  provider.addSkill(skill);
                                } else {
                                  provider.removeSkill(skill);
                                }
                                setModalState(() {});
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryFillOf(context),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Executive Bio Editor Modal ---
  void _showEditBioDialog(BuildContext context, JobSeekerProvider provider) {
    final bioCtrl = TextEditingController(text: provider.profile.bio);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppTheme.borderMedium, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Edit Executive Bio', style: const TextStyle(fontFamily: 'Archivo').copyWith(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.inkOf(context))),
                const SizedBox(height: 6),
                Text('Summarize your professional experience and key achievements.', style: AppTheme.sansRegular(fontSize: 12, color: AppTheme.textMuted)),
                const SizedBox(height: 14),
                TextField(
                  controller: bioCtrl,
                  maxLines: 5,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: 'Write a brief professional summary...',
                    fillColor: AppTheme.bgPaper,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      provider.updateBio(bioCtrl.text.trim());
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryFillOf(context),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Save Bio', style: AppTheme.sansBold(fontSize: 14, color: AppTheme.onInkOf(context))),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Resume Upload Dialog ---
  void _showResumeUploadDialog(BuildContext context, JobSeekerProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppTheme.borderMedium, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Update Resume', style: const TextStyle(fontFamily: 'Archivo').copyWith(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.inkOf(context))),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  final namePrefix = provider.profile.name.replaceAll(' ', '_');
                  final fileName = '${namePrefix.isNotEmpty ? namePrefix : "Candidate"}_Resume.pdf';
                  provider.updateResume(fileName);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Resume updated to $fileName')),
                  );
                },
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Select PDF Document'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryFillOf(context)),
              ),
              const SizedBox(height: 10),
              if (provider.profile.resumeFileName != null)
                TextButton(
                  onPressed: () {
                    provider.updateResume(null);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Remove Current Resume', style: TextStyle(color: Colors.redAccent)),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppTheme.borderMedium, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Privacy & Data Protection', style: const TextStyle(fontFamily: 'Archivo').copyWith(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.inkOf(context))),
              const SizedBox(height: 8),
              Text('Last updated: August 2026', style: AppTheme.sansRegular(fontSize: 12, color: AppTheme.textMuted)),
              const Divider(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _buildLegalSection('1. Candidate Data Encryption', 'All contact information, resume files, and verification records are encrypted with 256-bit AES encryption on ISO-certified cloud infrastructure.'),
                    _buildLegalSection('2. Recruiter Visibility', 'Your verified profile is only visible to certified employers whose vacancies match your skills. Contact numbers are masked until an interview is accepted.'),
                    _buildLegalSection('3. Cross-Border Compliance', 'Luckyboss adheres to PDPA (Singapore), PDPA (Malaysia), and Digital Personal Data Protection Act (India).'),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegalSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.sansBold(fontSize: 13.5, color: AppTheme.inkOf(context))),
          const SizedBox(height: 4),
          Text(body, style: AppTheme.sansRegular(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.4)),
        ],
      ),
    );
  }

  /// Resume upload + AI parse. Gated server-side on the admin flags; when the
  /// parser is off the candidate is told to fill the fields in themselves.
  /// Picks a resume, keeps it, and parses it only if there is a parser.
  ///
  /// The order is the same one the profile photo now follows, for the same
  /// reason. This used to call `ResumeService.pickAndParse()` and nothing else,
  /// so on a standalone install — where the parser endpoint does not exist —
  /// the candidate chose their CV, watched it be rejected, and ended up with no
  /// resume on file at all. Keeping the document is the part that matters to
  /// them; extracting text out of it is a convenience on top.
  Future<void> _uploadResume() async {
    final provider = context.read<JobSeekerProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final picked = await DocumentService.pickDocument();
    if (!mounted) return;

    if (!picked.isOk) {
      if (picked.failure == PickFailure.cancelled) return;
      messenger.showSnackBar(SnackBar(
        content: Text(picked.message ?? 'Could not read that file.',
            style: AppTheme.sansMedium(fontSize: 13, color: Colors.white)),
        backgroundColor: AppTheme.signalClosed,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final file = picked.file!;
    final document = await DocumentService.save(
      file: file,
      kind: DocumentKind.resume,
      label: 'Resume',
    );
    if (!mounted) return;

    // Any resume already on file is replaced rather than accumulated — a
    // candidate has one current CV, and a list of four is a support call.
    for (final old in provider.documentsOfKind(DocumentKind.resume)) {
      if (old.id != document.id) await provider.removeDocument(old.id);
    }
    if (!mounted) return;
    await provider.addDocument(document);
    if (!mounted) return;

    messenger.showSnackBar(SnackBar(
      content: Text('${file.fileName} saved to your profile.',
          style: AppTheme.sansMedium(fontSize: 13, color: Colors.white)),
      backgroundColor: AppTheme.signalPositive,
      behavior: SnackBarBehavior.floating,
    ));

    // Autofill, where a server offers it. A failure here costs the candidate
    // nothing: their resume is already on file.
    final parsed = await ResumeService.pickAndParse(alreadyPicked: file);
    if (!mounted || !parsed.ok) return;

    final r = parsed.data!;
    if (r.skills.isNotEmpty) provider.setSkills(r.skills);
    if (r.summary.isNotEmpty) provider.updateBio(r.summary);
    await provider.syncProfile();
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text('Filled in from ${file.fileName}. Check the details below.',
          style: AppTheme.sansMedium(fontSize: 13, color: Colors.white)),
      backgroundColor: AppTheme.signalPositive,
      behavior: SnackBarBehavior.floating,
    ));
  }

  /// Routes the photo card to the avatar's own camera/gallery sheet, so there
  /// is one capture flow rather than two that can drift apart.
  /// Opens the photo picker.
  ///
  /// This used to show a snackbar reading "Tap your photo above to take or
  /// choose one" — a button whose whole function was to point at a different
  /// button. It opens the same sheet as the avatar now.
  Future<void> _promptPhoto() async {
    final hasPhoto =
        (context.read<JobSeekerProvider>().profile.photoUrl ?? '').isNotEmpty;
    await ProfilePhotoSheet.open(context, hasPhoto: hasPhoto);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<JobSeekerProvider>(context);
    final profile = provider.profile;
    final candidateName = profile.name.isNotEmpty ? profile.name : 'Candidate';
    final candidateEmail = profile.email.isNotEmpty ? profile.email : 'No email added';
    final candidatePhone = profile.phone.isNotEmpty ? profile.phone : '+91 (Verified)';
    final candidateBio = profile.bio.isNotEmpty
        ? profile.bio
        : 'No executive bio added yet. Tap "Edit Bio" below to write a professional summary for hiring managers.';

    final hasResume = profile.resumeFileName != null && profile.resumeFileName!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('Candidate Profile', style: AppTheme.sansBold(fontSize: 18, color: AppTheme.inkOf(context))),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 80),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Column(children: [
          // 1. Candidate Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Tap to take a photo or choose one from the device.
                    const ProfilePhotoAvatar(size: 58),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  candidateName,
                                  style: const TextStyle(fontFamily: 'Archivo').copyWith(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.inkOf(context)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, color: AppTheme.emerald, size: 18),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            candidateEmail,
                            style: AppTheme.sansMedium(fontSize: 12.5, color: AppTheme.textSecondary),
                          ),
                          Text(
                            candidatePhone,
                            style: AppTheme.sansBold(fontSize: 12, color: AppTheme.emeraldDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Dynamic Profile Strength Meter
                Builder(
                  builder: (context) {
                    final strengthPercent = provider.profile.profileStrengthPercent;
                    final Color strengthColor = strengthPercent >= 80
                        ? AppTheme.emeraldDark
                        : (strengthPercent >= 50 ? AppTheme.royalBlue : AppTheme.amber);

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: strengthColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: strengthColor.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            strengthPercent >= 80 ? Icons.verified_user_outlined : Icons.shield_outlined,
                            color: strengthColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Profile Strength', style: AppTheme.sansBold(fontSize: 11.5, color: AppTheme.inkOf(context))),
                                    Text(
                                      strengthPercent == 100 ? '100% Complete & Verified' : '$strengthPercent% Complete',
                                      style: AppTheme.sansBold(fontSize: 11.5, color: strengthColor),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: (strengthPercent / 100.0).clamp(0.05, 1.0),
                                    backgroundColor: AppTheme.borderLight,
                                    valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sits under the profile card, not above it: the card is who you
          // are, these are what is missing from it. Reading the gaps before
          // the identity they belong to was backwards.
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: ProfileBoostCards(
              onAddSkills: () =>
                  ProfileFieldEditor.open(context, ProfileField.skills),
              onUploadResume: _uploadResume,
              onUploadPhoto: _promptPhoto,
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
              ),
              icon: const Icon(Icons.edit_outlined,
                  size: 17, color: AppTheme.royalBlue),
              label: Text('Edit my details',
                  style: AppTheme.sansBold(
                      fontSize: 13.5, color: AppTheme.royalBlue)),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Licences and cards — the field-work equivalent of a resume, and
          //    the single most valuable thing on a trade profile. Employers ask
          //    "does he have the forklift ticket" before anything else.
          if (profile.isFieldWork) ...[
            const _CertificatesCard(),
            const SizedBox(height: 16),
          ],

          // 3. Resume Card. Professional path only: a site worker has no CV,
          //    and a card telling them their profile is missing one is asking
          //    for something they cannot produce.
          if (!profile.isFieldWork)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Resume Document', style: AppTheme.sansBold(fontSize: 14, color: AppTheme.inkOf(context))),
                    if (hasResume)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.emerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('AI Parsed ✓', style: AppTheme.sansBold(fontSize: 11, color: AppTheme.emeraldDark)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgPaper,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasResume ? Icons.picture_as_pdf_rounded : Icons.note_add_outlined,
                        color: hasResume ? AppTheme.signalClosed : AppTheme.textMuted,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasResume ? profile.resumeFileName! : 'No resume uploaded (Manual Profile)',
                              style: AppTheme.sansBold(fontSize: 12.5, color: AppTheme.inkOf(context)),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              hasResume ? 'Updated Recently' : 'Tap to attach PDF resume',
                              style: AppTheme.sansRegular(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showResumeUploadDialog(context, provider),
                        child: Text(hasResume ? 'Change' : '+ Upload', style: AppTheme.sansBold(fontSize: 12, color: AppTheme.royalBlue)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!profile.isFieldWork) const SizedBox(height: 16),

          // 4. Skills / work card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      profile.isFieldWork
                          ? 'Work I can do (${profile.skills.length})'
                          : 'Skills & Competencies (${profile.skills.length})',
                      style: AppTheme.sansBold(
                          fontSize: 14, color: AppTheme.inkOf(context)),
                    ),
                    InkWell(
                      onTap: () => _showAddSkillDialog(context, provider),
                      child: Row(
                        children: [
                          const Icon(Icons.add_circle_outline_rounded, size: 15, color: AppTheme.royalBlue),
                          const SizedBox(width: 4),
                          Text('Add / Search', style: AppTheme.sansBold(fontSize: 12, color: AppTheme.royalBlue)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                profile.skills.isEmpty
                    ? Text(
                        profile.isFieldWork
                            ? 'Nothing added yet. Tap "Add / Search" to pick the work you can do.'
                            : 'No skills added yet. Tap "Add / Search" to choose skills.',
                        style: AppTheme.sansRegular(
                            fontSize: 12, color: AppTheme.textMuted))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.skills.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.bgPaper,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(skill, style: AppTheme.sansBold(fontSize: 12, color: AppTheme.inkOf(context))),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => provider.removeSkill(skill),
                                  child: const Icon(Icons.close_rounded, size: 14, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Executive Bio with Edit Option
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      profile.isFieldWork ? 'About me' : 'Executive Bio',
                      style: AppTheme.sansBold(
                          fontSize: 14, color: AppTheme.inkOf(context)),
                    ),
                    InkWell(
                      onTap: () => _showEditBioDialog(context, provider),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 15, color: AppTheme.royalBlue),
                          const SizedBox(width: 4),
                          Text('Edit Bio', style: AppTheme.sansBold(fontSize: 12, color: AppTheme.royalBlue)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  candidateBio,
                  style: AppTheme.sansRegular(fontSize: 13, color: AppTheme.textSecondary, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Settings & App Preferences (Dark Mode, Notifications, Privacy)
          // Material, not a plain Container: ListTile paints its background and
          // ink splashes onto the nearest Material ancestor, so a decorated box
          // in between hides the tap feedback entirely. Flutter asserts on this
          // in debug.
          Material(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('App Preferences & Settings', style: AppTheme.sansBold(fontSize: 14, color: AppTheme.inkOf(context))),
                const SizedBox(height: 8),



                // Push Notifications
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Interview & Job Alerts', style: AppTheme.sansMedium(fontSize: 13.5, color: AppTheme.textPrimary)),
                  subtitle: Text('Receive real-time ATS shortlist alerts', style: AppTheme.sansRegular(fontSize: 11.5, color: AppTheme.textMuted)),
                  value: _pushNotifications,
                  activeTrackColor: AppTheme.emerald,
                  onChanged: (val) => setState(() => _pushNotifications = val),
                ),
                const Divider(height: 1),

                // Privacy Policy
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.privacy_tip_outlined, color: AppTheme.inkOf(context), size: 20),
                  title: Text('Privacy Policy & Compliance', style: AppTheme.sansMedium(fontSize: 13.5, color: AppTheme.textPrimary)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                  onTap: () => _showPrivacyPolicy(context),
                ),
              ],
            ),
            ),
          ),
          const SizedBox(height: 20),

          // 6. Sign Out Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
              label: Text('Sign Out', style: AppTheme.sansBold(fontSize: 14, color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.signalClosedWash),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                await AuthService.logout();
                await provider.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ),
            ]),
          ),
        ],
      ),
    );
  }
}


/// Licences, cards and certificates — and whether the card itself is on file.
///
/// A card of its own rather than folded in with skills, because it is a
/// different kind of claim. A skill is what somebody says they can do; a licence
/// is a thing they hold, and it is what an employer screens on first for
/// warehouse, driving, security and construction work.
///
/// The distinction this draws is the one Shantosh asked for: a ticked licence
/// and an uploaded licence are not the same thing, and showing them identically
/// let a candidate believe they had submitted a document they had only named.
/// Ticked shows plain; uploaded shows green with its verification state.
class _CertificatesCard extends StatelessWidget {
  const _CertificatesCard();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobSeekerProvider>();
    final certificates = provider.profile.certificates;
    final uploaded =
        certificates.where(provider.hasProofFor).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Licences & Cards (${certificates.length})',
                    style: AppTheme.sansBold(
                        fontSize: 14, color: AppTheme.inkOf(context))),
              ),
              InkWell(
                onTap: () => LicencesSheet.open(context),
                child: Row(
                  children: [
                    const Icon(Icons.upload_file_outlined,
                        size: 16, color: AppTheme.royalBlue),
                    const SizedBox(width: 4),
                    Text('Add / Upload',
                        style: AppTheme.sansBold(
                            fontSize: 12, color: AppTheme.royalBlue)),
                  ],
                ),
              ),
            ],
          ),
          if (certificates.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              uploaded == certificates.length
                  ? 'All $uploaded uploaded and awaiting verification.'
                  : '$uploaded of ${certificates.length} uploaded. '
                      'Tap a card without a file to add it.',
              style: AppTheme.sansRegular(
                  fontSize: 12, color: AppTheme.inkFaintOf(context)),
            ),
          ],
          const SizedBox(height: 12),
          if (certificates.isEmpty)
            Text(
              'No licences added. If you hold any — a driving class, a forklift '
              'licence, a safety card — add them and upload a photo. They get '
              'you shortlisted faster than anything else here.',
              style: AppTheme.sansRegular(
                  fontSize: 12, color: AppTheme.textMuted),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final certificate in certificates)
                  _CertificateChip(
                    label: certificate,
                    proof: provider.documentForCertificate(certificate),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CertificateChip extends StatelessWidget {
  final String label;
  final UploadedDocument? proof;

  const _CertificateChip({required this.label, this.proof});

  @override
  Widget build(BuildContext context) {
    final document = proof;
    final verified = document?.status == DocumentStatus.verified;
    final uploaded = document != null;

    final tint = verified
        ? AppTheme.emeraldDark
        : (uploaded ? AppTheme.royalBlue : AppTheme.textMuted);

    return InkWell(
      onTap: document == null
          ? () => LicencesSheet.open(context)
          : () => DocumentPreview.open(context, document),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: uploaded
              ? tint.withValues(alpha: 0.08)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: uploaded
                ? tint.withValues(alpha: 0.35)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              verified
                  ? Icons.verified_rounded
                  : (uploaded
                      ? Icons.hourglass_top_rounded
                      : Icons.upload_file_outlined),
              size: 13,
              color: tint,
            ),
            const SizedBox(width: 5),
            Text(label,
                style: AppTheme.sansBold(
                    fontSize: 12, color: AppTheme.inkOf(context))),
            const SizedBox(width: 5),
            Text(
              // Says exactly where the document stands. "Not uploaded" is the
              // honest label for a licence that has only been ticked, and it is
              // also the instruction — tapping the chip opens the upload sheet.
              verified
                  ? 'Verified'
                  : (uploaded ? 'Checking' : 'Not uploaded'),
              style: AppTheme.sansMedium(fontSize: 10.5, color: tint),
            ),
          ],
        ),
      ),
    );
  }
}
