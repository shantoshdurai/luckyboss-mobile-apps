import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_data.dart';
import '../core/theme/app_theme.dart';
import '../providers/job_seeker_provider.dart';
import 'city_field.dart';

/// How a profile field is edited.
enum EditorKind { text, multiline, chips, list, city }

/// One editable profile field.
///
/// Declared in one place so a boost card, the editor sheet and the persisted
/// key can never drift apart — adding a field means adding one entry here, not
/// touching three files.
class ProfileField {
  /// Matches the key in [JobSeekerProvider.completionWeights] and the column
  /// the server stores it in.
  final String key;
  final String title;
  final String prompt;
  final String hint;
  final EditorKind kind;
  final List<String> options;

  /// Lets a chips field also accept typed entries.
  ///
  /// Necessary rather than nice: no list of trades is complete, and a candidate
  /// whose work is not on it must never be stuck. A shuttering carpenter who
  /// cannot enter "shuttering" has been told the app does not cover him.
  final bool allowFreeText;

  const ProfileField({
    required this.key,
    required this.title,
    required this.prompt,
    required this.kind,
    this.hint = '',
    this.options = const [],
    this.allowFreeText = false,
  });

  static const headline = ProfileField(
    key: 'headline',
    title: 'Your headline',
    prompt: 'One line recruiters see first, under your name.',
    hint: 'e.g. Flutter developer with 3 years in fintech',
    kind: EditorKind.text,
  );

  static const bio = ProfileField(
    key: 'bio',
    title: 'Professional summary',
    prompt: 'A short paragraph on what you do and what you are looking for.',
    hint: 'Two or three sentences is plenty.',
    kind: EditorKind.multiline,
  );

  static const department = ProfileField(
    key: 'department',
    title: 'Your department',
    prompt: 'The function you work in. Recruiters filter on this.',
    kind: EditorKind.chips,
    options: [
      'Engineering', 'IT & Software', 'Operations', 'Logistics',
      'Finance & Accounts', 'Sales', 'Marketing', 'Human Resources',
      'Healthcare', 'Customer Service', 'Administration', 'Design',
      'Education', 'Legal', 'Skilled Trades',
    ],
  );

  static const category = ProfileField(
    key: 'category',
    title: 'Area of work',
    prompt: 'The market you want to be matched in.',
    kind: EditorKind.chips,
    options: [],
  );

  static const city = ProfileField(
    key: 'city',
    title: 'Your city',
    prompt: 'Where you can realistically work.',
    hint: 'e.g. Chennai, Singapore, Kuala Lumpur',
    kind: EditorKind.city,
  );

  static const salary = ProfileField(
    key: 'salary',
    title: 'Expected salary',
    prompt: 'Monthly. Used for matching — employers never see this figure.',
    hint: 'Amount per month',
    kind: EditorKind.text,
  );

  static const phone = ProfileField(
    key: 'phone',
    title: 'Mobile number',
    prompt: 'Recruiters call before they email.',
    hint: 'Include your country code',
    kind: EditorKind.text,
  );

  static const projects = ProfileField(
    key: 'projects',
    title: 'Your best work',
    prompt: 'Projects worth showing. One per line.',
    hint: 'e.g. Warehouse stock app — cut picking errors by 30%',
    kind: EditorKind.list,
  );

  /// Chips drawn from the candidate's own trade, with free text underneath.
  ///
  /// This was a bare text box hinting "Flutter, Inventory Management, Patient
  /// Care — one per line", and it opened from a card headed *List the work you
  /// can do*. A mason tapping that was shown three software-adjacent examples
  /// and an empty box; the only reasonable conclusion is that the app is for
  /// somebody else. [_options] narrows the chips to their role.
  static const skills = ProfileField(
    key: 'skills',
    title: 'Your skills',
    prompt: 'Tap everything you can do. Add your own at the bottom.',
    hint: 'Type anything not listed above',
    kind: EditorKind.chips,
    allowFreeText: true,
  );

  static const languages = ProfileField(
    key: 'languages',
    title: 'Languages',
    prompt: 'Languages you can work in.',
    kind: EditorKind.chips,
    options: AppData.commonLanguages,
  );

  // ---------------------------------------------------------------------------
  // FIELD WORK
  //
  // Four fields that had no editor at all, because the profile they were part
  // of was built around a CV. Spec §31 asks for every one of them, and for a
  // trade candidate they carry more weight than anything above.
  // ---------------------------------------------------------------------------

  /// The trade itself. Multi-select is wrong here — a candidate is a plumber or
  /// an electrician, and letting them tick both produces a profile no employer
  /// trusts. Options are filled at open time from the chosen category.
  static const role = ProfileField(
    key: 'role',
    title: 'Your trade',
    prompt: 'What do you do? Employers search by this first.',
    kind: EditorKind.chips,
    options: [],
  );

  /// Kept for the completion table's key only. The licences UI is
  /// [LicencesSheet], because ticking a name is not uploading a card and the
  /// two must not share a screen that ends in a Save button.
  static const certificates = ProfileField(
    key: 'certificates',
    title: 'Licences and cards',
    prompt: 'Anything you hold.',
    kind: EditorKind.chips,
    options: [],
  );

  static const workPermit = ProfileField(
    key: 'permit',
    title: 'Work permit',
    prompt: 'Can you legally work in the country you want to work in?',
    kind: EditorKind.chips,
    options: AppData.workPermitStatuses,
  );

  static const availability = ProfileField(
    key: 'availability',
    title: 'When you can start',
    prompt: 'Employers filter on this more than almost anything else.',
    kind: EditorKind.chips,
    options: AppData.availabilityOptions,
  );
}

/// The editor sheet.
///
/// Opens straight onto the input with the keyboard up. Every boost card used to
/// call an empty callback — pressing "Upload resume" or "Add summary" did
/// nothing at all — and this is what those now open.
class ProfileFieldEditor extends StatefulWidget {
  final ProfileField field;

  const ProfileFieldEditor({super.key, required this.field});

  /// Returns true when something was saved.
  static Future<bool> open(BuildContext context, ProfileField field) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfileFieldEditor(field: field),
    );
    return saved ?? false;
  }

  @override
  State<ProfileFieldEditor> createState() => _ProfileFieldEditorState();
}

class _ProfileFieldEditorState extends State<ProfileFieldEditor> {
  late final TextEditingController _controller;
  final Set<String> _selected = {};
  bool _saving = false;

  /// Options for three of the fields are not fixed — they come from the
  /// candidate's own category, so a warehouse worker is offered forklift and
  /// reach-truck licences rather than a scaffolding certificate.
  List<String> get _options {
    final profile = context.read<JobSeekerProvider>().profile;
    final category = AppData.categoryByName(profile.preferredCategory);

    final role = profile.roleTitle.isNotEmpty
        ? profile.roleTitle
        : profile.currentTitle;

    return switch (widget.field.key) {
      'category' => AppData.categories.where((c) => c != AppData.allRoles).toList(),
      // Falls back to every role in the app when the category is unknown — an
      // empty picker would leave the candidate with no way to answer at all.
      'role' => category?.roleNames ?? AppData.allRoleTitles,
      // Narrowed to the job they actually do. This picker used to show the same
      // five cards to everyone regardless of what they had chosen.
      'certificates' =>
        AppData.certificatesFor(category: profile.preferredCategory, role: role),
      'skills' =>
        AppData.abilitiesFor(category: profile.preferredCategory, role: role),
      _ => widget.field.options,
    };
  }

  @override
  void initState() {
    super.initState();
    final p = context.read<JobSeekerProvider>().profile;

    // Seeded with what is already stored, so editing is a correction rather
    // than a re-entry.
    final existing = switch (widget.field.key) {
      'headline' => p.headline,
      'bio' => p.bio,
      'department' => p.department,
      'category' => p.preferredCategory,
      'city' => p.currentCity,
      'salary' => p.expectedSalary,
      'phone' => p.phone,
      'projects' => p.projects.join('\n'),
      'languages' => p.languages.join('\n'),
      'role' => p.roleTitle.isNotEmpty ? p.roleTitle : p.currentTitle,
      'certificates' => p.certificates.join('\n'),
      'permit' => p.workPermitStatus,
      'availability' => p.availability,
      _ => '',
    };

    _controller = TextEditingController(text: existing);

    if (widget.field.kind == EditorKind.chips) {
      _selected.addAll(
        existing.split('\n').where((e) => e.trim().isNotEmpty),
      );
      // A chips field that also takes typed entries starts with an empty box —
      // seeding it with the existing values would put the whole list back into
      // the text field as well as the chips.
      if (widget.field.allowFreeText) _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<JobSeekerProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _saving = true);

    final Object value = switch (widget.field.kind) {
      EditorKind.chips => _selected.toList(),
      EditorKind.list => _controller.text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList(),
      _ => _controller.text.trim(),
    };

    // Single-choice chips store a string, not a list.
    const singleChoice = {'category', 'department', 'role', 'permit', 'availability'};
    final normalised = singleChoice.contains(widget.field.key)
        ? (_selected.isEmpty ? '' : _selected.first)
        : value;

    await provider.setProfileField(widget.field.key, normalised);

    if (!mounted) return;
    navigator.pop(true);
    messenger.showSnackBar(
      SnackBar(
        content: Text('${widget.field.title} saved.',
            style: AppTheme.sansMedium(
                fontSize: 13, color: AppTheme.onInkOf(context))),
        backgroundColor: AppTheme.signalPositive,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool get _hasValue => switch (widget.field.kind) {
        EditorKind.chips => _selected.isNotEmpty,
        _ => _controller.text.trim().isNotEmpty,
      };

  /// The chips to render: the suggested list, plus anything already selected
  /// that is not in it. Without the second part a typed entry disappears from
  /// the sheet the moment it is reopened, which looks exactly like it was never
  /// saved.
  List<String> get _chipOptions {
    final options = _options;
    final extra = _selected.where((s) => !options.contains(s)).toList()..sort();
    return [...options, ...extra];
  }

  void _addTyped() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _selected.add(value);
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final singleChoice = const {'category', 'department', 'role', 'permit', 'availability'}
        .contains(widget.field.key);

    return Padding(
      // Lifts the sheet above the keyboard rather than letting it cover the
      // field the user is typing into.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(widget.field.title,
                style: AppTheme.serifTitle(
                    fontSize: 22, color: AppTheme.inkOf(context))),
            const SizedBox(height: 5),
            Text(widget.field.prompt,
                style: AppTheme.sansRegular(
                    fontSize: 13, color: AppTheme.inkMutedOf(context))),
            const SizedBox(height: 18),

            if (widget.field.kind == EditorKind.chips)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.36,
                ),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 9,
                    runSpacing: 10,
                    children: _chipOptions.map((o) {
                      final on = _selected.contains(o);
                      return InkWell(
                        onTap: () => setState(() {
                          if (singleChoice) {
                            _selected
                              ..clear()
                              ..add(o);
                          } else {
                            on ? _selected.remove(o) : _selected.add(o);
                          }
                        }),
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                            color: on
                                ? AppTheme.signalPositiveWash
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: on
                                  ? AppTheme.signalPositive
                                  : Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Text(
                            o,
                            style: on
                                ? AppTheme.sansSemiBold(
                                    fontSize: 13.5,
                                    color: AppTheme.signalPositive)
                                : AppTheme.sansMedium(
                                    fontSize: 13.5,
                                    color: AppTheme.inkOf(context)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ),
            // Free text under the chips, not instead of them. No list of
            // trades is ever complete, and a candidate whose work is missing
            // must not be stuck — but making them type when a tap would do is
            // what the field path exists to avoid, so the chips come first and
            // this is the escape hatch below them.
            if (widget.field.kind == EditorKind.chips &&
                widget.field.allowFreeText) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _addTyped(),
                      style: AppTheme.sansMedium(
                          fontSize: 14, color: AppTheme.inkOf(context)),
                      decoration: InputDecoration(
                        hintText: widget.field.hint,
                        hintStyle: AppTheme.sansRegular(
                            fontSize: 13.5,
                            color: AppTheme.inkFaintOf(context)),
                        filled: true,
                        fillColor: AppTheme.paperOf(context),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed:
                        _controller.text.trim().isEmpty ? null : _addTyped,
                    icon: const Icon(Icons.add_circle, size: 28),
                    color: AppTheme.signalSource,
                    tooltip: 'Add',
                  ),
                ],
              ),
            ],

            if (widget.field.kind == EditorKind.city)
              CityField(
                controller: _controller,
                hint: widget.field.hint,
                onChanged: (_) => setState(() {}),
              )
            // Chips fields own the controller for their free-text row above,
            // so they must not also render the plain input below it.
            else if (widget.field.kind != EditorKind.chips)
              TextField(
                controller: _controller,
                // Only a plain text field earns the keyboard on open. Chips
                // fields do not: their answer is a tap.
                autofocus: widget.field.kind != EditorKind.chips,
                minLines: widget.field.kind == EditorKind.text ? 1 : 3,
                maxLines: widget.field.kind == EditorKind.text ? 1 : 6,
                keyboardType: widget.field.key == 'salary'
                    ? TextInputType.number
                    : TextInputType.multiline,
                onChanged: (_) => setState(() {}),
                style: AppTheme.sansMedium(
                    fontSize: 15, color: AppTheme.inkOf(context)),
                decoration: InputDecoration(
                  hintText: widget.field.hint,
                  hintStyle: AppTheme.sansRegular(
                      fontSize: 14, color: AppTheme.inkFaintOf(context)),
                  filled: true,
                  fillColor: AppTheme.paperOf(context),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _hasValue && !_saving ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryFillOf(context),
                  foregroundColor: AppTheme.onPrimaryFillOf(context),
                  disabledBackgroundColor: Theme.of(context).dividerColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                              AppTheme.onPrimaryFillOf(context)),
                        ),
                      )
                    : Text('Save',
                        style: AppTheme.sansBold(
                          fontSize: 15,
                          color: _hasValue
                              ? AppTheme.onPrimaryFillOf(context)
                              : AppTheme.inkFaintOf(context),
                        )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
