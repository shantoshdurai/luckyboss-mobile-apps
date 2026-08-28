import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'onboarding_components.dart';

/// A chip picker that can be searched, and typed into when the list falls short.
///
/// Built because both apps had the same problem from opposite ends. An employer
/// picking what a Construction job requires was shown twenty-five ability chips
/// with no way to filter — Shantosh's words, *"they cant even search skills"* —
/// and a candidate picking their own abilities had the same wall. Scrolling a
/// grid hunting for "Scaffolding" is not selection, it is search done by eye.
///
/// Three behaviours worth keeping:
///
/// * **The search box only appears when it earns its place.** Below
///   [searchThreshold] options there is nothing to search, and an empty text
///   field above six chips is one more thing to read past.
/// * **Selected chips stay visible while filtering.** Typing "weld" must not
///   hide the four things already chosen, or it looks like the taps were lost.
/// * **Anything typed can be added.** No list of trades is complete. A
///   shuttering carpenter who cannot enter "shuttering" has been told the app
///   does not cover him.
class SearchableChipPicker extends StatefulWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  /// Single choice: tapping a chip replaces the selection rather than adding
  /// to it. Used for a trade, where claiming three is not credible.
  final bool single;

  /// Lets the candidate or employer add a term that is not offered.
  final bool allowCustom;

  /// How many options before the search box appears.
  final int searchThreshold;

  final String searchHint;

  const SearchableChipPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.single = false,
    this.allowCustom = true,
    this.searchThreshold = 12,
    this.searchHint = 'Search or type your own',
  });

  @override
  State<SearchableChipPicker> createState() => _SearchableChipPickerState();
}

class _SearchableChipPickerState extends State<SearchableChipPicker> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _query => _search.text.trim().toLowerCase();

  /// The chips to render.
  ///
  /// Anything already selected survives the filter, and anything selected that
  /// is not in [options] at all — a typed entry — is appended so it does not
  /// vanish when the sheet is reopened.
  List<String> get _visible {
    final extras = widget.selected.where((s) => !widget.options.contains(s));
    final all = [...widget.options, ...extras];
    if (_query.isEmpty) return all;
    return all
        .where((o) =>
            o.toLowerCase().contains(_query) || widget.selected.contains(o))
        .toList();
  }

  /// True when what has been typed is not already an option, so it can be added.
  bool get _canAddTyped {
    final typed = _search.text.trim();
    if (!widget.allowCustom || typed.isEmpty) return false;
    return !widget.options
            .any((o) => o.toLowerCase() == typed.toLowerCase()) &&
        !widget.selected.any((s) => s.toLowerCase() == typed.toLowerCase());
  }

  void _addTyped() {
    final typed = _search.text.trim();
    if (typed.isEmpty) return;
    widget.onToggle(typed);
    _search.clear();
    _focus.unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final showSearch = widget.options.length >= widget.searchThreshold;
    final visible = _visible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSearch) ...[
          TextField(
            controller: _search,
            focusNode: _focus,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _canAddTyped ? _addTyped() : _focus.unfocus(),
            style: AppTheme.sansMedium(
                fontSize: 14, color: AppTheme.inkOf(context)),
            decoration: InputDecoration(
              hintText: widget.searchHint,
              hintStyle: AppTheme.sansRegular(
                  fontSize: 13.5, color: AppTheme.inkFaintOf(context)),
              prefixIcon: Icon(Icons.search,
                  size: 18, color: AppTheme.inkFaintOf(context)),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close,
                          size: 16, color: AppTheme.inkFaintOf(context)),
                      tooltip: 'Clear',
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                    ),
              filled: true,
              fillColor: AppTheme.paperOf(context),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        if (visible.isEmpty && !_canAddTyped)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Nothing matches "${_search.text.trim()}".',
                style: AppTheme.sansRegular(
                    fontSize: 13, color: AppTheme.inkFaintOf(context))),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // The typed term first, so adding it is one tap from where the
              // eye already is rather than at the end of a filtered list.
              if (_canAddTyped)
                InkWell(
                  onTap: _addTyped,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.signalSource.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppTheme.signalSource),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add,
                            size: 15, color: AppTheme.signalSource),
                        const SizedBox(width: 6),
                        Text('Add "${_search.text.trim()}"',
                            style: AppTheme.sansSemiBold(
                                fontSize: 13.5,
                                color: AppTheme.signalSource)),
                      ],
                    ),
                  ),
                ),
              for (final option in visible)
                LbChoiceChip(
                  label: option,
                  selected: widget.selected.contains(option),
                  showAffordance: !widget.single,
                  onTap: () => widget.onToggle(option),
                ),
            ],
          ),
      ],
    );
  }
}
