import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_data.dart';
import '../core/theme/app_theme.dart';
import '../models/uploaded_document.dart';
import '../providers/job_seeker_provider.dart';
import '../services/document_service.dart';
import 'document_preview.dart';

/// Licences and cards, with the file that proves them.
///
/// The sheet this replaces was a row of chips and a Save button. Shantosh's
/// objection was exact and correct: *"we can click on anything and we can click
/// save, it doesn't mean that they're uploading"*. Ticking "Forklift Licence"
/// recorded a claim, looked to the candidate like a submission, and gave the
/// agency nothing to verify.
///
/// So every licence here has two states and they are shown differently:
///
/// * **Claimed** — the candidate says they hold it. Useful for matching, worth
///   nothing as evidence.
/// * **Uploaded** — the card itself is on file, marked *awaiting verification*
///   until the agency checks it. Never marked verified by this app; a handset
///   asserting that its own upload has been approved is not a signal anyone
///   can act on.
///
/// The list is drawn from the candidate's own **role**, not their category.
/// Every trade used to be shown the same five cards.
class LicencesSheet extends StatefulWidget {
  const LicencesSheet({super.key});

  static Future<void> open(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const LicencesSheet(),
      );

  @override
  State<LicencesSheet> createState() => _LicencesSheetState();
}

class _LicencesSheetState extends State<LicencesSheet> {
  String? _busyLabel;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobSeekerProvider>();
    final profile = provider.profile;
    final role =
        profile.roleTitle.isNotEmpty ? profile.roleTitle : profile.currentTitle;

    final suggested = AppData.certificatesFor(
      category: profile.preferredCategory,
      role: role,
    );

    // Anything the candidate has added that is not in the suggested list — a
    // licence from another trade, or one they typed themselves. It must not
    // silently disappear from the sheet just because it is off-list.
    final extra = [
      for (final c in profile.certificates)
        if (!suggested.contains(c)) c,
    ];
    final all = [...suggested, ...extra];

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [
                  Text('Licences and cards',
                      style: AppTheme.serifTitle(
                          fontSize: 22, color: AppTheme.inkOf(context))),
                  const SizedBox(height: 6),
                  Text(
                    role.isEmpty
                        ? 'Tick what you hold, then upload a photo of the card. '
                            'Lucky Boss checks it before an employer sees it.'
                        : 'What a $role usually needs. Tick what you hold, then '
                            'upload a photo of the card — Lucky Boss checks it '
                            'before an employer sees it.',
                    style: AppTheme.sansRegular(
                        fontSize: 13.5, color: AppTheme.inkMutedOf(context)),
                  ),
                  const SizedBox(height: 20),

                  if (all.isEmpty)
                    _EmptyState(role: role)
                  else
                    for (final licence in all)
                      _LicenceRow(
                        licence: licence,
                        claimed: profile.certificates.contains(licence),
                        proof: provider.documentForCertificate(licence),
                        busy: _busyLabel == licence,
                        onToggle: () => _toggle(provider, licence),
                        onUpload: () => _upload(provider, licence),
                        onRemoveProof: (id) => provider.removeDocument(id),
                      ),

                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _addOther,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('Add another licence',
                        style: AppTheme.sansSemiBold(
                            fontSize: 14, color: AppTheme.inkOf(context))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline,
                          size: 15, color: AppTheme.inkFaintOf(context)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your documents stay on this phone until Lucky Boss '
                          'submits you for a job.',
                          style: AppTheme.sansRegular(
                              fontSize: 12.5,
                              color: AppTheme.inkFaintOf(context)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    // Not "Save". Everything on this sheet is written the moment
                    // it is tapped, and a Save button would imply the taps had
                    // not counted until now — which is exactly the confusion the
                    // old version created.
                    child: Text('Done',
                        style: AppTheme.sansBold(
                            fontSize: 15, color: AppTheme.onInkOf(context))),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(JobSeekerProvider provider, String licence) async {
    if (provider.profile.certificates.contains(licence)) {
      final proof = provider.documentForCertificate(licence);
      if (proof != null && !await _confirmRemoveProof(licence)) return;
      await provider.removeCertificate(licence);
    } else {
      await provider.setProfileField(
        'certificates',
        [...provider.profile.certificates, licence],
      );
    }
  }

  Future<bool> _confirmRemoveProof(String licence) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove $licence?',
            style:
                AppTheme.sansBold(fontSize: 16, color: AppTheme.inkOf(context))),
        content: Text(
          'The card you uploaded for it will be deleted too.',
          style: AppTheme.sansRegular(
              fontSize: 14, color: AppTheme.inkMutedOf(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep it',
                style: AppTheme.sansMedium(
                    fontSize: 14, color: AppTheme.inkMutedOf(context))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove',
                style: AppTheme.sansBold(
                    fontSize: 14, color: AppTheme.signalClosed)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _upload(JobSeekerProvider provider, String licence) async {
    final source = await _askSource(licence);
    if (source == null) return;

    setState(() => _busyLabel = licence);
    final picked = source == _Source.camera
        ? await DocumentService.captureWithCamera()
        : await DocumentService.pickDocument();
    if (!mounted) return;
    setState(() => _busyLabel = null);

    if (!picked.isOk) {
      if (picked.failure == PickFailure.cancelled) return;
      if (picked.failure == PickFailure.permissionPermanentlyDenied) {
        _offerSettings(picked.message!);
        return;
      }
      if (picked.message != null) _notify(picked.message!, AppTheme.signalClosed);
      return;
    }

    final document = await DocumentService.save(
      file: picked.file!,
      kind: DocumentKind.certificate,
      label: licence,
    );
    if (!mounted) return;
    await provider.addDocument(document);
    if (!mounted) return;

    _notify('$licence uploaded. Lucky Boss will verify it.',
        AppTheme.signalPositive);
  }

  Future<_Source?> _askSource(String licence) => showModalBottomSheet<_Source>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(licence,
                  style: AppTheme.sansBold(
                      fontSize: 16, color: AppTheme.inkOf(context))),
              const SizedBox(height: 4),
              Text('A clear photo of the card is enough. PDF also works.',
                  style: AppTheme.sansRegular(
                      fontSize: 13, color: AppTheme.inkMutedOf(context))),
              const SizedBox(height: 16),
              _sheetAction(ctx, Icons.photo_camera_outlined,
                  'Take a photo of the card', _Source.camera),
              _sheetAction(ctx, Icons.folder_open_outlined,
                  'Choose a file', _Source.file),
            ],
          ),
        ),
      );

  Widget _sheetAction(
          BuildContext ctx, IconData icon, String label, _Source source) =>
      InkWell(
        onTap: () => Navigator.pop(ctx, source),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 21, color: AppTheme.inkOf(context)),
              const SizedBox(width: 14),
              Text(label,
                  style: AppTheme.sansMedium(
                      fontSize: 15, color: AppTheme.inkOf(context))),
            ],
          ),
        ),
      );

  Future<void> _addOther() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add a licence',
            style:
                AppTheme.sansBold(fontSize: 16, color: AppTheme.inkOf(context))),
        content: TextField(
                    textInputAction: TextInputAction.done,
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Boom Lift Licence',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTheme.sansMedium(
                    fontSize: 14, color: AppTheme.inkMutedOf(context))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text('Add',
                style: AppTheme.sansBold(
                    fontSize: 14, color: AppTheme.signalSource)),
          ),
        ],
      ),
    );

    if (!mounted || name == null || name.isEmpty) return;
    final provider = context.read<JobSeekerProvider>();
    if (provider.profile.certificates.contains(name)) return;
    await provider.setProfileField(
      'certificates',
      [...provider.profile.certificates, name],
    );
  }

  void _offerSettings(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Permission needed',
            style:
                AppTheme.sansBold(fontSize: 16, color: AppTheme.inkOf(context))),
        content: Text(message,
            style: AppTheme.sansRegular(
                fontSize: 14, color: AppTheme.inkMutedOf(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Not now',
                style: AppTheme.sansMedium(
                    fontSize: 14, color: AppTheme.inkMutedOf(context))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              DocumentService.openSettings();
            },
            child: Text('Open Settings',
                style: AppTheme.sansBold(
                    fontSize: 14, color: AppTheme.signalSource)),
          ),
        ],
      ),
    );
  }

  void _notify(String message, Color tone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: AppTheme.sansMedium(
                fontSize: 13, color: AppTheme.onInkOf(context))),
        backgroundColor: tone,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

enum _Source { camera, file }

class _EmptyState extends StatelessWidget {
  final String role;

  const _EmptyState({required this.role});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgPaper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Text(
          role.isEmpty
              ? 'Pick your trade on your profile first and we will show the '
                  'licences that matter for it.'
              : 'A $role does not usually need a licence. If you hold one '
                  'anyway, add it below — it still counts in your favour.',
          style: AppTheme.sansRegular(
              fontSize: 13, color: AppTheme.inkMutedOf(context)),
        ),
      );
}

/// One licence: the claim, and the file behind it.
class _LicenceRow extends StatelessWidget {
  final String licence;
  final bool claimed;
  final UploadedDocument? proof;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onUpload;
  final ValueChanged<String> onRemoveProof;

  const _LicenceRow({
    required this.licence,
    required this.claimed,
    required this.proof,
    required this.busy,
    required this.onToggle,
    required this.onUpload,
    required this.onRemoveProof,
  });

  @override
  Widget build(BuildContext context) {
    final document = proof;
    final hasProof = document != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: hasProof
            ? AppTheme.emerald.withValues(alpha: 0.06)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasProof
              ? AppTheme.emerald.withValues(alpha: 0.35)
              : (claimed
                  ? AppTheme.signalSource.withValues(alpha: 0.4)
                  : Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    claimed
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 22,
                    color: claimed
                        ? AppTheme.signalSource
                        : AppTheme.inkFaintOf(context),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(licence,
                    style: AppTheme.sansSemiBold(
                        fontSize: 14, color: AppTheme.inkOf(context))),
              ),
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (!hasProof)
                TextButton(
                  onPressed: onUpload,
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8)),
                  child: Text('Upload',
                      style: AppTheme.sansBold(
                          fontSize: 13, color: AppTheme.royalBlue)),
                ),
            ],
          ),
          if (hasProof) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => DocumentPreview.open(context, document),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      document.isPdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.image_outlined,
                      size: 22,
                      color: AppTheme.emeraldDark,
                    ),
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
                          Text(
                            '${document.status.label} · ${document.sizeDisplay}',
                            style: AppTheme.sansRegular(
                                fontSize: 11,
                                color: document.status ==
                                        DocumentStatus.rejected
                                    ? AppTheme.signalClosed
                                    : AppTheme.inkFaintOf(context)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => onRemoveProof(document.id),
                      icon: Icon(Icons.delete_outline,
                          size: 19, color: AppTheme.inkFaintOf(context)),
                      tooltip: 'Remove this file',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
