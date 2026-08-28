import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/feed_prompt.dart';
import '../providers/job_seeker_provider.dart';

/// A question card sitting between job listings.
///
/// Visually distinct from a job card on purpose — tinted ground, no employer
/// mark, a label saying what it is for. A prompt that looked like a listing
/// would be a dark pattern: people tap Apply on autopilot when scanning a feed.
///
/// Every card is dismissible. A question the candidate does not want to answer
/// has to go away permanently, or the feed becomes a nag.
class FeedPromptCard extends StatefulWidget {
  final FeedPrompt prompt;

  const FeedPromptCard({super.key, required this.prompt});

  @override
  State<FeedPromptCard> createState() => _FeedPromptCardState();
}

class _FeedPromptCardState extends State<FeedPromptCard> {
  final TextEditingController _number = TextEditingController();
  final FocusNode _numberFocus = FocusNode();
  final Set<String> _multi = {};

  @override
  void dispose() {
    _number.dispose();
    _numberFocus.dispose();
    super.dispose();
  }

  void _answer(Object value) {
    // Both of these are resolved BEFORE the answer is recorded. Recording it
    // removes this prompt from pendingPrompts, which rebuilds the feed and
    // deactivates this widget — after which looking up an ancestor through its
    // context throws "Looking up a deactivated widget's ancestor is unsafe".
    final provider = context.read<JobSeekerProvider>();
    final messenger = ScaffoldMessenger.of(context);

    provider.answerPrompt(widget.prompt.id, value);
    messenger.showSnackBar(
      SnackBar(
        content: Text('Saved. Your matches will update.',
            style: AppTheme.sansMedium(fontSize: 13, color: AppTheme.onInkOf(context))),
        backgroundColor: AppTheme.signalPositive,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prompt;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.fromLTRB(16, 13, 10, 16),
      decoration: BoxDecoration(
        color: AppTheme.signalSourceWash,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.signalSource.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, size: 15, color: AppTheme.signalSource),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'IMPROVE YOUR MATCHES  ·  +${p.completionGain}%',
                  style: AppTheme.sansBold(
                          fontSize: 10, color: AppTheme.signalSource)
                      .copyWith(letterSpacing: 0.6),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(Icons.close, size: 16, color: AppTheme.inkFaintOf(context)),
                tooltip: 'Not now',
                onPressed: () =>
                    context.read<JobSeekerProvider>().dismissPrompt(p.id),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(p.question,
                style: AppTheme.sansBold(fontSize: 16, color: AppTheme.inkOf(context))),
          ),
          if (p.detail != null) ...[
            const SizedBox(height: 4),
            Text(p.detail!,
                style: AppTheme.sansRegular(
                    fontSize: 12.5, color: AppTheme.inkMutedOf(context))),
          ],
          const SizedBox(height: 14),
          _input(p),
        ],
      ),
    );
  }

  Widget _input(FeedPrompt p) {
    switch (p.kind) {
      case PromptKind.yesNo:
        return Row(
          children: [
            Expanded(child: _pill('Yes', () => _answer(true))),
            const SizedBox(width: 9),
            Expanded(child: _pill('No', () => _answer(false))),
          ],
        );

      case PromptKind.choice:
        return Wrap(
          spacing: 8,
          runSpacing: 9,
          children: p.options.map((o) => _pill(o, () => _answer(o))).toList(),
        );

      case PromptKind.multiChoice:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 9,
              children: p.options
                  .map((o) => _pill(
                        o,
                        () => setState(() =>
                            _multi.contains(o) ? _multi.remove(o) : _multi.add(o)),
                        selected: _multi.contains(o),
                      ))
                  .toList(),
            ),
            if (_multi.isNotEmpty) ...[
              const SizedBox(height: 12),
              _save(() => _answer(_multi.toList())),
            ],
          ],
        );

      case PromptKind.number:
        // Listens to the controller instead of calling setState on every
        // keystroke. The old version rebuilt this whole card as the candidate
        // typed, inside a feed that rebuilds on every provider notification —
        // between the two, the field kept losing focus and the answer could not
        // be entered at all.
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: _number,
          builder: (context, value, _) {
            final entered = value.text.trim();
            return Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _number,
                    focusNode: _numberFocus,
                    keyboardType: TextInputType.number,
                    // Submitting from the keyboard saves and closes it, rather
                    // than leaving the candidate to find a button behind it.
                    textInputAction: TextInputAction.done,
                    onSubmitted: (v) {
                      if (v.trim().isEmpty) return;
                      _numberFocus.unfocus();
                      _answer(v.trim());
                    },
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: AppTheme.sansSemiBold(
                        fontSize: 15, color: AppTheme.inkOf(context)),
                    decoration: InputDecoration(
                      hintText: 'Amount per month',
                      hintStyle: AppTheme.sansRegular(
                          fontSize: 14, color: AppTheme.inkFaintOf(context)),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                _save(entered.isEmpty
                    ? null
                    : () {
                        _numberFocus.unfocus();
                        _answer(entered);
                      }),
              ],
            );
          },
        );
    }
  }

  Widget _pill(String label, VoidCallback onTap, {bool selected = false}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.signalSource
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? AppTheme.signalSource
                  : AppTheme.signalSource.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: AppTheme.sansMedium(
              fontSize: 13.5,
              color: selected ? Colors.white : AppTheme.inkOf(context),
            ),
          ),
        ),
      );

  Widget _save(VoidCallback? onTap) => SizedBox(
        height: 44,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryFillOf(context),
            foregroundColor: AppTheme.onPrimaryFillOf(context),
            disabledBackgroundColor: Theme.of(context).dividerColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Save',
              style: AppTheme.sansBold(
                  fontSize: 14,
                  color: onTap == null ? AppTheme.inkFaintOf(context) : Colors.white)),
        ),
      );
}

/// The closing feedback card at the end of the feed.
///
/// Asks one question, records one answer, and does not ask again. Its value is
/// telling us whether the recommendations were any good — which is the only
/// signal we have while match scoring is still keyword-based.
class FeedFeedbackCard extends StatelessWidget {
  const FeedFeedbackCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobSeekerProvider>();
    final answered = provider.feedFeedback;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: answered == null
          ? Row(
              children: [
                Expanded(
                  child: Text('Were these recommendations useful?',
                      style: AppTheme.sansMedium(
                          fontSize: 14, color: AppTheme.inkOf(context))),
                ),
                IconButton(
                  icon: const Icon(Icons.thumb_up_outlined, size: 20),
                  color: AppTheme.inkMutedOf(context),
                  tooltip: 'Yes',
                  onPressed: () => provider.setFeedFeedback(true),
                ),
                IconButton(
                  icon: const Icon(Icons.thumb_down_outlined, size: 20),
                  color: AppTheme.inkMutedOf(context),
                  tooltip: 'No',
                  onPressed: () => provider.setFeedFeedback(false),
                ),
              ],
            )
          : Row(
              children: [
                Icon(
                  answered ? Icons.check_circle_outline : Icons.build_outlined,
                  size: 18,
                  color: answered
                      ? AppTheme.signalPositive
                      : AppTheme.signalAttention,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    answered
                        ? 'Thanks — we will keep matching this way.'
                        : 'Noted. Add more skills and preferences and these will sharpen.',
                    style: AppTheme.sansMedium(
                      fontSize: 13,
                      color: answered
                          ? AppTheme.signalPositive
                          : AppTheme.signalAttention,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
