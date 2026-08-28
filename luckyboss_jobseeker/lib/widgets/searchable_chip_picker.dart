import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'onboarding_components.dart';

/// A chip picker that shows a few, searches the rest, and suggests what fits.
///
/// The first version rendered every option at once. For "Work you can do" in
/// Construction that is forty-odd chips — a page and a half of scrolling before
/// the next question, with no way to tell the useful ones from the rest.
/// Shantosh: *"don't put all, have like few and have expand view all, and they
/// search and [the] model recommend related skills — having like this looks
/// bad."*
///
/// So it shows [collapsedCount] to begin with, ordered by relevance rather than
/// alphabetically, and everything else is one tap or one search away. Three
/// rules hold it together:
///
/// * **What is already chosen is always visible**, wherever it sits in the
///   list. A selection that scrolls out of view looks like a lost tap.
/// * **[suggested] comes first.** These are the abilities of the specific trade
///   the candidate picked, so they are the ones most likely to apply.
/// * **Anything typed can be added.** No list of trades is complete.
class SearchableChipPicker extends StatefulWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  /// Options worth offering first — normally the chosen role's own abilities,
  /// rather than everything anyone in the category might do.
  final List<String> suggested;

  /// Single choice: tapping a chip replaces the selection rather than adding
  /// to it. Used for a trade, where claiming three is not credible.
  final bool single;

  /// Lets the candidate or employer add a term that is not offered.
  final bool allowCustom;

  /// How many options before the search box appears.
  final int searchThreshold;

  /// How many chips to show before "Show all".
  final int collapsedCount;

  final String searchHint;

  const SearchableChipPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.suggested = const [],
    this.single = false,
    this.allowCustom = true,
    this.searchThreshold = 12,
    this.collapsedCount = 10,
    this.searchHint = 'Search or type your own',
  });

  @override
  State<SearchableChipPicker> createState() => _SearchableChipPickerState();
}

class _SearchableChipPickerState extends State<SearchableChipPicker> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _focus = FocusNode();

  bool _expanded = false;

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _query => _search.text.trim().toLowerCase();

  /// Every option, best first.
  ///
  /// Suggested, then selected, then the rest — so the chips a candidate is
  /// most likely to want are the ones they see without expanding anything.
  List<String> get _ordered {
    final seen = <String>{};
    final out = <String>[];

    void add(Iterable<String> items) {
      for (final item in items) {
        if (seen.add(item)) out.add(item);
      }
    }

    add(widget.suggested.where(widget.options.contains));
    add(widget.selected);
    add(widget.options);
    return out;
  }

  /// What to render, after the search box and the collapse.
  List<String> get _visible {
    final all = _ordered;
    if (_query.isNotEmpty) {
      // Searching means the candidate knows what they want — show every match
      // rather than a truncated list they would then have to expand.
      return all
          .where((o) =>
              o.toLowerCase().contains(_query) || widget.selected.contains(o))
          .toList();
    }
    if (_expanded || all.length <= widget.collapsedCount) return all;

    // Collapsed: the first N, plus anything selected that falls outside them.
    final head = all.take(widget.collapsedCount).toList();
    final selectedOutside =
        widget.selected.where((s) => !head.contains(s)).toList();
    return [...head, ...selectedOutside];
  }

  bool get _canAddTyped {
    final typed = _search.text.trim();
    if (!widget.allowCustom || typed.isEmpty) return false;
    return !widget.options.any((o) => o.toLowerCase() == typed.toLowerCase()) &&
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
    final hiddenCount = _ordered.length - visible.length;

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

        // Only while collapsed and unsearched — expanding is meaningless once a
        // query is narrowing the list anyway.
        if (_query.isEmpty && (hiddenCount > 0 || _expanded)) ...[
          const SizedBox(height: 10),
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _expanded ? 'Show fewer' : 'Show all ${_ordered.length}',
                    style: AppTheme.sansBold(
                        fontSize: 13, color: AppTheme.royalBlue),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 17,
                    color: AppTheme.royalBlue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
