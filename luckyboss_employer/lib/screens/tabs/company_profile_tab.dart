import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/employer_job.dart';
import '../../models/uploaded_document.dart';
import '../../providers/employer_provider.dart';
import '../../services/document_service.dart';
import '../auth/company_registration_screen.dart';
import '../auth/verification_pending_screen.dart';
import '../edit_company_screen.dart';
import '../settings_screen.dart';

/// The company as candidates and Lucky Boss see it.
///
/// Rebuilt on the shared design system — it was the last screen still on the
/// pre-rebuild layout and looked it. More importantly it had nowhere to show
/// the two things that now decide what this account can do: verification state,
/// and the documents behind it.
///
/// Workplace photos live here rather than in settings because they are the one
/// company upload a candidate ever sees. Shantosh: *"they need to upload their
/// company pictures in the profile."*
class CompanyProfileTab extends StatelessWidget {
  final VoidCallback? onMenu;

  const CompanyProfileTab({super.key, this.onMenu});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployerProvider>();
    final company = provider.company;

    return Scaffold(
      backgroundColor: AppTheme.paperOf(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          children: [
            Row(
              children: [
                if (onMenu != null)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40),
                    onPressed: onMenu,
                    tooltip: 'Menu',
                    icon: Icon(Icons.menu, color: AppTheme.inkOf(context)),
                  ),
                Expanded(
                  child: Text('Company',
                      style: AppTheme.serifTitle(
                          fontSize: 24, color: AppTheme.inkOf(context))),
                ),
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EditCompanyScreen()),
                  ),
                  tooltip: 'Edit company',
                  icon: Icon(Icons.edit_outlined, color: AppTheme.inkOf(context)),
                ),
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  tooltip: 'Settings',
                  icon: Icon(Icons.settings_outlined,
                      color: AppTheme.inkOf(context)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            _IdentityCard(company: company),
            const SizedBox(height: 14),

            if (company.status != CompanyStatus.verified) ...[
              _VerificationPrompt(company: company),
              const SizedBox(height: 14),
            ],

            _section(context, 'Details'),
            _card(
              context,
              child: Column(
                children: [
                  _row(context, 'Business type',
                      company.type.isEmpty ? '—' : company.type),
                  const Divider(height: 20),
                  _row(
                      context,
                      'Registration no.',
                      company.registrationNumber.isEmpty
                          ? '—'
                          : company.registrationNumber),
                  const Divider(height: 20),
                  _row(
                      context,
                      'Based in',
                      company.city.isEmpty
                          ? '—'
                          : '${company.city}, ${company.countryCode}'),
                  const Divider(height: 20),
                  _row(context, 'Contact',
                      company.contactName.isEmpty ? '—' : company.contactName),
                  const Divider(height: 20),
                  _row(context, 'Phone',
                      company.phone.isEmpty ? '—' : company.phone),
                ],
              ),
            ),

            if (company.about.isNotEmpty) ...[
              const SizedBox(height: 14),
              _section(context, 'About'),
              _card(
                context,
                child: Text(company.about,
                    style: AppTheme.sansRegular(
                        fontSize: 14, color: AppTheme.inkOf(context))),
              ),
            ],

            const SizedBox(height: 14),
            _section(context, 'Workplace photos'),
            _PhotoStrip(
              photos: provider.documents
                  .where((d) => d.kind == DocumentKind.companyPhoto)
                  .toList(),
            ),

            const SizedBox(height: 14),
            _section(context, 'Verification documents'),
            _DocumentList(
              documents: provider.documents
                  .where((d) => d.kind != DocumentKind.companyPhoto)
                  .toList(),
            ),

            const SizedBox(height: 14),
            _section(context, 'Hiring'),
            _card(
              context,
              child: Column(
                children: [
                  _row(context, 'Jobs posted', '${provider.jobs.length}'),
                  const Divider(height: 20),
                  _row(context, 'Live now', '${provider.activeJobsCount}'),
                  const Divider(height: 20),
                  _row(context, 'Hired through Luckyboss',
                      '${provider.hiredCount}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 9, left: 2),
        child: Text(title.toUpperCase(),
            style: AppTheme.sansBold(
                    fontSize: 10, color: AppTheme.inkFaintOf(context))
                .copyWith(letterSpacing: 0.6)),
      );

  Widget _card(BuildContext context, {required Widget child}) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: child,
      );

  Widget _row(BuildContext context, String label, String value) => Row(
        children: [
          Expanded(
            child: Text(label,
                style: AppTheme.sansMedium(
                    fontSize: 14, color: AppTheme.inkMutedOf(context))),
          ),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.sansSemiBold(
                    fontSize: 13.5, color: AppTheme.inkOf(context))),
          ),
        ],
      );
}

class _IdentityCard extends StatelessWidget {
  final CompanyProfile company;

  const _IdentityCard({required this.company});

  @override
  Widget build(BuildContext context) {
    final initials = company.name.trim().isEmpty
        ? 'LB'
        : company.name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join();
    final logoBytes = DocumentService.bytesFromDataUri(company.logoUrl);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          // The logo when there is one, initials until then. Tapping either
          // opens the editor, so the empty square is an invitation rather than
          // a dead end.
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditCompanyScreen()),
            ),
            child: Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: logoBytes == null
                    ? AppTheme.inkOf(context)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                image: logoBytes == null
                    ? null
                    : DecorationImage(
                        image: MemoryImage(logoBytes), fit: BoxFit.cover),
              ),
              child: logoBytes != null
                  ? null
                  : Text(initials,
                      style: AppTheme.sansBold(
                          fontSize: 19, color: AppTheme.onInkOf(context))),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        company.name.isEmpty ? 'Your company' : company.name,
                        maxLines: 2,
                        style: AppTheme.sansBold(
                            fontSize: 17, color: AppTheme.inkOf(context)),
                      ),
                    ),
                    if (company.isVerified) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.verified,
                          size: 16, color: AppTheme.signalPositive),
                    ],
                  ],
                ),
                if (company.type.isNotEmpty)
                  Text(company.type,
                      style: AppTheme.sansRegular(
                          fontSize: 13,
                          color: AppTheme.inkMutedOf(context))),
                if (company.email.isNotEmpty)
                  Text(company.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.sansRegular(
                          fontSize: 12.5,
                          color: AppTheme.inkFaintOf(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationPrompt extends StatelessWidget {
  final CompanyProfile company;

  const _VerificationPrompt({required this.company});

  @override
  Widget build(BuildContext context) {
    final notStarted = company.status == CompanyStatus.draft;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => notStarted
              ? const CompanyRegistrationScreen()
              : const VerificationPendingScreen(),
        ),
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppTheme.signalAttentionWash,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppTheme.signalAttention.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
                notStarted
                    ? Icons.assignment_outlined
                    : Icons.hourglass_top_rounded,
                size: 19,
                color: AppTheme.signalAttention),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notStarted
                        ? 'Register to publish jobs'
                        : company.status.label,
                    style: AppTheme.sansBold(
                        fontSize: 14, color: AppTheme.inkOf(context)),
                  ),
                  Text(
                    notStarted
                        ? 'We check every employer before candidates see their '
                            'vacancies.'
                        : 'Your vacancies stay as drafts until we finish.',
                    style: AppTheme.sansRegular(
                        fontSize: 12.5, color: AppTheme.inkMutedOf(context)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: AppTheme.inkMutedOf(context)),
          ],
        ),
      ),
    );
  }
}

/// Workplace photos, the one company upload a candidate ever sees.
class _PhotoStrip extends StatefulWidget {
  final List<UploadedDocument> photos;

  const _PhotoStrip({required this.photos});

  @override
  State<_PhotoStrip> createState() => _PhotoStripState();
}

class _PhotoStripState extends State<_PhotoStrip> {
  bool _busy = false;

  Future<void> _add() async {
    setState(() => _busy = true);
    final picked = await DocumentService.pickDocument(imagesOnly: true);
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
      kind: DocumentKind.companyPhoto,
      label: 'Workplace photo',
    );
    if (!mounted) return;
    await context.read<EmployerProvider>().addDocument(document);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final photo in widget.photos)
            Padding(
              padding: const EdgeInsets.only(right: 9),
              child: _Thumbnail(document: photo),
            ),
          InkWell(
            onTap: _busy ? null : _add,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  style: BorderStyle.solid,
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            size: 20, color: AppTheme.inkMutedOf(context)),
                        const SizedBox(height: 6),
                        Text('Add photo',
                            style: AppTheme.sansMedium(
                                fontSize: 11,
                                color: AppTheme.inkMutedOf(context))),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final UploadedDocument document;

  const _Thumbnail({required this.document});

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
        future: DocumentService.bytesFor(document.id),
        builder: (context, snapshot) {
          final bytes = DocumentService.bytesFromDataUri(snapshot.data);
          return Container(
            width: 96,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: bytes == null
                ? Icon(Icons.image_outlined,
                    color: AppTheme.inkFaintOf(context))
                : Image.memory(bytes, fit: BoxFit.cover),
          );
        },
      );
}

/// Verification documents and where each one stands.
class _DocumentList extends StatelessWidget {
  final List<UploadedDocument> documents;

  const _DocumentList({required this.documents});

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Text(
          'No documents uploaded. Register your company to add them.',
          style: AppTheme.sansRegular(
              fontSize: 13, color: AppTheme.inkMutedOf(context)),
        ),
      );
    }

    return Column(
      children: [
        for (final document in documents)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Icon(
                    document.isPdf
                        ? Icons.picture_as_pdf_rounded
                        : Icons.image_outlined,
                    size: 19,
                    color: AppTheme.inkMutedOf(context)),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(document.kind.label,
                          style: AppTheme.sansSemiBold(
                              fontSize: 13.5,
                              color: AppTheme.inkOf(context))),
                      Text('${document.fileName} · ${document.sizeDisplay}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.sansRegular(
                              fontSize: 11.5,
                              color: AppTheme.inkFaintOf(context))),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: switch (document.status) {
                      DocumentStatus.verified => AppTheme.signalPositiveWash,
                      DocumentStatus.rejected => AppTheme.signalClosedWash,
                      _ => AppTheme.signalAttentionWash,
                    },
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(document.status.label,
                      style: AppTheme.sansBold(
                        fontSize: 10,
                        color: switch (document.status) {
                          DocumentStatus.verified => AppTheme.signalPositive,
                          DocumentStatus.rejected => AppTheme.signalClosed,
                          _ => AppTheme.signalAttention,
                        },
                      )),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
