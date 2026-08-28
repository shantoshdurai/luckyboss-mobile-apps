import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_data.dart';
import '../core/theme/app_theme.dart';

/// Digit grouping and length rules per market.
///
/// Grouping is not decoration. A 10-digit string is near-impossible to
/// proof-read as one run, which is how people mistype their own number and then
/// wait for an SMS that was never going to arrive. Each market is grouped the
/// way its own people write it — 98765 43210 in India, 8123 4567 in Singapore —
/// so the number on screen looks like the number in the user's head.
class PhoneFormat {
  final String iso;
  final String dialCode;
  final String flag;
  final String name;

  /// Digits per visual group, in order.
  final List<int> groups;

  /// A real, correctly-shaped example for this market.
  final String example;

  const PhoneFormat({
    required this.iso,
    required this.dialCode,
    required this.flag,
    required this.name,
    required this.groups,
    required this.example,
  });

  int get digitCount => groups.fold(0, (a, b) => a + b);

  String get hint {
    final out = StringBuffer();
    var i = 0;
    for (var g = 0; g < groups.length; g++) {
      if (g > 0) out.write(' ');
      out.write(example.substring(i, i + groups[g]));
      i += groups[g];
    }
    return out.toString();
  }

  static const List<PhoneFormat> all = [
    PhoneFormat(
      iso: 'IN', dialCode: '+91', flag: '🇮🇳', name: 'India',
      groups: [5, 5], example: '9876543210',
    ),
    PhoneFormat(
      iso: 'SG', dialCode: '+65', flag: '🇸🇬', name: 'Singapore',
      groups: [4, 4], example: '81234567',
    ),
    PhoneFormat(
      iso: 'MY', dialCode: '+60', flag: '🇲🇾', name: 'Malaysia',
      groups: [2, 3, 4], example: '123456789',
    ),
  ];

  static PhoneFormat byIso(String iso) =>
      all.firstWhere((f) => f.iso == iso, orElse: () => all.first);
}

/// Inserts spaces between digit groups as the user types.
///
/// Works on digits only and recomputes the caret from the number of digits
/// before it, rather than nudging the old offset. Nudging is what makes phone
/// fields jump the cursor to the end when you edit the middle of a number —
/// the caret has to be derived from the content, not patched.
class _GroupingFormatter extends TextInputFormatter {
  final List<int> groups;

  const _GroupingFormatter(this.groups);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    final max = groups.fold(0, (a, b) => a + b);
    final kept = digits.length > max ? digits.substring(0, max) : digits;

    // How many digits sit to the left of the caret in the incoming value.
    final digitsBeforeCaret = next.text
        .substring(0, next.selection.baseOffset.clamp(0, next.text.length))
        .replaceAll(RegExp(r'\D'), '')
        .length;

    final buffer = StringBuffer();
    var caret = 0;
    var index = 0;

    for (var g = 0; g < groups.length && index < kept.length; g++) {
      if (g > 0) {
        buffer.write(' ');
        if (index < digitsBeforeCaret) caret++;
      }
      final end = (index + groups[g]).clamp(0, kept.length);
      for (var i = index; i < end; i++) {
        buffer.write(kept[i]);
        if (i < digitsBeforeCaret) caret++;
      }
      index = end;
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret.clamp(0, text.length)),
    );
  }
}

/// Country selector plus grouped number entry.
///
/// Reports the E.164 number (`+6591234567`) through [onChanged] — that is the
/// only form worth passing to an SMS provider, and building it here means no
/// caller has to remember to strip the spaces this field added.
class PhoneNumberField extends StatefulWidget {
  final PhoneFormat initialFormat;
  final ValueChanged<String> onChanged;

  /// Fired when the field holds a complete number and the user submits.
  final VoidCallback? onSubmitted;
  final ValueChanged<PhoneFormat>? onCountryChanged;
  final String? errorText;
  final bool enabled;
  final bool autofocus;

  const PhoneNumberField({
    super.key,
    required this.onChanged,
    this.initialFormat = const PhoneFormat(
      iso: 'IN', dialCode: '+91', flag: '🇮🇳', name: 'India',
      groups: [5, 5], example: '9876543210',
    ),
    this.onSubmitted,
    this.onCountryChanged,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
  });

  @override
  State<PhoneNumberField> createState() => PhoneNumberFieldState();
}

class PhoneNumberFieldState extends State<PhoneNumberField> {
  late PhoneFormat _format = widget.initialFormat;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  String get digits => _controller.text.replaceAll(RegExp(r'\D'), '');

  /// True once the number has the exact digit count its market expects.
  bool get isComplete => digits.length == _format.digitCount;

  String get e164 => '${_format.dialCode}$digits';

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onCountryChanged(PhoneFormat? next) {
    if (next == null || next.iso == _format.iso) return;
    setState(() {
      _format = next;
      // Regrouping the existing digits under the new market's rules keeps a
      // half-typed number rather than silently discarding the user's work.
      final existing = digits;
      _controller.value = _GroupingFormatter(next.groups).formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(
          text: existing,
          selection: TextSelection.collapsed(offset: existing.length),
        ),
      );
    });
    widget.onCountryChanged?.call(next);
    widget.onChanged(e164);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final borderColor = hasError
        ? AppTheme.signalClosed
        : _focus.hasFocus
            ? AppTheme.inkOf(context)
            : Theme.of(context).dividerColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: _focus.hasFocus || hasError ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PhoneFormat>(
                    value: _format,
                    onChanged: widget.enabled ? _onCountryChanged : null,
                    borderRadius: BorderRadius.circular(14),
                    icon: Icon(Icons.expand_more, size: 18, color: AppTheme.inkMutedOf(context)),
                    items: PhoneFormat.all
                        .map((f) => DropdownMenuItem(
                              value: f,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(f.flag, style: const TextStyle(fontSize: 17)),
                                  const SizedBox(width: 7),
                                  Text(
                                    f.dialCode,
                                    style: AppTheme.sansSemiBold(
                                        fontSize: 15, color: AppTheme.inkOf(context)),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 26,
                color: Theme.of(context).dividerColor,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  // Lets the OS offer the device's own number instead of making
                  // the user recall and retype it.
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _GroupingFormatter(_format.groups),
                  ],
                  style: AppTheme.sansSemiBold(
                    fontSize: 18,
                    color: AppTheme.inkOf(context),
                  ).copyWith(letterSpacing: 1.1),
                  decoration: InputDecoration(
                    hintText: _format.hint,
                    hintStyle: AppTheme.sansRegular(
                      fontSize: 18,
                      color: AppTheme.inkFaintOf(context),
                    ).copyWith(letterSpacing: 1.1),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    counterText: '',
                  ),
                  onChanged: (_) {
                    setState(() {});
                    widget.onChanged(e164);
                  },
                  onSubmitted: (_) {
                    if (isComplete) widget.onSubmitted?.call();
                  },
                ),
              ),
              // A quiet completion tick. The user gets confirmation they typed
              // the right number of digits without having to count them.
              AnimatedOpacity(
                opacity: isComplete ? 1 : 0,
                duration: const Duration(milliseconds: 160),
                child: const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: Icon(Icons.check_circle, size: 19, color: AppTheme.signalPositive),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 14, color: AppTheme.signalClosed),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: AppTheme.sansMedium(fontSize: 12.5, color: AppTheme.signalClosed),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Maps this widget's markets onto the country rows used elsewhere in the app,
/// so a selection here can set currency and location defaults too.
Map<String, String> countryRowFor(PhoneFormat format) =>
    AppData.countries.firstWhere((c) => c['code'] == format.iso,
        orElse: () => AppData.countries.first);
