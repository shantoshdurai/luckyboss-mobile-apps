import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/skill_service.dart';
import '../../../widgets/onboarding_components.dart';

/// Key skills, with suggestions that react to what has been picked.
///
/// The behaviour worth preserving: every skill added re-queries the taxonomy,
/// so picking Flutter surfaces Dart, Kotlin and React Native, and picking a
/// second skill narrows the list toward a coherent role rather than widening it.
/// That is what turns skill entry from recall ("what am I supposed to type?")
/// into recognition ("yes, that one too").
///
/// Free text is always allowed. A candidate whose skill is not in the taxonomy
/// must never be stuck — their entry is accepted, sent to the server, and the
/// taxonomy learns from it.
class KeySkillsStep extends StatefulWidget {
  final List<String> selected;

  /// Job title or course, used to seed the opening list before anything is picked.
  final String seedCategory;
  final ValueChanged<List<String>> onChanged;

  const KeySkillsStep({
    super.key,
    required this.selected,
    required this.onChanged,
    this.seedCategory = '',
  });

  @override
  State<KeySkillsStep> createState() => _KeySkillsStepState();
}

class _KeySkillsStepState extends State<KeySkillsStep> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  List<SkillSuggestion> _suggestions = [];
  List<SkillSuggestion> _typeahead = [];
  bool _loadingSuggestions = true;

  /// Debounces the type-ahead so a request is not fired per keystroke.
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _refreshSuggestions();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Reloads the suggestion list for the current selection.
  ///
  /// With nothing picked this is the category-seeded opening list; after that it
  /// is the related-skill graph.
  Future<void> _refreshSuggestions() async {
    setState(() => _loadingSuggestions = true);

    final results = widget.selected.isEmpty
        ? await SkillService.suggested(category: widget.seedCategory)
        : await SkillService.related(widget.selected);

    if (!mounted) return;
    setState(() {
      // Defensive: the server already excludes selections, but a stale
      // in-flight response from before the last tap could still contain one.
      _suggestions = results
          .where((s) => !_isSelected(s.name))
          .toList();
      _loadingSuggestions = false;
    });
  }

  bool _isSelected(String name) => widget.selected
      .any((s) => s.toLowerCase().trim() == name.toLowerCase().trim());

  void _add(String raw) {
    final name = raw.trim();
    if (name.isEmpty || _isSelected(name)) return;

    widget.onChanged([...widget.selected, name]);
    _controller.clear();
    setState(() => _typeahead = []);
    _refreshSuggestions();
  }

  void _remove(String name) {
    widget.onChanged(
      widget.selected.where((s) => s.toLowerCase() != name.toLowerCase()).toList(),
    );
    _refreshSuggestions();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();

    if (query.length < 2) {
      setState(() => _typeahead = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 280), () async {
      final results = await SkillService.search(query);
      if (!mounted) return;
      setState(() {
        _typeahead = results.where((s) => !_isSelected(s.name)).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Key skills',
            style: AppTheme.serifTitle(fontSize: 26, color: AppTheme.inkOf(context))),
        const SizedBox(height: 6),
        Text(
          'Employers search by skill. The more precise these are, the better your matches.',
          style: AppTheme.sansRegular(fontSize: 14, color: AppTheme.inkMutedOf(context)),
        ),
        const SizedBox(height: 24),

        _searchField(),

        // Type-ahead results replace the suggestion list while typing — showing
        // both at once puts two competing lists of chips on screen.
        if (_typeahead.isNotEmpty) ...[
          const SizedBox(height: 14),
          _chipWrap(_typeahead.map((s) => LbChoiceChip(
                label: s.name,
                selected: false,
                onTap: () => _add(s.name),
              ))),
        ] else ...[
          if (widget.selected.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text('Your skills (${widget.selected.length})',
                style: AppTheme.sansBold(fontSize: 13.5, color: AppTheme.inkOf(context))),
            const SizedBox(height: 10),
            _chipWrap(widget.selected.map((name) => LbChoiceChip(
                  label: name,
                  selected: true,
                  onTap: () => _remove(name),
                ))),
          ],
          const SizedBox(height: 24),
          _suggestionSection(),
        ],
      ],
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _controller,
      focusNode: _focus,
      textInputAction: TextInputAction.done,
      onChanged: _onQueryChanged,
      // Accepting the raw text on submit is what guarantees a candidate is
      // never blocked by a gap in the taxonomy.
      onSubmitted: _add,
      style: AppTheme.sansMedium(fontSize: 15, color: AppTheme.inkOf(context)),
      decoration: InputDecoration(
        hintText: 'e.g. Flutter, Inventory Management, Patient Care',
        hintStyle: AppTheme.sansRegular(fontSize: 14.5, color: AppTheme.inkFaintOf(context)),
        prefixIcon: Icon(Icons.search, size: 20, color: AppTheme.inkFaintOf(context)),
        suffixIcon: _controller.text.trim().isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.add_circle, size: 22, color: AppTheme.signalPositive),
                onPressed: () => _add(_controller.text),
              ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.inkOf(context), width: 1.6),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _suggestionSection() {
    if (_loadingSuggestions) {
      return Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              valueColor: AlwaysStoppedAnimation(AppTheme.inkFaintOf(context)),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            widget.selected.isEmpty
                ? 'Finding skills for you…'
                : 'Finding skills related to your selection…',
            style: AppTheme.sansRegular(fontSize: 13, color: AppTheme.inkFaintOf(context)),
          ),
        ],
      );
    }

    if (_suggestions.isEmpty) {
      // Reached when the taxonomy and AI both returned nothing — usually
      // offline. Say so plainly; typing still works.
      return Text(
        'Type your skills above to add them.',
        style: AppTheme.sansRegular(fontSize: 13, color: AppTheme.inkFaintOf(context)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.selected.isEmpty
              ? 'Suggested for you'
              : 'Related to what you picked',
          style: AppTheme.sansBold(fontSize: 13.5, color: AppTheme.inkOf(context)),
        ),
        const SizedBox(height: 4),
        Text(
          widget.selected.isEmpty
              ? 'Tap to add. More appear as you go.'
              : 'These often go together — tap any that apply.',
          style: AppTheme.sansRegular(fontSize: 12.5, color: AppTheme.inkFaintOf(context)),
        ),
        const SizedBox(height: 12),
        _chipWrap(_suggestions.map((s) => LbChoiceChip(
              label: s.name,
              selected: false,
              onTap: () => _add(s.name),
            ))),
      ],
    );
  }

  Widget _chipWrap(Iterable<Widget> chips) =>
      Wrap(spacing: 9, runSpacing: 10, children: chips.toList());
}
