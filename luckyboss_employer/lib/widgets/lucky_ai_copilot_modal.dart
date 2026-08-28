import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/employer_provider.dart';
import '../services/employer_copilot_service.dart';

/// One turn in the conversation.
class _Turn {
  final bool isUser;
  final String text;

  /// Where the answer came from. Rendered distinctly, because "the model said
  /// so" and "your own data says so" are different levels of trust and a
  /// recruiter acting on a placement needs to know which they have.
  final ReplySource source;

  const _Turn({
    required this.isUser,
    required this.text,
    this.source = ReplySource.model,
  });

  bool get unavailable => source == ReplySource.unavailable;
  bool get fromLocalData => source == ReplySource.localData;
}

/// Lucky AI — the hiring assistant.
///
/// The employer counterpart to the candidate copilot, with one deliberate
/// difference: when the server cannot be reached this does not go quiet and it
/// does not invent. [EmployerCopilotService] answers from the jobs and
/// candidates actually on the device, and the reply is labelled as coming from
/// the company's own data rather than from a model.
///
/// That labelling is the point. A recruiter deciding whether to open a site
/// with twelve workers needs to know whether a number came from a model or from
/// counting rows, and a chat bubble that hides the difference is worse than no
/// assistant.
///
/// Model output arrives as light markdown. Rendering `**Skills:**` literally,
/// asterisks and all, is what made earlier builds look unfinished, so
/// [_RichReply] resolves bold and bullets into real text spans.
class LuckyAiCopilotModal extends StatefulWidget {
  const LuckyAiCopilotModal({super.key}) : scrollController = null;

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Tall by default: a chat that opens at a third of the screen makes the
      // user drag before they can read anything.
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) =>
            LuckyAiCopilotModal._withController(scrollController),
      ),
    );
  }

  const LuckyAiCopilotModal._withController(this.scrollController);

  final ScrollController? scrollController;

  @override
  State<LuckyAiCopilotModal> createState() => _LuckyAiCopilotModalState();
}

class _LuckyAiCopilotModalState extends State<LuckyAiCopilotModal> {
  final List<_Turn> _turns = [];
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  late final ScrollController _scroll =
      widget.scrollController ?? ScrollController();

  bool _busy = false;

  /// Openers, shown only while the conversation is empty. They disappear once
  /// there is real context — stale chips compete with what the user is actually doing.
  /// Openers a recruiter would actually type. Each one is answerable from
  /// local data, so they work with the server down.
  static const List<(IconData, String)> _starters = [
    (Icons.groups_outlined, 'How many forklift drivers do we have in Malaysia?'),
    (Icons.payments_outlined, 'What do my open vacancies pay?'),
    (Icons.badge_outlined, 'Which licences do candidates actually hold?'),
    (Icons.construction, 'How many masons are available in Chennai?'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _inputFocus.dispose();
    if (widget.scrollController == null) _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String raw) async {
    final query = raw.trim();
    if (query.isEmpty || _busy) return;

    _controller.clear();
    setState(() {
      _turns.add(_Turn(isUser: true, text: query));
      _busy = true;
    });
    _scrollToEnd();

    final provider = context.read<EmployerProvider>();
    final result = await EmployerCopilotService.ask(
      query,
      pool: provider.allCandidates,
      jobs: provider.jobs,
    );
    if (!mounted) return;

    setState(() {
      _turns.add(_Turn(
        isUser: false,
        text: result.text,
        source: result.source,
      ));
      _busy = false;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _header(context),
          Expanded(
            child: _turns.isEmpty
                ? _emptyState()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                    itemCount: _turns.length + (_busy ? 1 : 0),
                    itemBuilder: (context, i) => i >= _turns.length
                        ? const _ThinkingBubble()
                        : _bubble(_turns[i]),
                  ),
          ),
          _composer(context),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 10, 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.inkOf(context),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(Icons.auto_awesome, size: 17, color: AppTheme.onInkOf(context)),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lucky AI',
                          style: AppTheme.sansBold(
                              fontSize: 16, color: AppTheme.inkOf(context))),
                      Text('Career assistant',
                          style: AppTheme.sansRegular(
                              fontSize: 12, color: AppTheme.inkFaintOf(context))),
                    ],
                  ),
                ),
                if (_turns.isNotEmpty)
                  TextButton(
                    onPressed: _busy ? null : () => setState(_turns.clear),
                    child: Text('Clear',
                        style: AppTheme.sansMedium(
                            fontSize: 13, color: AppTheme.inkMutedOf(context))),
                  ),
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: AppTheme.inkMutedOf(context)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _emptyState() => ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
        children: [
          Text(
            'How can I help?',
            style: AppTheme.serifTitle(fontSize: 24, color: AppTheme.inkOf(context)),
          ),
          const SizedBox(height: 6),
          Text(
            'Ask about roles, salary ranges, or how to strengthen your profile across Singapore, Malaysia and India.',
            style: AppTheme.sansRegular(fontSize: 14, color: AppTheme.inkMutedOf(context)),
          ),
          const SizedBox(height: 24),
          ..._starters.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _starterChip(s.$1, s.$2),
              )),
        ],
      );

  Widget _starterChip(IconData icon, String text) => InkWell(
        onTap: () => _send(text),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.signalSource),
              const SizedBox(width: 12),
              Expanded(
                child: Text(text,
                    style: AppTheme.sansMedium(
                        fontSize: 14, color: AppTheme.inkOf(context))),
              ),
              Icon(Icons.north_east, size: 14, color: AppTheme.inkFaintOf(context)),
            ],
          ),
        ),
      );

  Widget _bubble(_Turn turn) {
    if (turn.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14, left: 44),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          decoration: BoxDecoration(
            color: AppTheme.inkOf(context),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(turn.text,
              style: AppTheme.sansMedium(fontSize: 14.5, color: AppTheme.onInkOf(context))),
        ),
      );
    }

    // The unavailable case gets its own treatment — an attention wash and an
    // icon — because it is not an answer and must not look like one.
    if (turn.unavailable) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14, right: 24),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.signalAttentionWash,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 17, color: AppTheme.signalAttention),
            const SizedBox(width: 11),
            Expanded(
              child: Text(turn.text,
                  style: AppTheme.sansMedium(
                      fontSize: 13.5, color: AppTheme.signalAttention)),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Where the answer came from, said before the answer is read.
          //
          // A recruiter about to staff a site off one of these numbers needs to
          // know whether a model produced it or whether the app counted rows.
          // Hiding that distinction is how an assistant becomes something you
          // cannot rely on for the one decision that matters.
          if (turn.fromLocalData) ...[
            Row(
              children: [
                const Icon(Icons.storage_outlined,
                    size: 13, color: AppTheme.signalProgress),
                const SizedBox(width: 6),
                Text('FROM YOUR LUCKY BOSS DATA — NOT AI',
                    style: AppTheme.sansBold(
                            fontSize: 9, color: AppTheme.signalProgress)
                        .copyWith(letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 7),
          ],
          _RichReply(text: turn.text),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: turn.text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied.',
                      style: AppTheme.sansMedium(fontSize: 13, color: AppTheme.onInkOf(context))),
                  backgroundColor: AppTheme.primaryFillOf(context),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_outlined, size: 13, color: AppTheme.inkFaintOf(context)),
                  const SizedBox(width: 5),
                  Text('Copy',
                      style: AppTheme.sansMedium(
                          fontSize: 12, color: AppTheme.inkFaintOf(context))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _composer(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(
          14,
          10,
          14,
          10 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _inputFocus,
                  enabled: !_busy,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  style: AppTheme.sansRegular(fontSize: 14.5, color: AppTheme.inkOf(context)),
                  decoration: InputDecoration(
                    hintText: 'Ask Lucky AI…',
                    hintStyle:
                        AppTheme.sansRegular(fontSize: 14.5, color: AppTheme.inkFaintOf(context)),
                    filled: true,
                    fillColor: AppTheme.paperOf(context),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) {
                  final ready = value.text.trim().isNotEmpty && !_busy;
                  return GestureDetector(
                    onTap: ready ? () => _send(_controller.text) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: ready ? AppTheme.inkOf(context) : Theme.of(context).dividerColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_upward,
                        size: 19,
                        color: ready ? Colors.white : AppTheme.inkFaintOf(context),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
}

/// Renders the assistant's light markdown.
///
/// Handles `**bold**` and leading bullet markers only. That is deliberately
/// narrow: the backend's system prompt asks for exactly those, and a fuller
/// markdown dependency would be weight carried for output that never arrives.
/// Anything unrecognised falls through as plain text rather than showing raw
/// syntax to the candidate.
class _RichReply extends StatelessWidget {
  final String text;

  const _RichReply({required this.text});

  static final RegExp _bold = RegExp(r'\*\*(.+?)\*\*');
  static final RegExp _bulletPrefix = RegExp(r'^\s*[•\-\*]\s+');

  @override
  Widget build(BuildContext context) {
    final lines = text.trim().split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      final isBullet = _bulletPrefix.hasMatch(trimmed);
      final content = isBullet ? trimmed.replaceFirst(_bulletPrefix, '') : trimmed;

      widgets.add(Padding(
        padding: EdgeInsets.only(bottom: 6, left: isBullet ? 2 : 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isBullet)
              Padding(
                padding: const EdgeInsets.only(top: 7, right: 9),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.inkFaintOf(context),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Expanded(child: _spans(context, content)),
          ],
        ),
      ));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _spans(BuildContext context, String source) {
    final base = AppTheme.sansRegular(fontSize: 14.5, color: AppTheme.inkOf(context))
        .copyWith(height: 1.45);
    final strong = AppTheme.sansBold(fontSize: 14.5, color: AppTheme.inkOf(context))
        .copyWith(height: 1.45);

    final spans = <TextSpan>[];
    var cursor = 0;

    for (final match in _bold.allMatches(source)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: source.substring(cursor, match.start), style: base));
      }
      spans.add(TextSpan(text: match.group(1), style: strong));
      cursor = match.end;
    }
    if (cursor < source.length) {
      spans.add(TextSpan(text: source.substring(cursor), style: base));
    }

    return SelectableText.rich(TextSpan(children: spans));
  }
}

/// The waiting state, as a bubble in the flow rather than a spinner over it.
class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                valueColor: AlwaysStoppedAnimation(AppTheme.inkFaintOf(context)),
              ),
            ),
            const SizedBox(width: 11),
            Text('Thinking…',
                style: AppTheme.sansRegular(fontSize: 13.5, color: AppTheme.inkFaintOf(context))),
          ],
        ),
      );
}
