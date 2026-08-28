import 'package:flutter/material.dart';

import '../core/constants/cities.dart';
import '../core/theme/app_theme.dart';

/// Location input with an instant, bundled suggestion list.
///
/// Matches against [Cities] in memory, so the list appears on the same frame as
/// the keystroke — no debounce, no request, no spinner. That is the whole point:
/// location is typed at the very start of a search, and a lag there makes the
/// entire app feel slow regardless of how fast the results are.
///
/// Free text is always accepted. The bundled list covers the cities that carry
/// recruitment volume, not every settlement, and a candidate in a town we did
/// not list must still be able to search for it.
class CityField extends StatefulWidget {
  final TextEditingController controller;

  /// Restricts suggestions to one market when known.
  final String? country;
  final String hint;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  /// Renders label + helper text, for form use rather than search-bar use.
  final String? helper;

  /// How many characters must be typed before suggestions appear.
  ///
  /// Zero — the default — opens the busiest cities the moment the field is
  /// tapped, which is right during onboarding where the candidate may not know
  /// what the app covers. On the search screen it is wrong: a list of eight
  /// cities drops over the results the instant the field is touched, hiding the
  /// screen behind a menu nobody asked for. Shantosh: *"it doesn't need to drop
  /// down five things, only recommend if it is there in the database"*.
  final int minChars;

  const CityField({
    super.key,
    required this.controller,
    this.country,
    this.hint = 'City',
    this.onSubmitted,
    this.onChanged,
    this.helper,
    this.minChars = 0,
  });

  @override
  State<CityField> createState() => _CityFieldState();
}

class _CityFieldState extends State<CityField> {
  final FocusNode _focus = FocusNode();
  List<City> _matches = const [];
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      // Tapping away dismisses the list — but not instantly. A tap on a
      // suggestion blurs the field first, and closing here on that blur removed
      // the list from the tree before the tap could land, so selections did
      // nothing. The pick is committed on pointer-down (see below), which fires
      // first; this delay only has to outlive that.
      if (!_focus.hasFocus) {
        Future<void>.delayed(const Duration(milliseconds: 120), () {
          if (mounted && !_focus.hasFocus) setState(() => _open = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _update(String value) {
    setState(() {
      final query = value.trim();
      if (query.length < widget.minChars) {
        _matches = const [];
        _open = false;
        widget.onChanged?.call(value);
        return;
      }
      _matches = Cities.search(value, country: widget.country);
      // An exact match means they have finished; keeping the list open would
      // cover the next field for no reason.
      _open = _matches.isNotEmpty &&
          !(_matches.length == 1 &&
              _matches.first.name.toLowerCase() == value.trim().toLowerCase());
    });
    widget.onChanged?.call(value);
  }

  void _pick(City city) {
    widget.controller.text = city.name;
    setState(() => _open = false);
    _focus.unfocus();
    widget.onChanged?.call(city.name);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focus,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.search,
          onTap: () => _update(widget.controller.text),
          onChanged: _update,
          onSubmitted: (v) {
            setState(() => _open = false);
            widget.onSubmitted?.call(v);
          },
          style: AppTheme.sansMedium(fontSize: 14.5, color: AppTheme.inkOf(context)),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle:
                AppTheme.sansRegular(fontSize: 14.5, color: AppTheme.inkFaintOf(context)),
            helperText: widget.helper,
            helperStyle:
                AppTheme.sansRegular(fontSize: 12, color: AppTheme.inkFaintOf(context)),
            prefixIcon: Icon(Icons.location_on_outlined,
                size: 19, color: AppTheme.inkFaintOf(context)),
            suffixIcon: widget.controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 17),
                    color: AppTheme.inkFaintOf(context),
                    onPressed: () {
                      widget.controller.clear();
                      _update('');
                    },
                  ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide:
                  BorderSide(color: AppTheme.inkOf(context), width: 1.5),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
          ),
        ),
        if (_open)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 232),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _matches.length,
              separatorBuilder: (_, i) =>
                  Divider(height: 1, color: Theme.of(context).dividerColor),
              itemBuilder: (context, i) {
                final city = _matches[i];
                // Listener, not InkWell: onPointerDown fires before the field
                // loses focus, so the selection is committed no matter what the
                // focus system does next.
                return Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (_) => _pick(city),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(city.name,
                              style: AppTheme.sansMedium(
                                  fontSize: 14, color: AppTheme.inkOf(context))),
                        ),
                        Text(
                          city.country,
                          style: AppTheme.sansRegular(
                              fontSize: 11.5, color: AppTheme.inkFaintOf(context)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
