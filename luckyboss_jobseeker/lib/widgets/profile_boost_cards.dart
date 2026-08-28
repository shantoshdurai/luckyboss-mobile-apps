import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/job_seeker_provider.dart';
import 'licences_sheet.dart';
import 'profile_field_editor.dart';

/// One thing the candidate could add, and what it is worth.
class ProfileBoost {
  final IconData icon;
  final String headline;
  final String action;
  final int gain;
  final VoidCallback onTap;

  const ProfileBoost({
    required this.icon,
    required this.headline,
    required this.action,
    required this.gain,
    required this.onTap,
  });
}

/// Horizontally scrolling "what to add next" tiles.
///
/// A completion percentage on its own is a scold. Each tile names one concrete
/// addition and the exact percentage it is worth, so the number stops being a
/// judgement and becomes a list of things to do.
///
/// The percentages are real — they come from the same weights
/// [JobSeekerProvider.profileCompletion] uses to compute the score. A tile
/// promising +10% that moves the bar by three would be worse than no tile.
class ProfileBoostCards extends StatelessWidget {
  /// Opens the skills editor — a picker, not a text field, so it stays a
  /// callback rather than a ProfileField.
  final VoidCallback onAddSkills;

  /// Opens the resume file picker and the AI parse.
  final VoidCallback onUploadResume;

  /// Opens the camera/gallery sheet.
  final VoidCallback onUploadPhoto;

  const ProfileBoostCards({
    super.key,
    required this.onAddSkills,
    required this.onUploadResume,
    required this.onUploadPhoto,
  });

  @override
  Widget build(BuildContext context) {

    // Every incomplete field gets a card, so the strip is a real to-do list
    // rather than a sample of one. Ordered by what each is worth, because the
    // first card should be the one that moves the score most.
    final state = context.watch<JobSeekerProvider>().completionState;

    // Weight comes from whichever table applies to this candidate, so a card can
    // never advertise a gain the score will not actually deliver.
    final provider = context.read<JobSeekerProvider>();
    final weights = provider.completionWeightsFor;
    final isFieldWork = provider.profile.isFieldWork;
    int gain(String key) => weights[key] ?? 0;

    ProfileBoost editor(
      String key,
      IconData icon,
      String headline,
      String action,
      ProfileField field,
    ) =>
        ProfileBoost(
          icon: icon,
          headline: headline,
          action: action,
          gain: gain(key),
          onTap: () => ProfileFieldEditor.open(context, field),
        );

    // The field list. Nothing here asks for a document, a written summary or a
    // department — a plumber has none of those, and cards demanding them were
    // the app telling him his profile was incomplete in ways he could not fix.
    final fieldBoosts = <ProfileBoost>[
      if (state['role'] != true)
        editor('role', Icons.handyman_outlined,
            'Your trade is the first thing employers search',
            'Add your trade', ProfileField.role),
      if (state['skills'] != true)
        ProfileBoost(
          icon: Icons.build_outlined,
          headline: 'List the work you can do',
          action: 'Add work',
          gain: gain('skills'),
          onTap: onAddSkills,
        ),
      if (state['certificates'] != true)
        ProfileBoost(
          icon: Icons.badge_outlined,
          headline: 'Licences and cards get you shortlisted fastest',
          action: 'Add licences',
          gain: gain('certificates'),
          // Deliberately not the generic field editor. A licence needs a file
          // uploaded, not a name ticked, and routing it through the chip sheet
          // is what let a candidate press Save believing they had submitted a
          // document.
          onTap: () => LicencesSheet.open(context),
        ),
      if (state['permit'] != true)
        editor('permit', Icons.verified_user_outlined,
            'Employers ask this before anything else',
            'Add work permit', ProfileField.workPermit),
      if (state['languages'] != true)
        editor('languages', Icons.translate, 'What languages do you speak?',
            'Add languages', ProfileField.languages),
      if (state['city'] != true)
        editor('city', Icons.location_on_outlined,
            'Jobs near you come first', 'Add location', ProfileField.city),
      if (state['availability'] != true)
        editor('availability', Icons.event_available_outlined,
            'When can you start?', 'Add availability',
            ProfileField.availability),
      if (state['photo'] != true)
        ProfileBoost(
          icon: Icons.photo_camera_outlined,
          headline: 'A photo makes your profile stand out',
          action: 'Add photo',
          gain: gain('photo'),
          onTap: onUploadPhoto,
        ),
      if (state['phone'] != true)
        editor('phone', Icons.phone_outlined,
            'Employers call before they email', 'Add number',
            ProfileField.phone),
    ];

    final professionalBoosts = <ProfileBoost>[
      if (state['skills'] != true)
        ProfileBoost(
          icon: Icons.workspace_premium_outlined,
          headline: 'Skills are how employers find you',
          action: 'Add skills',
          gain: gain('skills'),
          onTap: onAddSkills,
        ),
      if (state['resume'] != true)
        ProfileBoost(
          icon: Icons.description_outlined,
          headline: 'A resume gets you shortlisted faster',
          action: 'Upload resume',
          gain: gain('resume'),
          onTap: onUploadResume,
        ),
      if (state['headline'] != true)
        editor('headline', Icons.star_outline, 'Pitch yourself to recruiters',
            'Add headline', ProfileField.headline),
      if (state['bio'] != true)
        editor('bio', Icons.notes_outlined,
            'Personal details help in shortlisting', 'Add details',
            ProfileField.bio),
      if (state['category'] != true)
        editor('category', Icons.category_outlined,
            'Recruiters look for your area of work', 'Add area',
            ProfileField.category),
      if (state['department'] != true)
        editor('department', Icons.groups_outlined,
            'Recruiters look for your department', 'Add department',
            ProfileField.department),
      if (state['photo'] != true)
        ProfileBoost(
          icon: Icons.photo_camera_outlined,
          headline: 'Profiles with a photo are more noticeable',
          action: 'Upload photo',
          gain: gain('photo'),
          onTap: onUploadPhoto,
        ),
      if (state['projects'] != true)
        editor('projects', Icons.workspaces_outline, 'Add your best works',
            'Add project', ProfileField.projects),
      if (state['languages'] != true)
        editor('languages', Icons.translate,
            'Showcase your communication skills', 'Add languages',
            ProfileField.languages),
      if (state['city'] != true)
        editor('city', Icons.location_on_outlined,
            'Add the location you want to work in', 'Add location',
            ProfileField.city),
      if (state['salary'] != true)
        editor('salary', Icons.payments_outlined,
            'Expected pay sharpens your matches', 'Add salary',
            ProfileField.salary),
      if (state['phone'] != true)
        editor('phone', Icons.phone_outlined,
            'Recruiters call before they email', 'Add number',
            ProfileField.phone),
    ];

    final boosts = isFieldWork ? fieldBoosts : professionalBoosts;

    // Nothing left to add: the section removes itself rather than showing an
    // empty carousel or a congratulatory card nobody asked for.
    if (boosts.isEmpty) return const SizedBox.shrink();

    // Naming the count is what tells the user the strip scrolls. Two visible
    // cards with no label read as "there are two things" rather than "here are
    // the first two of nine".
    final remaining = boosts.fold<int>(0, (sum, b) => sum + b.gain);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${boosts.length} ${boosts.length == 1 ? "thing" : "things"} left to add',
                  style: AppTheme.sansBold(
                      fontSize: 14, color: AppTheme.inkOf(context)),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.signalPositiveWash,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text('+$remaining% available',
                    style: AppTheme.sansBold(
                        fontSize: 11, color: AppTheme.signalPositive)),
              ),
              const SizedBox(width: 6),
              Icon(Icons.swipe_outlined,
                  size: 16, color: AppTheme.inkFaintOf(context)),
            ],
          ),
        ),
        SizedBox(
          height: 152,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            // Always draggable, even where a mouse is the pointer — on web the
            // default physics can make a nested horizontal list feel stuck.
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            // 11 + the tile's own 5 margin = the 16 gutter every other
            // card on this screen uses, so the strip lines up with them.
            padding: const EdgeInsets.symmetric(horizontal: 11),
            itemCount: boosts.length,
            itemBuilder: (context, i) => _SlideInRight(
              index: i,
              child: _tile(context, boosts[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, ProfileBoost boost) => Container(
        width: 188,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(boost.icon, size: 19, color: AppTheme.signalSource),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.signalPositiveWash,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('+${boost.gain}%',
                      style: AppTheme.sansBold(
                          fontSize: 10.5, color: AppTheme.signalPositive)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                boost.headline,
                style: AppTheme.sansMedium(
                    fontSize: 13, color: AppTheme.inkOf(context)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 34,
              child: ElevatedButton(
                onPressed: boost.onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.signalSourceWash,
                  foregroundColor: AppTheme.signalSource,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(boost.action,
                    style: AppTheme.sansBold(
                        fontSize: 12.5, color: AppTheme.signalSource)),
              ),
            ),
          ],
        ),
      );
}

/// Slides in from the right, staggered.
///
/// A different entrance from the feed's fade-up, so the horizontal strip reads
/// as a distinct kind of content rather than more of the same list.
class _SlideInRight extends StatefulWidget {
  final Widget child;
  final int index;

  const _SlideInRight({required this.child, required this.index});

  @override
  State<_SlideInRight> createState() => _SlideInRightState();
}

class _SlideInRightState extends State<_SlideInRight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(
      Duration(milliseconds: 90 * widget.index.clamp(0, 5)),
      () {
        if (mounted) _c.forward();
      },
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: CurvedAnimation(parent: _c, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.28, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic)),
          child: widget.child,
        ),
      );
}
