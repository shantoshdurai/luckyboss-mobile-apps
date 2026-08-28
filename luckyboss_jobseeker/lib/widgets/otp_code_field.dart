import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';

/// One-time-code entry as separate digit cells.
///
/// The cells are a display over a single hidden field rather than one
/// TextField per box. Per-box fields are the common approach and they break in
/// the ways users actually hit them: backspace at an empty box does nothing,
/// pasting a code from the SMS fills only the first box, and autofill has no
/// single target to attach to. With one real field underneath, backspace,
/// paste, SMS autofill and text selection are the platform's own behaviour and
/// need no reimplementation.
class OtpCodeField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onChanged;

  /// Fired the moment the last digit lands, so a correct code submits without
  /// the user reaching for a button they can already see is redundant.
  final ValueChanged<String>? onCompleted;
  final bool enabled;
  final bool hasError;

  const OtpCodeField({
    super.key,
    required this.onChanged,
    this.length = 6,
    this.onCompleted,
    this.enabled = true,
    this.hasError = false,
  });

  @override
  State<OtpCodeField> createState() => OtpCodeFieldState();
}

class OtpCodeFieldState extends State<OtpCodeField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  String get code => _controller.text;

  void clear() {
    _controller.clear();
    setState(() {});
    widget.onChanged('');
  }

  void focus() => _focus.requestFocus();

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

  void _onChanged(String value) {
    setState(() {});
    widget.onChanged(value);
    if (value.length == widget.length) {
      // Dismiss the keyboard so the result is not hidden behind it.
      _focus.unfocus();
      widget.onCompleted?.call(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The real input, held off-screen rather than made invisible: an
        // Opacity(0) field still takes hit-tests and would swallow taps meant
        // for the cells.
        Positioned(
          left: -400,
          child: SizedBox(
            width: 200,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              enabled: widget.enabled,
              autofocus: true,
              keyboardType: TextInputType.number,
              // Lets iOS and Android drop the code straight in from the SMS.
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              onChanged: _onChanged,
            ),
          ),
        ),
        GestureDetector(
          onTap: widget.enabled ? focus : null,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (i) => _cell(context, i)),
          ),
        ),
      ],
    );
  }

  Widget _cell(BuildContext context, int index) {
    final filled = index < code.length;
    final isNext = index == code.length && _focus.hasFocus;

    final Color border;
    if (widget.hasError) {
      border = AppTheme.signalClosed;
    } else if (isNext) {
      border = AppTheme.inkOf(context);
    } else if (filled) {
      border = AppTheme.inkFaintOf(context);
    } else {
      border = Theme.of(context).dividerColor;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: isNext || widget.hasError ? 1.8 : 1),
          ),
          alignment: Alignment.center,
          child: filled
              ? Text(
                  code[index],
                  style: AppTheme.sansBold(
                    fontSize: 24,
                    color: widget.hasError ? AppTheme.signalClosed : AppTheme.inkOf(context),
                  ),
                )
              // The caret cell shows a rule rather than an empty box, so the
              // user can see where the next digit is going to land.
              : isNext
                  ? Container(width: 15, height: 2, color: AppTheme.inkFaintOf(context))
                  : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Countdown that gates the "Resend code" action.
///
/// Resending is genuinely rate-limited by every SMS provider, and each send
/// costs real money, so the timer is not decorative — it stops a user burning
/// the account's quota by tapping repeatedly when the network is slow.
class ResendCountdown extends StatefulWidget {
  final int seconds;
  final VoidCallback onResend;
  final bool enabled;

  const ResendCountdown({
    super.key,
    required this.onResend,
    this.seconds = 30,
    this.enabled = true,
  });

  @override
  State<ResendCountdown> createState() => ResendCountdownState();
}

class ResendCountdownState extends State<ResendCountdown> {
  late int _remaining = widget.seconds;
  bool _ticking = true;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void restart() {
    if (!mounted) return;
    setState(() {
      _remaining = widget.seconds;
      _ticking = true;
    });
    _tick();
  }

  Future<void> _tick() async {
    while (_ticking && _remaining > 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _remaining--);
    }
    if (mounted) setState(() => _ticking = false);
  }

  @override
  void dispose() {
    _ticking = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _remaining <= 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't get the code? ",
          style: AppTheme.sansRegular(fontSize: 13.5, color: AppTheme.inkMutedOf(context)),
        ),
        if (ready)
          GestureDetector(
            onTap: widget.enabled
                ? () {
                    widget.onResend();
                    restart();
                  }
                : null,
            child: Text(
              'Resend',
              style: AppTheme.sansBold(fontSize: 13.5, color: AppTheme.signalSource),
            ),
          )
        else
          Text(
            'Resend in ${_remaining}s',
            style: AppTheme.sansMedium(fontSize: 13.5, color: AppTheme.inkFaintOf(context)),
          ),
      ],
    );
  }
}
