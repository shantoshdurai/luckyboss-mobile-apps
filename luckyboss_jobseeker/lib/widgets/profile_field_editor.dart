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

  const ProfileField({
    required this.key,
    required this.title,
    required this.prompt,
    required this.kind,
    this.hint = '',
    this.options = const [],
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

  /// Free-list rather than the taxonomy picker used in onboarding — this is the
  /// quick correction path, not first-time entry.
  static const skills = ProfileField(
    key: 'skills',
    title: 'Your skills',
    prompt: 'One per line. These are what employers search on.',
    hint: 'Flutter, Inventory Management, Patient Care — one per line',
    kind: EditorKind.list,
  );

  static const languages = ProfileField(
    key: 'languages',
    title: 'Languages',
    prompt: 'Languages you can work in.',
    kind: EditorKind.chips,
    options: [
      'English', 'Hindi', 'Tamil', 'Telugu', 'Malayalam', 'Kannada',
      'Bahasa Malaysia', 'Mandarin', 'Cantonese', 'Bengali', 'Marathi',
      'Punjabi', 'Gujarati', 'Arabic',
    ],
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

  List<String> get _options => widget.field.key == 'category'
      ? AppData.categories.where((c) => c != 'All Roles').toList()
      : widget.field.options;

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
      _ => '',
    };

    _controller = TextEditingController(text: existing);

    if (widget.field.kind == EditorKind.chips) {
      _selected.addAll(
        existing.split('\n').where((e) => e.trim().isNotEmpty),
      );
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
    final normalised = widget.field.key == 'category' || widget.field.key == 'department'
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

  @override
  Widget build(BuildContext context) {
    final singleChoice =
        widget.field.key == 'category' || widget.field.key == 'department';

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
                    children: _options.map((o) {
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
              )
            else if (widget.field.kind == EditorKind.city)
              CityField(
                controller: _controller,
                hint: widget.field.hint,
                onChanged: (_) => setState(() {}),
              )
            else
              TextField(
                controller: _controller,
                autofocus: true,
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
