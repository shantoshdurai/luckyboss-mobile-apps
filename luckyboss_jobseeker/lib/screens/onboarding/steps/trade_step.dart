import 'package:flutter/material.dart';

import '../../../core/constants/app_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/onboarding_model.dart';
import '../../../widgets/onboarding_components.dart';
import '../../../models/uploaded_document.dart';
import '../../../services/document_service.dart';
import '../../../widgets/searchable_chip_picker.dart';

/// The field-work counterpart to [KeySkillsStep]: trade, years, work done, cards.
///
/// The screen it replaces asked every candidate to type their "key skills" into
/// a chip field. That works for a developer who thinks in named technologies. It
/// does not work for a mason, who does not have a list of skills in mind and has
/// no idea what the app is expecting — so the field stays empty, the profile
/// scores nothing, and no employer ever sees them.
///
/// Here nothing has to be typed at all. The trade is a tap, the years are a tap,
/// the work and the cards are taps from the vocabulary of that specific trade.
/// A candidate who does not read English well can still complete this screen,
/// and the profile that comes out the other side is richer than the one the
/// chip field was producing.
class TradeStep extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onChanged;

  const TradeStep({super.key, required this.data, required this.onChanged});

  @override
  State<TradeStep> createState() => _TradeStepState();
}

class _TradeStepState extends State<TradeStep> {
  // Anchors for the questions that appear once the trade is picked, so the app
  // scrolls to them rather than leaving the candidate to find them.
  final GlobalKey _yearsKey = GlobalKey();
  final GlobalKey _abilitiesKey = GlobalKey();

  OnboardingData get data => widget.data;
  void onChanged() => widget.onChanged();

  /// Years offered as buckets rather than a number pad. Nobody knows whether
  /// they have done seven years or eight, and a keyboard on this screen is a
  /// wall in front of a candidate who is otherwise only tapping.
  static const List<(String, int)> years = [
    ('No experience', 0),
    ('Under 1 year', 1),
    ('1–3 years', 2),
    ('3–5 years', 4),
    ('5–10 years', 7),
    ('Over 10 years', 12),
  ];

  @override
  Widget build(BuildContext context) {
    final category = data.workCategory;
    if (category == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(category.icon, size: 24, color: AppTheme.signalSource),
            const SizedBox(width: 10),
            Expanded(
              child: Text(category.name,
                  style: AppTheme.sansSemiBold(
                      fontSize: 14, color: AppTheme.signalSource)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text('What is your work?',
            style: AppTheme.serifTitle(fontSize: 26, color: AppTheme.inkOf(context))),
        const SizedBox(height: 6),
        Text(
          'Tap what you do. Employers search by this.',
          style: AppTheme.sansRegular(fontSize: 14, color: AppTheme.inkMutedOf(context)),
        ),
        const SizedBox(height: 24),

        // Searchable, and it takes a typed trade — the separate "Not in the
        // list? Type it" box this replaces sat below a wall of chips, so it was
        // only found by the people who had already given up scrolling.
        RevealedField(
          label: 'Your job *',
          child: SearchableChipPicker(
            options: category.roleNames,
            selected: {if (data.roleTitle.isNotEmpty) data.roleTitle},
            single: true,
            searchHint: 'Search trades, or type your own',
            onToggle: (r) {
              data.roleTitle = data.roleTitle == r ? '' : r;
              onChanged();
              if (data.roleTitle.isNotEmpty) revealNextQuestion(_yearsKey);
            },
          ),
        ),

        RevealedField(
          key: _yearsKey,
          label: 'How long have you done this work?',
          visible: data.roleTitle.isNotEmpty,
          child: _chips(
            years.map((y) => y.$1).toList(),
            isSelected: (label) =>
                data.yearsInTrade == years.firstWhere((y) => y.$1 == label).$2,
            onTap: (label) {
              data.yearsInTrade = years.firstWhere((y) => y.$1 == label).$2;
              onChanged();
              revealNextQuestion(_abilitiesKey);
            },
            single: true,
          ),
        ),

        RevealedField(
          key: _abilitiesKey,
          label: 'What can you do? Pick everything that applies',
          visible: data.roleTitle.isNotEmpty,
          // Once a role is picked these narrow to that role's own work, so a
          // plumber is offered pipe fitting and leak repairs rather than every
          // task anyone on a construction site performs.
          child: SearchableChipPicker(
            options:
                AppData.abilitiesFor(category: category.name, role: data.roleTitle),
            selected: data.skills.toSet(),
            searchHint: 'Search the work you do, or type it',
            onToggle: (a) {
              if (!data.skills.remove(a)) data.skills.add(a);
              onChanged();
            },
          ),
        ),

        // Upload first, tick second — and neither is pushed.
        //
        // Shantosh: *"no one has maximum certificates for labour work like
        // carpenter or plumber, just proof of work — uploadable certificate if
        // they have any."* He is right, and the list-first version was quietly
        // discouraging: a screen of licence chips reads as a checklist you are
        // failing. Most trades genuinely hold nothing, so the question leads
        // with "if you have any", offers an upload, and keeps the tick list
        // underneath for the trades that do have cards.
        RevealedField(
          label: 'Any certificate or proof of work?',
          visible: data.roleTitle.isNotEmpty,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Most ${data.roleTitle.toLowerCase()}s have none, and that is '
                'fine — you can finish without this. If you hold a card, a '
                'training certificate, or a letter from an employer, a photo of '
                'it puts you ahead of everyone who has not shown one.',
                style: AppTheme.sansRegular(
                    fontSize: 12.5, color: AppTheme.inkFaintOf(context)),
              ),
              const SizedBox(height: 12),
              _UploadProof(
                role: data.roleTitle,
                uploaded: data.uploadedProof,
                onUploaded: (document) {
                  data.uploadedProof.add(document);
                  if (!data.certificates.contains(document.label)) {
                    data.certificates.add(document.label);
                  }
                  onChanged();
                },
              ),
              if (_certificates(category).isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Or tick anything you hold — you can add the photo later.',
                  style: AppTheme.sansRegular(
                      fontSize: 12.5, color: AppTheme.inkFaintOf(context)),
                ),
                const SizedBox(height: 10),
                SearchableChipPicker(
                  options: _certificates(category),
                  selected: data.certificates,
                  searchHint: 'Search licences, or type one',
                  onToggle: (c) {
                    if (!data.certificates.remove(c)) data.certificates.add(c);
                    onChanged();
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Licences for the chosen role only.
  ///
  /// Deliberately not widened to the category. Showing a plumber a crane
  /// operator licence is not a harmless extra option — it is the app saying it
  /// does not know what his job is.
  List<String> _certificates(WorkCategory category) =>
      AppData.certificatesFor(category: category.name, role: data.roleTitle);

  Widget _chips(
    List<String> options, {
    required bool Function(String) isSelected,
    required ValueChanged<String> onTap,
    bool single = false,
  }) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in options)
            LbChoiceChip(
              label: option,
              selected: isSelected(option),
              showAffordance: !single,
              onTap: () => onTap(option),
            ),
        ],
      );
}

/// Uploading proof of work during onboarding.
///
/// Stored on the device immediately, like every other upload in this app, and
/// marked awaiting verification. When the database is connected these move
/// server-side unchanged — the document already carries its label, kind and
/// status.
class _UploadProof extends StatefulWidget {
  final String role;
  final List<UploadedDocument> uploaded;
  final ValueChanged<UploadedDocument> onUploaded;

  const _UploadProof({
    required this.role,
    required this.uploaded,
    required this.onUploaded,
  });

  @override
  State<_UploadProof> createState() => _UploadProofState();
}

class _UploadProofState extends State<_UploadProof> {
  bool _busy = false;

  Future<void> _add() async {
    final fromCamera = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add proof',
                style: AppTheme.sansBold(
                    fontSize: 16, color: AppTheme.inkOf(context))),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('Take a photo of it',
                  style: AppTheme.sansMedium(
                      fontSize: 15, color: AppTheme.inkOf(context))),
              onTap: () => Navigator.pop(ctx, true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_open_outlined),
              title: Text('Choose a file',
                  style: AppTheme.sansMedium(
                      fontSize: 15, color: AppTheme.inkOf(context))),
              onTap: () => Navigator.pop(ctx, false),
            ),
          ],
        ),
      ),
    );
    if (fromCamera == null || !mounted) return;

    setState(() => _busy = true);
    final picked = fromCamera
        ? await DocumentService.captureWithCamera()
        : await DocumentService.pickDocument();
    if (!mounted) return;
    setState(() => _busy = false);

    if (!picked.isOk) {
      if (picked.failure == PickFailure.cancelled) return;
      if (picked.message != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(picked.message!,
              style: AppTheme.sansMedium(
                  fontSize: 13, color: AppTheme.onInkOf(context))),
          backgroundColor: AppTheme.signalClosed,
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    final document = await DocumentService.save(
      file: picked.file!,
      kind: DocumentKind.certificate,
      // Named after the trade when the candidate has not said what it is. The
      // agency reads the document during verification anyway.
      label: widget.role.isEmpty ? 'Proof of work' : '${widget.role} proof',
    );
    if (!mounted) return;
    widget.onUploaded(document);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final document in widget.uploaded)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppTheme.signalPositiveWash,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.signalPositive.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 17, color: AppTheme.signalPositive),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(document.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.sansSemiBold(
                              fontSize: 12.5,
                              color: AppTheme.inkOf(context))),
                      Text(document.status.label,
                          style: AppTheme.sansRegular(
                              fontSize: 11,
                              color: AppTheme.inkMutedOf(context))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: _busy ? null : _add,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: _busy
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.upload_file_outlined,
                  size: 18, color: AppTheme.signalSource),
          label: Text(
            widget.uploaded.isEmpty ? 'Add a certificate' : 'Add another',
            style: AppTheme.sansBold(
                fontSize: 13.5, color: AppTheme.signalSource),
          ),
        ),
      ],
    );
  }
}
